"""A preview-first personalizer and runtime adapters; no implicit restarts."""
import argparse
import difflib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
from .apps import discover, launch, require_selected, workspace
from .envfile import PreferenceError
from .model import FIELDS, Preferences, ROLES, validate_value
from .storage import Plan, restore

USAGE = '''Personalization (saved values remain outside Git):
  personalize.sh [--recheck] [--dry-run]      interactive preview
  personalize.sh show [--json]
  personalize.sh get KEY [--raw]
  personalize.sh set KEY VALUE [--apply] [--dry-run]
  personalize.sh reset KEY [--apply]
  personalize.sh apply [--dry-run]           project saved values and render
  personalize.sh check
  personalize.sh undo BACKUP_NAME [--apply]
  personalize.sh list-apps [--json]
  personalize.sh discover                   explicit read-only hardware discovery
  personalize.sh catalog                   fields, defaults, units, and consumers

Values: bundle IDs for apps, persistent workspace names for routes, JSON arrays
for project roots, and null for optional values. set/reset/undo preview by default.
--dry-run always suppresses writes, live hardware discovery, and app launches.
No command installs tools, registers services, or silently reloads applications.
'''


def preferences():
    repo = Path(os.environ.get('DOTFILES_DIR', str(Path(__file__).resolve().parents[4])))
    directory = Path(os.environ.get('DOTFILES_USER_CONFIG_DIR', str(Path.home()/'.config/dotfiles')))
    return Preferences(repo, directory)


def hardware_discovery():
    result = {'displays': [], 'monitors': [], 'warnings': []}
    from display_control.hardware import Hardware, parse_devices
    cli = os.environ.get('DOTFILES_BD_CLI') or shutil.which('betterdisplaycli')
    if cli:
        try:
            result['displays'] = parse_devices(Hardware(cli).call('get', '--identifiers'))
        except (RuntimeError, ValueError, OSError) as error:
            result['warnings'].append('Display identity discovery unavailable: ' + str(error))
    aerospace = shutil.which('aerospace')
    if aerospace:
        try:
            process = subprocess.run([aerospace, 'list-monitors'], text=True, capture_output=True, timeout=5)
            if process.returncode == 0:
                result['monitors'] = [line.partition('|')[2].strip() for line in process.stdout.splitlines() if '|' in line]
        except (OSError, subprocess.TimeoutExpired):
            result['warnings'].append('Monitor-name discovery unavailable')
    return result


def decode(key, text):
    if key not in FIELDS:
        raise PreferenceError('Unknown preference: '+key)
    if text == 'null':
        return None
    if FIELDS[key][1] == 'paths' or text.startswith('"'):
        try:
            return json.loads(text)
        except ValueError:
            raise PreferenceError('Use valid JSON for arrays and quoted strings') from None
    return text  # Workspace names and serials can consist entirely of digits.


def preview(plan, patch=None, reset=(), show_diff=False):
    for warning in plan.warnings:
        print('Note: ' + warning)
    for key in dict.fromkeys([*(patch or {}), *reset]):
        print(key + ' -> ' + json.dumps(plan.values[key], ensure_ascii=False) + ' [' + plan.sources[key] + ']')
    if not plan.changes:
        print('No changes needed.')
    for path in plan.changes:
        print('Would update: ' + str(path))
        # Never print unrelated personal.env content, even in a preview.
        if show_diff and path.suffix == '.toml':
            print(''.join(difflib.unified_diff((plan.before[path] or b'').decode().splitlines(True),
                                              plan.files[path].decode().splitlines(True),
                                              fromfile='current AeroSpace', tofile='proposed AeroSpace')))
    print('Launchers read saved app preferences immediately. Reload routing when ready: aerospace reload-config')
    print('New interactive shells read the managed environment block; no service restart is performed.')


def wizard(prefs, recheck=False, dry=False):
    values, _, _ = prefs.effective()
    applications = discover()
    detected = hardware_discovery() if recheck and not dry else {'displays': [], 'monitors': [], 'warnings': []}
    print('Personalization: Enter keeps your current value; no unknown settings are rewritten.')
    if dry and recheck:
        print('Dry run: live display discovery is skipped.')
    for warning in detected['warnings']:
        print('Note: ' + warning)
    if detected['displays']:
        for item in detected['displays']:
            print(f"Detected {item['role']}: {item['name']} — serial {item['serial'] or 'unavailable'}")
    if detected['monitors']:
        print('Monitor patterns (literal names escaped for regex):')
        for name in detected['monitors']:
            print('  ' + re.escape(name))
    patch = {}
    for key in ['monitors.builtin', 'monitors.external', 'display.builtin_serial', 'display.external_serial', 'projects.roots']:
        response = input(key + ' [' + json.dumps(values[key], ensure_ascii=False) + ']: ').strip()
        if response:
            value = decode(key, response)
            validate_value(key, value, prefs.repo, prefs.home)
            patch[key] = value
    options = sorted((items[0] for items in applications.values()), key=lambda item: item['name'].lower())
    print('\nInstalled applications (number or bundle ID; null leaves a role unconfigured):')
    for i, item in enumerate(options, 1):
        print(f"  {i}. {item['name']} ({item['id']})")
    for role in ROLES:
        key = 'apps.'+role
        response = input(key + ' [' + str(values[key]) + ']: ').strip()
        if response:
            if response.isdigit() and 1 <= int(response) <= len(options):
                response = options[int(response)-1]['id']
            patch[key] = decode(key, response)
        key = 'workspaces.'+role
        response = input(key + ' [' + values[key] + ']: ').strip()
        if response:
            patch[key] = response
    return patch


def main(argv=None):
    parser = argparse.ArgumentParser(description=USAGE, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('items', nargs='*')
    parser.add_argument('--dry-run', '-n', action='store_true')
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--recheck', '-r', action='store_true')
    parser.add_argument('--json', action='store_true')
    parser.add_argument('--raw', action='store_true')
    parser.add_argument('--new', action='store_true')
    parser.add_argument('--diff', action='store_true')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_intermixed_args(argv)
    items = args.items
    command = items[0] if items else 'wizard'
    params = items[1:]
    try:
        prefs = preferences()
        if command == 'catalog':
            print(json.dumps({key: {'default': field[0], 'type': field[1], 'environment': field[2], 'consumer': field[3]}
                              for key, field in FIELDS.items()}, indent=2))
            return 0
        if command == 'check-workspaces':
            from .render import aerospace, parse_toml
            values, _, _ = prefs.effective()
            document = parse_toml(aerospace(prefs.repo, values))
            allowed = set(document.get('persistent-workspaces', []))
            referenced = set(document.get('workspace-to-monitor-force-assignment', {}))
            commands = []
            for mode in document.get('mode', {}).values():
                commands += list(mode.get('binding', {}).values())
            commands += [rule.get('run', []) for rule in document.get('on-window-detected', [])]
            for group in commands:
                for command_text in group if isinstance(group, list) else [group]:
                    parts = shlex.split(command_text)
                    if parts and parts[0] in ('workspace', 'move-node-to-workspace') and len(parts) > 1:
                        referenced.add(parts[-1])
            if referenced-allowed:
                raise PreferenceError('Workspaces referenced but not persistent: '+', '.join(sorted(referenced-allowed)))
            print('doctor: OK   persistent-workspaces covers every effective workspace reference')
            return 0
        if command == 'app-routes':
            from .render import aerospace, parse_toml
            values, _, _ = prefs.effective()
            document = parse_toml(aerospace(prefs.repo, values))
            print('\n'.join(sorted({rule['if']['app-id'] for rule in document.get('on-window-detected', []) if 'app-id' in rule.get('if', {})})))
            return 0
        if command == 'list-apps':
            apps = [item for items in discover().values() for item in items]
            print(json.dumps(apps, ensure_ascii=False, indent=2) if args.json else '\n'.join(item['name']+' — '+item['id'] for item in apps))
            return 0
        if command == 'discover':
            print(json.dumps({'skipped': 'dry run'} if args.dry_run else hardware_discovery(), ensure_ascii=False, indent=2))
            return 0
        if command in ('launch-app', 'workspace'):
            if len(params) != 1 or params[0] not in ROLES:
                raise PreferenceError('Choose one role: terminal, browser, editor, notes')
            if args.dry_run:
                print('Would '+command+' for '+params[0]); return 0
            return launch(prefs, params[0], args.new) if command == 'launch-app' else workspace(prefs, params[0])
        if command in ('show', 'get'):
            values, sources, warnings = prefs.effective()
            if command == 'get':
                if len(params) != 1 or params[0] not in FIELDS:
                    raise PreferenceError('get requires a known setting key')
                value = values[params[0]]
                if args.raw:
                    if not isinstance(value, str):
                        raise PreferenceError('--raw requires a string setting')
                    print(value)
                else:
                    print(json.dumps(value, ensure_ascii=False))
            elif args.json:
                print(json.dumps({'values': values, 'sources': sources, 'warnings': warnings}, ensure_ascii=False, indent=2))
            else:
                for key in FIELDS:
                    print(key + ' = ' + json.dumps(values[key], ensure_ascii=False) + ' ['+sources[key]+']')
                for warning in warnings:
                    print('Note: '+warning)
            return 0
        if command == 'undo':
            if len(params) != 1:
                raise PreferenceError('undo requires a backup directory name')
            actual = args.apply and not args.dry_run
            paths = restore(prefs, params[0], actual)
            print(('Restored: ' if actual else 'Would restore: ') + ', '.join(paths))
            print('Reload routing when ready: aerospace reload-config')
            return 0
        patch, resets = {}, []
        if command == 'wizard':
            if params:
                raise PreferenceError('Unexpected wizard arguments')
            patch = wizard(prefs, args.recheck, args.dry_run)
        elif command == 'set':
            if len(params) != 2:
                raise PreferenceError('set requires KEY VALUE')
            patch = {params[0]: decode(*params)}
        elif command == 'reset':
            if len(params) != 1 or params[0] not in FIELDS:
                raise PreferenceError('reset requires a known setting')
            resets = params
        elif command not in ('apply', 'check', 'render-aerospace') or params:
            raise PreferenceError('Unknown command or unexpected arguments')
        apps = discover() if command not in ('render-aerospace',) else {}
        validator = (lambda _: None) if command == 'render-aerospace' else lambda values: require_selected(values, apps)
        plan = Plan(prefs, patch, resets, validator, render_only=command == 'render-aerospace')
        if command == 'check' or args.check:
            meaningful = [path for path in plan.changes if path != prefs.file or prefs.file.exists()]
            if meaningful:
                print('Configuration drift: ' + ', '.join(str(p) for p in meaningful))
                return 1
            print('Preferences and rendered configuration agree.')
            return 0
        preview(plan, patch, resets, args.diff)
        actual = (args.apply or command == 'apply') and not args.dry_run
        if command == 'wizard' and not args.dry_run and not actual:
            actual = input('Apply this validated preview? [y/N]: ').strip().lower() == 'y'
        if actual:
            backup = plan.apply()
            if backup:
                print('Applied. Backup: '+str(backup))
                print('Undo preview: ./personalize.sh undo '+backup.name)
        return 0
    except (PreferenceError, OSError, ValueError, TypeError, KeyError, EOFError, subprocess.TimeoutExpired) as error:
        print('Personalization: '+str(error), file=sys.stderr)
        return 2
