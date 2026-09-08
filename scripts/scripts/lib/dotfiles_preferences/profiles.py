"""Explicit preference profiles; this module reads and plans, never writes.

The caller merges ProfilePlan.before/files into the shared storage transaction.
The profile and the preference inputs must remain guarded through apply/undo.
"""
from copy import deepcopy
from dataclasses import dataclass
import json
import re

from .envfile import PreferenceError
from .model import FIELDS, validate_overrides, validate_value


STARTERS = {'laptop': 'Laptop', 'desk': 'Desk', 'presentation': 'Presentation'}
_MISSING = object()


def allowed_keys():
    """Use the live catalog, excluding display-controller identity/ownership."""
    return tuple(key for key in FIELDS if not key.startswith('display.'))


def _name(value):
    if not isinstance(value, str) or re.fullmatch(r'[a-z][a-z0-9-]{0,47}', value) is None:
        raise PreferenceError('Profile names use 1-48 lowercase letters, digits, or dashes, starting with a letter')
    return value


def _keys(values, description, nonempty=False):
    if not isinstance(values, (list, tuple)) or (nonempty and not values):
        raise PreferenceError(description + ' must be ' + ('a nonempty' if nonempty else 'an') + ' ordered list of preference keys')
    seen = set()
    for key in values:
        if not isinstance(key, str) or key not in allowed_keys():
            raise PreferenceError('Profiles may own supported preferences except display.*')
        if key in seen:
            raise PreferenceError('Duplicate preference ownership: ' + key)
        seen.add(key)
    return list(values)


def _pairs(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise PreferenceError('Duplicate JSON key in profile input')
        result[key] = value
    return result


def _constant(_):
    raise PreferenceError('Non-finite numbers are not supported in profile input')


def _json(raw, description):
    try:
        return json.loads(raw, object_pairs_hook=_pairs, parse_constant=_constant)
    except (UnicodeDecodeError, ValueError, TypeError):
        # Do not expose values or arbitrary personal input in parser errors.
        raise PreferenceError('Invalid ' + description + '; existing files left untouched') from None


def _validate(data, preferences):
    if not isinstance(data, dict) or type(data.get('version')) is not int or data['version'] != 1:
        raise PreferenceError('Unsupported profiles version; existing file left untouched')
    if set(data) != {'version', 'profiles'} or not isinstance(data['profiles'], list):
        raise PreferenceError('Profiles must contain version and an ordered profiles list')
    names = set()
    for entry in data['profiles']:
        if not isinstance(entry, dict) or set(entry) != {'name', 'owns', 'values', 'reset'}:
            raise PreferenceError('Each profile must contain name, owns, values, and reset')
        name = _name(entry['name'])
        if name in names:
            raise PreferenceError('Duplicate profile name: ' + name)
        names.add(name)
        if not isinstance(entry['owns'], list) or not isinstance(entry['reset'], list):
            raise PreferenceError('Profile owns and reset must be JSON arrays')
        owns = _keys(entry['owns'], 'Profile owns', nonempty=True)
        reset = _keys(entry['reset'], 'Profile reset')
        if not isinstance(entry['values'], dict):
            raise PreferenceError('Profile values must be an object')
        if set(entry['values']) & set(reset) or set(owns) != set(entry['values']) | set(reset):
            raise PreferenceError('Every owned preference must have exactly one saved value or reset')
        for key, value in entry['values'].items():
            validate_value(key, value, preferences.repo, preferences.home)
    return data


def load(preferences, raw=_MISSING):
    """Read a strict versioned profile file, or validate already captured bytes."""
    file = preferences.directory/'profiles.json'
    if raw is _MISSING:
        if file.is_symlink():
            raise PreferenceError('Refusing a symlinked profiles.json; inspect ownership')
        raw = file.read_bytes() if file.exists() else None
    if raw is None:
        return {'version': 1, 'profiles': []}
    return deepcopy(_validate(_json(raw, 'profiles.json'), preferences))


@dataclass
class ProfileSnapshot:
    before: dict
    data: dict
    overrides: dict
    values: dict


def capture_snapshot(preferences):
    """Capture all inputs for both matching and later transaction drift guards."""
    file = preferences.directory/'profiles.json'
    template = preferences.repo/'aerospace/templates/aerospace.toml.template'
    paths = (file, preferences.file, preferences.env, template)
    before = {}
    for path in paths:
        if path.is_symlink():
            raise PreferenceError('Refusing a symlinked profile input; inspect ownership: ' + str(path))
        before[path] = path.read_bytes() if path.exists() else None
    data = load(preferences, before[file])
    overrides = (_json(before[preferences.file], 'preferences.json')
                 if before[preferences.file] is not None else {'version': 1, 'values': {}})
    validate_overrides(overrides, preferences.repo, preferences.home)
    try:
        environment = (before[preferences.env] or b'').decode('utf-8')
    except UnicodeDecodeError:
        raise PreferenceError('personal.env must contain UTF-8 text; existing file left untouched') from None
    values = preferences.effective(overrides, environment)[0]
    return ProfileSnapshot(before, data, overrides, values)


def _entry(data, name):
    _name(name)
    return next((entry for entry in data['profiles'] if entry['name'] == name), None)


def _description(entry, name, current):
    label = STARTERS.get(name, name.replace('-', ' ').title())
    if entry is None:
        return {'name': name, 'label': label, 'state': 'unconfigured', 'owns': [],
                'values': {}, 'reset': [], 'different': []}
    different = [key for key in entry['owns']
                 if ((key in entry['values'] and current.values[key] != entry['values'][key])
                     or (key in entry['reset'] and key in current.overrides['values']))]
    return dict(deepcopy(entry), label=label,
                state='different' if different else 'matches', different=different)


def list_profiles(preferences, snapshot=None):
    """Report current matches, never a potentially stale persisted active flag."""
    current = snapshot if snapshot is not None else capture_snapshot(preferences)
    entries = {entry['name']: entry for entry in current.data['profiles']}
    names = list(STARTERS) + sorted(name for name in entries if name not in STARTERS)
    return [_description(entries.get(name), name, current) for name in names]


def show_profile(preferences, name, snapshot=None):
    current = snapshot if snapshot is not None else capture_snapshot(preferences)
    entry = _entry(current.data, name)
    if entry is None and name not in STARTERS:
        raise PreferenceError('Unknown profile: ' + name)
    return _description(entry, name, current)


@dataclass
class ProfilePlan:
    action: str
    name: str
    patch: dict
    reset: tuple
    before: dict
    files: dict


def _proposed(preferences, current, patch, reset):
    data = deepcopy(current.overrides)
    for key in reset:
        data['values'].pop(key, None)
    data['values'].update(deepcopy(patch))
    preferences.effective(data, (current.before[preferences.env] or b'').decode('utf-8'))


def save_plan(preferences, name, owns, values=None, reset=(), replace=False, snapshot=None):
    """Capture owned effective values without applying the profile.

    Explicit values/reset are a backend interface for authored recipes: each
    owned key must occur exactly once. A reset removes its managed override when
    used later, allowing then-current personal.env/default values to apply.
    """
    name = _name(name)
    owns = _keys(owns, 'Profile owns', nonempty=True)
    reset = _keys(reset, 'Profile reset')
    current = snapshot if snapshot is not None else capture_snapshot(preferences)
    if _entry(current.data, name) is not None and not replace:
        raise PreferenceError('Profile already exists; use --replace to capture it again: ' + name)
    if values is None:
        values = {key: deepcopy(current.values[key]) for key in owns if key not in reset}
    entry = {'name': name, 'owns': owns, 'values': deepcopy(values), 'reset': reset}
    data = deepcopy(current.data)
    existing = _entry(data, name)
    if existing is None:
        data['profiles'].append(entry)
    else:
        data['profiles'][data['profiles'].index(existing)] = entry
    _validate(data, preferences)
    _proposed(preferences, current, entry['values'], reset)
    raw = (json.dumps(data, ensure_ascii=False, indent=2)+'\n').encode('utf-8')
    return ProfilePlan('save', name, {}, (), deepcopy(current.before),
                       {preferences.directory/'profiles.json': raw})


def use_plan(preferences, name, snapshot=None):
    """Return only owned updates/resets for the shared preference Plan."""
    current = snapshot if snapshot is not None else capture_snapshot(preferences)
    entry = _entry(current.data, name)
    if entry is None:
        raise PreferenceError('Profile is unconfigured; save its owned settings first: ' + name)
    _proposed(preferences, current, entry['values'], entry['reset'])
    return ProfilePlan('use', name, deepcopy(entry['values']), tuple(entry['reset']),
                       deepcopy(current.before), {})
