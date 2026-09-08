"""Pure display policy and atomic persistence. No hardware calls in this module."""
from copy import deepcopy
from datetime import datetime, timezone
import json
import math
import os
from pathlib import Path
import tempfile

XDR = 'Apple XDR Display (P3-1600 nits)'
SRGB = 'Internet & Web (sRGB)'
PRESETS = {
    'dawn': (100, 55, '󰖜', 'Dawn'),
    'day': (105, 100, '󰖙', 'Day'),
    'afternoon': (100, 85, '󰖕', 'Afternoon'),
    'evening': (80, 55, '󰖛', 'Evening'),
    'night': (60, 35, '󰖔', 'Night'),
    'meeting': (130, 100, '󰍫', 'Meeting'),
    'read': (100, 85, '󰂺', 'Read'),
    'stream': (120, 90, '󰕧', 'Stream'),
    'cinema': (150, 80, '󰎁', 'Cinema'),
}
AMBIENT = ('night', 'evening', 'afternoon', 'day')


class PolicyError(ValueError):
    pass


def stamp():
    return datetime.now(timezone.utc).isoformat(timespec='seconds')


def number(value, low, high):
    try:
        n = float(value)
    except (ValueError, TypeError):
        raise PolicyError('Expected a numeric display value') from None
    if isinstance(value, bool) or not math.isfinite(n) or not low <= n <= high:
        raise PolicyError(f'Display value must be between {low} and {high}')
    return n


def preset(name, profiles=None):
    if name not in PRESETS:
        raise PolicyError('Unknown display preset: ' + name)
    dev, port, glyph, label = PRESETS[name]
    result = {'preset': name, 'dev': dev, 'port': port, 'hardware': 100, 'xdr': XDR, 'glyph': glyph, 'label': label}
    result.update((profiles or {}).get(name, {}))
    validate_base(result)
    return result


def validate_base(base):
    if not isinstance(base, dict) or base.get('preset') not in (*PRESETS, 'custom'):
        raise PolicyError('Invalid saved display preset')
    for field, maximum in [('dev', 160), ('port', 100), ('hardware', 100)]:
        if type(base.get(field)) not in (int, float):
            raise PolicyError('Invalid saved brightness type')
        number(base[field], 0, maximum)
    if base.get('xdr') not in (XDR, SRGB):
        raise PolicyError('Invalid saved color preset')
    if base['xdr'] == SRGB and base['dev'] > 100:
        raise PolicyError('sRGB brightness must not exceed 100%')
    if not all(isinstance(base.get(k), str) and '\n' not in base[k] and '|' not in base[k]
               for k in ('label', 'glyph')):
        raise PolicyError('Invalid saved display label')


def validate(state):
    if not isinstance(state, dict) or state.get('version') != 1:
        raise PolicyError('Unsupported display intent version; saved data left untouched')
    if state.get('owner') not in ('manual', 'auto'):
        raise PolicyError('Invalid display ownership')
    validate_base(state.get('base'))
    hdr = state.get('hdr')
    if not isinstance(hdr, dict) or not (hdr.get('enabled') is None or type(hdr.get('enabled')) is bool):
        raise PolicyError('Invalid HDR intent')
    if type(hdr.get('brightness')) not in (int, float):
        raise PolicyError('Invalid HDR brightness type')
    number(hdr['brightness'], 0, 100)
    if not isinstance(state.get('revision'), int) or state['revision'] < 0:
        raise PolicyError('Invalid display revision')
    if not isinstance(state.get('outcome'), dict) or not isinstance(state.get('identity'), dict):
        raise PolicyError('Invalid display outcome or identity')
    for key in ('dev', 'port'):
        serial = state['identity'].get(key)
        if serial is not None and not isinstance(serial, str):
            raise PolicyError('Invalid saved display serial')
    if state.get('stream_previous') is not None:
        previous = state['stream_previous']
        if not isinstance(previous, dict) or previous.get('owner') not in ('manual', 'auto'):
            raise PolicyError('Invalid saved pre-stream intent')
        validate_base(previous.get('base'))
    if state['outcome'].get('status') not in ('unverified', 'pending', 'failed', 'dispatched', 'awaiting-sensor'):
        raise PolicyError('Invalid display outcome status')
    if not all(isinstance(state.get(k), str) and '\n' not in state[k] and '|' not in state[k] for k in ('source', 'updated_at')):
        raise PolicyError('Invalid saved display metadata')
    return state


def initial(legacy, hdr_brightness=100):
    fields = legacy.strip().split('|') if legacy else []
    if fields and fields[0] not in PRESETS:
        raise PolicyError('Unknown legacy mode; inspect bd-state before migration')
    name = fields[0] if fields else 'day'
    return {'version': 1, 'revision': 0, 'owner': 'manual', 'base': preset(name),
            'hdr': {'enabled': None, 'brightness': hdr_brightness}, 'identity': {},
            'stream_previous': None, 'source': 'legacy' if fields else 'initial',
            'updated_at': stamp(), 'outcome': {'status': 'unverified', 'dev': 'not-run', 'port': 'not-run'}}


def ambient_mode(path, now=None):
    try:
        bucket, _, timestamp = Path(path).read_text().strip().split('|')
        age = (now or datetime.now(timezone.utc)) - datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
        return AMBIENT[int(bucket)] if bucket in ('0', '1', '2', '3') and 0 <= age.total_seconds() <= 180 else None
    except (OSError, ValueError, TypeError):
        return None


def reduce(state, action, arguments, source, ambient=None, profiles=None):
    """Return new intent and whether hardware should be reconciled, under the lock."""
    state = deepcopy(validate(state))
    base = state['base']
    if action == 'ambient':
        if len(arguments) != 1 or arguments[0] not in AMBIENT:
            raise PolicyError('ambient requires night, evening, afternoon, or day')
        if state['owner'] == 'manual' or state['hdr']['enabled'] is True:
            if state['outcome']['status'] in ('pending', 'failed'):
                state.update(revision=state['revision']+1, updated_at=stamp(),
                             outcome={'status': 'pending', 'dev': 'not-run', 'port': 'not-run'})
                return state, True  # Retry the held intent, never the ambient preset.
            return state, False
        if base['preset'] == arguments[0] and state['outcome']['status'] == 'dispatched':
            return state, False
        state['base'] = preset(arguments[0], profiles)
    elif action == 'auto':
        if arguments:
            raise PolicyError('auto takes no arguments')
        state['owner'] = 'auto'
        state['stream_previous'] = None
        if state['hdr']['enabled'] is True or ambient is None:
            state['revision'] += 1
            state['source'], state['updated_at'] = source, stamp()
            if state['hdr']['enabled'] is not True:
                state['outcome'] = {'status': 'awaiting-sensor', 'dev': 'not-run', 'port': 'not-run'}
            return state, False
        state['base'] = preset(ambient, profiles)
    elif action == 'manual':
        if arguments:
            raise PolicyError('manual takes no arguments')
        state['owner'] = 'manual'
        state['revision'] += 1
        state['source'], state['updated_at'] = source, stamp()
        return state, False  # Hold current intent without changing the displays.
    elif action == 'reapply':
        if arguments:
            raise PolicyError('reapply takes no arguments')
    elif action in ('preset', 'cycle'):
        if len(arguments) != 1:
            raise PolicyError(action + ' requires one argument')
        if action == 'cycle':
            if arguments[0] not in ('next', 'prev'):
                raise PolicyError('cycle requires next or prev')
            order = list(PRESETS)
            index = order.index(base['preset']) if base['preset'] in order else -1
            name = order[(index + (1 if arguments[0] == 'next' else -1)) % len(order)]
        else:
            name = arguments[0]
        new_base = preset(name, profiles)
        if name == 'stream' and base['preset'] != 'stream':
            state['stream_previous'] = {'base': deepcopy(base), 'owner': state['owner']}
        elif name != 'stream':
            state['stream_previous'] = None
        state['base'], state['owner'] = new_base, 'manual'
    elif action == 'stream-stop':
        if arguments or base['preset'] != 'stream' or not state.get('stream_previous'):
            raise PolicyError('No active stream preset with a saved previous choice')
        previous = state.pop('stream_previous')
        state.update(previous)
        state['stream_previous'] = None
    elif action == 'backlight':
        if len(arguments) != 1:
            raise PolicyError('backlight requires a percentage')
        base.update(hardware=number(arguments[0], 0, 100), dev=100,
                    preset='custom', label='Custom', glyph='󰃟')
        state.update(owner='manual', stream_previous=None)
    elif action in ('set', 'up', 'down'):
        if action == 'set':
            if len(arguments) != 2:
                raise PolicyError('set requires dev|port|all and a percentage')
            target, amount = arguments[0], arguments[1]
        else:
            if len(arguments) > 1:
                raise PolicyError(action + ' accepts dev|port|all')
            target, amount = (arguments[0] if arguments else 'all'), 10
        if target not in ('dev', 'port', 'all'):
            raise PolicyError('Target must be dev, port, or all')
        for field in ('dev', 'port') if target == 'all' else (target,):
            maximum = 160 if field == 'dev' and base['xdr'] == XDR else 100
            if field == 'dev' and base['hardware'] < 100 and action != 'set':
                base['hardware'] = min(100, max(0, base['hardware'] + (10 if action == 'up' else -10)))
                continue
            current = state['hdr']['brightness'] if field == 'port' and state['hdr']['enabled'] is True else base[field]
            value = number(amount, 0, maximum) if action == 'set' else min(maximum, max(0, current + (10 if action == 'up' else -10)))
            if field == 'port' and state['hdr']['enabled'] is True:
                state['hdr']['brightness'] = value
            else:
                base[field] = value
        base.update(preset='custom', label='Custom', glyph='󰃟')
        state.update(owner='manual', stream_previous=None)
    elif action in ('srgb', 'xdr'):
        if arguments:
            raise PolicyError(action + ' takes no arguments')
        base.update(hardware=100, xdr=SRGB if action == 'srgb' else XDR,
                    dev=100 if action == 'srgb' else 160,
                    preset='custom', label=action.upper(), glyph='󰃟')
        state.update(owner='manual', stream_previous=None)
    elif action == 'hdr':
        if len(arguments) != 1 or arguments[0] not in ('on', 'off'):
            raise PolicyError('hdr requires on or off')
        state['hdr']['enabled'] = arguments[0] == 'on'
    else:
        raise PolicyError('Unknown display action: ' + action)
    state.update(revision=state['revision'] + 1, source=source, updated_at=stamp(),
                 outcome={'status': 'pending', 'dev': 'not-run', 'port': 'not-run'})
    return validate(state), True


def atomic_write(path, content):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix='.' + path.name + '-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
    finally:
        Path(name).unlink(missing_ok=True)


class Store:
    def __init__(self, directory, hdr_brightness=100):
        self.directory = Path(directory)
        self.path = self.directory / 'bd-intent.json'
        self.legacy = self.directory / 'bd-state'
        self.hdr_brightness = hdr_brightness

    def load(self):
        if self.path.exists():
            return validate(json.loads(self.path.read_text()))
        return initial(self.legacy.read_text() if self.legacy.exists() else '', self.hdr_brightness)

    def save(self, state):
        validate(state)
        if not self.path.exists() and self.legacy.exists():
            backup = self.directory / 'bd-state.before-intent-v1'
            if not backup.exists():
                atomic_write(backup, self.legacy.read_text())
        atomic_write(self.path, json.dumps(state, ensure_ascii=False, indent=2) + '\n')
        # Compatibility projection for parked/external readers. Never read back
        # into authoritative state once the JSON exists.
        base = state['base']
        atomic_write(self.legacy, '|'.join([base['preset'], state['updated_at'], state['source'],
                                         base['glyph'], base['label']]) + '\n')


def label(state):
    owner = 'HDR / ' + state['owner'].title() if state['hdr']['enabled'] is True else state['owner'].title()
    port = state['hdr']['brightness'] if state['hdr']['enabled'] is True else state['base']['port']
    return f"{owner} · {state['base']['label']} · Mac H{state['base']['hardware']:g}/S{state['base']['dev']:g}% · Dell {port:g}% · {state['outcome']['status']}"


def read_profiles(path):
    path = Path(path)
    if not path.exists():
        return {}
    data = json.loads(path.read_text())
    if not isinstance(data, dict) or data.get('version') != 1 or not isinstance(data.get('modes'), dict):
        raise PolicyError('Invalid display profiles file')
    for name, values in data['modes'].items():
        if name not in PRESETS or not isinstance(values, dict) or set(values) != {'hardware', 'dev', 'port', 'xdr'}:
            raise PolicyError('Invalid calibrated display preset')
        preset(name, {name: values})
    return data['modes']


def save_profile(path, name, base):
    if name not in PRESETS:
        raise PolicyError('Unknown preset to calibrate')
    profiles = read_profiles(path)
    profiles[name] = {k: base[k] for k in ('hardware', 'dev', 'port', 'xdr')}
    preset(name, profiles)
    path = Path(path)
    if path.exists():
        atomic_write(path.with_name(path.name + '.previous'), path.read_text())
    atomic_write(path, json.dumps({'version': 1, 'modes': profiles}, indent=2) + '\n')
