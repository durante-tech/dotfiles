"""Bounded BetterDisplay calls; accepted DDC writes are never called verified."""
import json
import re
import subprocess
import time
from .policy import PolicyError


class ControlError(RuntimeError):
    pass


def parse_devices(text):
    # The CLI has returned both JSON collections and a stream of JSON objects.
    try:
        value = json.loads(text)
        values = value if isinstance(value, list) else [value]
    except ValueError:
        decoder, values, rest = json.JSONDecoder(), [], text.strip()
        while rest:
            value, end = decoder.raw_decode(rest)
            values.append(value)
            rest = rest[end:].lstrip(' \t\r\n,')
    devices = []
    def walk(value):
        if isinstance(value, list):
            for item in value:
                walk(item)
        elif isinstance(value, dict):
            if value.get('deviceType', value.get('type')) == 'Display':
                if value.get('connected') is False or str(value.get('displayID', '')) == '0':
                    return
                tag = str(value.get('tagID', ''))
                if not re.fullmatch(r'\d+', tag):
                    raise PolicyError('Invalid display tag in identifier response')
                registry = str(value.get('registryLocation', ''))
                builtin = value.get('builtIn')
                role = 'dev' if builtin is True or 'disp0@' in registry else 'port' if builtin is False or registry else None
                if role is None:
                    raise PolicyError('Display role is unknown; refusing to guess')
                serial = str(value.get('serial', '')).strip()
                devices.append({'tag': tag, 'serial': serial if serial not in ('', '0', 'None') else None,
                                'role': role, 'name': str(value.get('name', ''))})
            else:
                for child in value.values():
                    if isinstance(child, (list, dict)):
                        walk(child)
    for value in values:
        walk(value)
    if not devices or len({d['tag'] for d in devices}) != len(devices):
        raise PolicyError('No unique registered displays found')
    return devices


def resolve(devices, serials):
    resolved = {}
    for role in ('dev', 'port'):
        candidates = [d for d in devices if d['role'] == role]
        serial = serials.get(role)
        if serial:
            matches = [d for d in candidates if d['serial'] == serial]
            if not matches and not candidates:
                resolved[role] = None  # Unplugged / clamshell, keep the intent.
                continue
            if len(matches) != 1:
                raise PolicyError(f'{role}: configured display serial is absent or ambiguous')
            resolved[role] = matches[0]
        elif len(candidates) <= 1:
            resolved[role] = candidates[0] if candidates else None
        else:
            raise PolicyError(f'{role}: multiple displays; set DOTFILES_BD_{role.upper()}_SERIAL')
    return resolved


class Hardware:
    def __init__(self, cli, timeout=6, sleep=time.sleep, runner=subprocess.run,
                 contrast=75, temperature=0, gamma=0):
        self.cli, self.timeout, self.sleep, self.runner = str(cli), timeout, sleep, runner
        self.contrast, self.temperature, self.gamma = contrast, temperature, gamma

    def call(self, *args):
        try:
            result = self.runner([self.cli, *args], capture_output=True, text=True, timeout=self.timeout)
        except (OSError, subprocess.TimeoutExpired) as error:
            raise ControlError(str(error)) from error
        out, err = result.stdout.strip(), result.stderr.strip()
        if result.returncode != 0 or re.search(r'\b(failed|error)\b', err, re.I) or (not out.startswith(('{', '[')) and re.search(r'\b(failed|error)\b', out, re.I)):
            raise ControlError(f'BetterDisplay {args[0]} failed ({result.returncode}): {err or out}')
        return out

    def identities(self, serials):
        return resolve(parse_devices(self.call('get', '--identifiers')), serials)

    def get(self, tag, feature):
        return self.call('get', '--tagID=' + tag, '--' + feature)

    def set(self, tag, feature, value):
        return self.call('set', '--tagID=' + tag, '--' + feature + '=' + str(value))

    def ensure(self, tag, feature, value, expected, numeric=False, settle=0.5):
        def matches(actual):
            if numeric:
                try:
                    return abs(float(actual) - float(expected)) <= 0.02
                except ValueError:
                    return False
            return actual == expected
        try:
            if matches(self.get(tag, feature)):
                return
        except ControlError:
            pass
        error = f'{feature} did not reach the requested value'
        for _ in range(3):
            try:
                self.set(tag, feature, value)
                self.sleep(settle)
                if matches(self.get(tag, feature)):
                    return
            except ControlError as exc:
                error = str(exc)
            self.sleep(0.5)
        raise ControlError(error)

    def vcp(self, tag, feature, value):
        error = ''
        for attempt in range(3):
            try:
                self.call('set', '--tagID=' + tag, '--ddc', '--vcp=' + feature, '--value=' + f'{value:g}')
                return  # Dispatched, no physical readback claim.
            except ControlError as exc:
                error = str(exc)
                if attempt < 2:
                    try:
                        self.call('perform', '--tagID=' + tag, '--reinitialize')
                    except ControlError:
                        pass
                    self.sleep(1)
        raise ControlError(error)

    def apply(self, state, devices):
        outcome = {'status': 'dispatched', 'dev': 'absent', 'port': 'absent', 'errors': []}
        def attempt(role, action):
            try:
                action()
            except ControlError as error:
                outcome[role] = 'failed'
                outcome['errors'].append(f'{role}: {error}')
        dev, port = devices['dev'], devices['port']
        base, hdr = state['base'], state['hdr']
        if dev:
            tag = dev['tag']
            outcome['dev'] = 'verified'
            attempt('dev', lambda: self.ensure(tag, 'autoBrightness', 'off', 'off'))
            attempt('dev', lambda: self.ensure(tag, 'xdrPreset', base['xdr'], base['xdr'], settle=1))
            attempt('dev', lambda: self.ensure(tag, 'hardwareBrightness', f"{base['hardware']:g}%", base['hardware']/100, numeric=True))
            attempt('dev', lambda: self.ensure(tag, 'softwareBrightness', f"{base['dev']:g}%", base['dev']/100, numeric=True))
            attempt('dev', lambda: self.ensure(tag, 'autoBrightness', 'off', 'off'))
        if port:
            tag = port['tag']
            outcome['port'] = 'dispatched'
            if hdr['enabled'] is not None:
                desired = 'on' if hdr['enabled'] else 'off'
                attempt('port', lambda: self.ensure(tag, 'hdr', desired, desired, settle=1))
            if outcome['port'] != 'failed':
                luminance = hdr['brightness'] if hdr['enabled'] is True else base['port']
                attempt('port', lambda: self.vcp(tag, 'luminance', luminance))
                attempt('port', lambda: self.vcp(tag, 'contrast', self.contrast))
                attempt('port', lambda: self.ensure(tag, 'temperature', f'{self.temperature:g}%', self.temperature/100, numeric=True, settle=0.7))
                if self.gamma:
                    attempt('port', lambda: self.ensure(tag, 'gamma', f'{self.gamma:g}%', self.gamma/100, numeric=True, settle=0.7))
        if hdr['enabled'] is True and not port:
            outcome['errors'].append('port: HDR target is disconnected')
        if outcome['errors']:
            outcome['status'] = 'failed'
        return outcome

    def hold(self, devices):
        if devices['dev']:
            self.ensure(devices['dev']['tag'], 'autoBrightness', 'off', 'off')

    def verify(self, state, devices):
        result = {'status': 'readback-ok', 'port_hardware': 'unverifiable', 'errors': []}
        values = []
        if devices['dev']:
            tag = devices['dev']['tag']
            values = [(tag, 'xdrPreset', state['base']['xdr'], False),
                      (tag, 'hardwareBrightness', state['base']['hardware']/100, True),
                      (tag, 'autoBrightness', 'off', False),
                      (tag, 'softwareBrightness', state['base']['dev']/100, True)]
        if devices['port']:
            tag = devices['port']['tag']
            values.append((tag, 'temperature', self.temperature/100, True))
            if state['hdr']['enabled'] is not None:
                values.append((tag, 'hdr', 'on' if state['hdr']['enabled'] else 'off', False))
        for tag, feature, expected, numeric in values:
            try:
                actual = self.get(tag, feature)
                matches = abs(float(actual)-expected) <= 0.02 if numeric else actual == expected
                if not matches:
                    result['errors'].append(f'{feature}: expected {expected}, read {actual}')
            except (ControlError, ValueError) as error:
                result['errors'].append(str(error))
        if result['errors']:
            result['status'] = 'drift-or-unavailable'
        return result
