"""One lock covers intent selection, hardware writes, and outcome recording."""
from contextlib import contextmanager
import fcntl
import json
import os
import plistlib
from pathlib import Path
import shutil
import subprocess
import sys
import time
from .hardware import ControlError, Hardware
from .policy import (AMBIENT, PRESETS, PolicyError, Store, ambient_mode, label,
                     number, reduce, stamp, read_profiles, save_profile, preset)


@contextmanager
def locked(directory, timeout=30):
    directory = Path(directory)
    directory.mkdir(parents=True, exist_ok=True)
    if (directory / 'bd-apply.lock').is_dir():
        raise BlockingIOError('Legacy display lock exists; inspect its owner before retrying')
    # Same stable inode as the previous macOS lockf implementation.
    with (directory / 'bd-apply.lock.file').open('a') as file:
        deadline = time.monotonic() + timeout
        while True:
            try:
                fcntl.flock(file, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if time.monotonic() >= deadline:
                    raise BlockingIOError('Display controller is busy; retry later') from None
                time.sleep(min(0.05, max(0, deadline-time.monotonic())))
        try:
            yield
        finally:
            fcntl.flock(file, fcntl.LOCK_UN)


class Controller:
    def __init__(self, store, hardware, serials=None, notify=lambda: None, bucket_path='/tmp/bd-lmu-bucket', profiles_path=None):
        self.store, self.hardware = store, hardware
        self.serials, self.notify, self.bucket_path = serials or {}, notify, bucket_path
        self.profiles_path = Path(profiles_path or store.directory/'display-profiles.json')

    def identities(self, state):
        return self.hardware.identities({role: self.serials.get(role) or state['identity'].get(role)
                                         for role in ('dev', 'port')})

    def dispatch(self, action, args, source):
        # Called only under locked(). Fresh load prevents delayed wake/ambient
        # requests from replaying a snapshot captured before a newer choice.
        slot = None
        if action == 'favorite':
            if len(args) != 2 or args[0] not in PRESETS or args[1] not in ('1', '2', '3', '4', '5'):
                raise PolicyError('favorite requires a preset and slot 1–5')
            action, args, slot = 'preset', [args[0]], args[1]
        old = self.store.load()
        if action == 'migrate':
            if args:
                raise PolicyError('migrate takes no arguments')
            self.store.save(old)
            self.notify()
            return old
        profiles = read_profiles(self.profiles_path)
        if action == 'save-preset':
            if len(args) != 1 or old['hdr']['enabled'] is True or old['outcome']['status'] != 'dispatched':
                raise PolicyError('Save a preset after a successful managed adjustment, with HDR off')
            save_profile(self.profiles_path, args[0], old['base'])
            old['base'] = preset(args[0], read_profiles(self.profiles_path))
            old.update(owner='manual', source=source, updated_at=stamp(), revision=old['revision']+1)
            self.store.save(old)
            self.notify()
            return old
        devices = None
        if action == 'hdr' and args == ['toggle']:
            enabled = old['hdr']['enabled']
            if enabled is None:
                devices = self.identities(old)
                if not devices['port']:
                    raise ControlError('HDR target is disconnected')
                value = self.hardware.get(devices['port']['tag'], 'hdr')
                if value not in ('on', 'off'):
                    raise ControlError('HDR state is unavailable')
                enabled = value == 'on'
            args = ['off' if enabled else 'on']
        new, apply = reduce(old, action, args, source, ambient=ambient_mode(self.bucket_path), profiles=profiles)
        if new != old or not self.store.path.exists():
            self.store.save(new)
            self.notify()
        if not apply:
            if action == 'manual':
                try:
                    self.hardware.hold(self.identities(new))
                except (ControlError, PolicyError, ValueError) as error:
                    new['outcome'] = {'status': 'failed', 'dev': 'not-run', 'port': 'not-run', 'errors': [str(error)]}
                    self.store.save(new)
                    self.notify()
            return new
        try:
            devices = devices or self.identities(new)
            for role, device in devices.items():
                if device and device['serial']:
                    new['identity'][role] = device['serial']
            new['outcome'] = self.hardware.apply(new, devices)
            if slot and new['outcome']['status'] == 'dispatched':
                for device in devices.values():
                    if device:
                        self.hardware.set(device['tag'], 'saveFavoriteMode', slot)
        except (ControlError, PolicyError, ValueError) as error:
            new['outcome'] = {'status': 'failed', 'dev': 'not-run', 'port': 'not-run', 'errors': [str(error)]}
        new['outcome']['at'] = stamp()
        self.store.save(new)
        self.notify()
        return new


def lingering_cli_processes():
    """Preserve the old doctor's stranded-CLI diagnostic without exposing values."""
    try:
        result = subprocess.run(['ps', '-Ao', 'pid,etime,args'], capture_output=True, text=True, timeout=2)
    except (OSError, subprocess.TimeoutExpired):
        return []
    found = []
    prefix = '/Applications/BetterDisplay.app/Contents/MacOS/BetterDisplay '
    for line in result.stdout.splitlines():
        parts = line.split(None, 2)
        if len(parts) == 3 and parts[2].startswith(prefix):
            operation = parts[2][len(prefix):].split()[0]
            if operation in ('get', 'set', 'perform', 'version'):
                found.append({'pid': parts[0], 'elapsed': parts[1], 'operation': operation})
    return found


USAGE = '''Usage: bd-apply.sh <preset>
       bd-apply.sh auto | manual | reapply
       bd-apply.sh up|down [dev|port|all]
       bd-apply.sh set dev|port|all <percent>
       bd-apply.sh backlight <percent> | save-preset <preset>
       bd-apply.sh srgb | xdr | hdr [toggle|on|off|status]
       bd-apply.sh cycle next|prev | stream-stop
       bd-apply.sh status [--json|--label] | verify | doctor
Manual choices persist until Auto is explicitly selected. Percentages are
built-in software brightness (0–160; sRGB max 100) and external luminance (0–100).
'''


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if not argv or argv[0] in ('--help', '-h'):
        print(USAGE)
        return 0 if argv else 2
    action, args = argv[0], argv[1:]
    source = os.environ.get('BD_SOURCE', 'manual')
    source = source if source in ('manual', 'raycast', 'click', 'wake', 'lmu', 'timer') else 'manual'
    if action in PRESETS:
        # Older still-running watcher versions remain safe during rollout.
        action, args = ('ambient' if source in ('lmu', 'timer') else 'preset'), [action, *args]
    if action == 'hdr' and not args:
        args = ['toggle']
    try:
        directory = Path(os.environ.get('DOTFILES_DISPLAY_STATE_DIR', str(Path.home()/'.cache')))
        store = Store(directory, number(os.environ.get('DOTFILES_BD_HDR_BRIGHTNESS', 100), 0, 100))
        hardware = Hardware(os.environ.get('DOTFILES_BD_CLI') or shutil.which('betterdisplaycli') or '/opt/homebrew/bin/betterdisplaycli',
                            timeout=number(os.environ.get('DOTFILES_BD_COMMAND_TIMEOUT', 6), 0.01, 60),
                            contrast=number(os.environ.get('DOTFILES_BD_PORT_REF_CONTRAST', 75), 0, 100),
                            temperature=number(os.environ.get('DOTFILES_BD_PORT_REF_TEMP', 0), -100, 100),
                            gamma=number(os.environ.get('DOTFILES_BD_PORT_GAMMA', 0), 0, 100))
        def notify():
            tool = shutil.which('sketchybar') or '/opt/homebrew/bin/sketchybar'
            if Path(tool).is_file():
                try:
                    subprocess.run([tool, '--trigger', 'bd_mode_changed'], capture_output=True, timeout=2)
                except (OSError, subprocess.TimeoutExpired):
                    pass
        controller = Controller(store, hardware, {role: os.environ.get('DOTFILES_BD_'+role.upper()+'_SERIAL') for role in ('dev', 'port')}, notify,
                                profiles_path=os.environ.get('DOTFILES_DISPLAY_PROFILES_FILE', str(Path.home()/'.config/dotfiles/display-profiles.json')))
        if action == 'status' or (action == 'hdr' and args == ['status']):
            if action == 'status' and args not in ([], ['--json'], ['--label']):
                raise PolicyError('status accepts --json or --label')
            state = store.load()
            if args == ['--json']:
                print(json.dumps(state, ensure_ascii=False))
            else:
                print(label(state))
                if args != ['--label']:
                    print('Source:', state['source'], '| revision:', state['revision'])
                    print('Built-in:', state['outcome']['dev'], '| external:', state['outcome']['port'])
                    for error in state['outcome'].get('errors', []):
                        print('  ' + error)
            return 0
        if action == 'sensor':
            if args:
                raise PolicyError('sensor takes no arguments')
            print(number(hardware.call('get', '--ambientLight'), 0, 10000000))
            return 0
        if action == 'layout':
            allowed = {'--daily', '--stream', '--hires', '--native', '--portrait', '--portrait-hires', '--solo', '--force', '--dry-run'}
            if any(arg not in allowed for arg in args):
                raise PolicyError('Unknown layout option')
            def layout():
                helper = Path(__file__).resolve().parents[1] / 'display-layout.sh'
                return subprocess.run(['/bin/bash', str(helper), *args], timeout=30,
                                      env=dict(os.environ, DOTFILES_DISPLAY_LAYOUT_LOCKED='1')).returncode
            if '--dry-run' in args:
                return layout()
            with locked(directory, number(os.environ.get('DOTFILES_DISPLAY_LOCK_TIMEOUT', 30), 0, 60)):
                return layout()
        timeout = number(os.environ.get('DOTFILES_DISPLAY_LOCK_TIMEOUT', 30), 0, 60)
        with locked(directory, timeout):
            if action in ('verify', 'doctor', 'probe'):
                if args:
                    raise PolicyError(action + ' takes no arguments')
                state = store.load()
                devices = controller.identities(state)
                if action == 'doctor':
                    app = Path('/Applications/BetterDisplay.app/Contents/Info.plist')
                    try:
                        metadata = plistlib.loads(app.read_bytes())
                        version = metadata.get('CFBundleShortVersionString')
                    except (OSError, ValueError):
                        version = 'unavailable'
                    print(json.dumps({'devices': devices, 'app_version': version,
                                      'cli_processes': lingering_cli_processes(),
                                      'homebrew_versions': [p.name for p in Path('/opt/homebrew/Caskroom/betterdisplay').glob('[0-9]*')]},
                                     ensure_ascii=False, indent=2))
                    print('Registration/identity only; external physical brightness is not verified.')
                    return 0
                if action == 'probe':
                    # Availability signal only, never a physical DDC readback claim.
                    if not devices['port']:
                        return 1
                    number(hardware.get(devices['port']['tag'], 'hardwareBrightness'), 0, 2)
                    return 0
                result = hardware.verify(state, devices)
                print(json.dumps(result, ensure_ascii=False, indent=2))
                return 1 if result['errors'] else 0
            state = controller.dispatch(action, args, source)
            print(label(state))
            if state['outcome']['status'] == 'failed':
                for error in state['outcome'].get('errors', []):
                    print(error, file=sys.stderr)
                return 1
            return 0
    except BlockingIOError as error:
        print(str(error), file=sys.stderr)
        return 75
    except (PolicyError, ControlError, OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired) as error:
        print('Display control: ' + str(error), file=sys.stderr)
        return 2
