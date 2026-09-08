"""Read-only personal reference derived from configured bindings, never executed."""
from collections import defaultdict
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import re
import shlex

from .envfile import PreferenceError
from .model import ROLES
from .render import aerospace, parse_toml

AEROSPACE = 'aerospace/templates/aerospace.toml.template'
KARABINER = 'karabiner/.config/karabiner/karabiner.json'
MODIFIERS = {'ctrl': 'Ctrl', 'alt': 'Alt', 'shift': 'Shift', 'cmd': 'Cmd',
             'control': 'Ctrl', 'option': 'Alt', 'command': 'Cmd'}
KEYS = {'caps_lock': 'CapsLock', 'return_or_enter': 'Enter', 'enter': 'Enter',
        'esc': 'Escape', 'escape': 'Escape', 'spacebar': 'Space', 'space': 'Space',
        'tab': 'Tab', 'backspace': 'Backspace', 'delete_or_backspace': 'Backspace',
        'backslash': '\\', 'slash': '/', 'comma': ',', 'period': '.',
        'semicolon': ';', 'equal': '=', 'minus': '-',
        'leftSquareBracket': '[', 'rightSquareBracket': ']',
        'open_bracket': '[', 'close_bracket': ']'}


def _digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, ensure_ascii=False,
                                    separators=(',', ':')).encode()).hexdigest()


def _mod(value):
    side, _, base = value.partition('_')
    if side in ('left', 'right') and base in MODIFIERS:
        return side.title() + MODIFIERS[base]
    return MODIFIERS.get(value, value)


def _step(key, modifiers=(), event='press', optional=()):
    return {'key': key, 'modifiers': list(modifiers), 'event': event,
            'optional_modifiers': list(optional)}


def _notation(step):
    chord = '+'.join([_mod(m) for m in step['modifiers']] + [KEYS.get(step['key'], step['key'])])
    return chord if step['event'] == 'press' else step['event'].title() + '(' + chord + ')'


def _aero_step(binding):
    parts = binding.split('-')
    modifiers = []
    while parts and parts[0] in ('ctrl', 'alt', 'shift', 'cmd'):
        modifiers.append(parts.pop(0))
    if len(parts) != 1 or not parts[0]:
        raise ValueError('Unsupported AeroSpace key notation')
    return _step(parts[0], modifiers)


def _commands(value):
    if isinstance(value, str):
        return [value]
    if isinstance(value, list) and all(isinstance(c, str) for c in value):
        return value
    raise ValueError('Binding action is not a command string or string array')


def _row(tool, mode, steps, action, source, *, status='parsed', note='', conditions=None, destination=None, activation_conditions=None):
    result = {'tool': tool, 'mode': mode, 'sequence': [_notation(s) for s in steps],
              'steps': deepcopy(steps), 'action': deepcopy(action), 'source': source,
              'status': status, 'note': note, 'conditions': deepcopy(conditions or []),
              'activation_conditions': deepcopy(activation_conditions or []),
              'destination': destination, 'reference_only': True}
    # Source position and explanatory prose are not shortcut identity. Behavior,
    # held keys, modifier sides, conditions, and personal targets are identity.
    result['id'] = tool + ':' + _digest({k: result[k] for k in
                                       ('tool', 'mode', 'steps', 'action', 'conditions', 'activation_conditions', 'destination')})[:24]
    return result


def _target(command, values):
    """Resolve only exact managed launch/workspace commands; do not parse shell."""
    try:
        tokens = shlex.split(command)
    except ValueError:
        return None
    if tokens and tokens[0] == 'exec-and-forget':
        tokens = tokens[1:]
    if len(tokens) == 2 and tokens[0] == 'workspace':
        return {'workspace': tokens[1]}
    if tokens and Path(tokens[0]).name in ('dotfiles-app', 'dotfiles-workspace') and len(tokens) in (2, 3):
        role = tokens[1]
        if role not in ROLES or (len(tokens) == 3 and tokens[2] != '--new'):
            return None
        result = {'role': role, 'workspace': values['workspaces.' + role]}
        if Path(tokens[0]).name == 'dotfiles-app':
            result['app'] = values['apps.' + role]
        return result
    return None


def _aerospace_rows(parsed, values, diagnostics):
    modes = parsed.get('mode', {})
    rows, entries = [], {'main': []}
    # A unique direct `mode NAME` action establishes an entry path. Multi-action
    # transitions can have side effects or fail first, so they are not inferred.
    for _ in range(len(modes)):
        changed = False
        candidates = defaultdict(list)
        for mode, data in modes.items():
            if mode not in entries:
                continue
            for binding, action in data.get('binding', {}).items():
                if isinstance(action, str) and re.fullmatch(r'mode [A-Za-z0-9_-]+', action):
                    target = action.split()[1]
                    if target == 'main':
                        continue
                    try:
                        candidates[target].append(entries[mode] + [_aero_step(binding)])
                    except ValueError:
                        continue
        for target, paths in candidates.items():
            shortest = min(len(p) for p in paths)
            unique = {json.dumps(p, sort_keys=True): p for p in paths if len(p) == shortest}
            if target not in entries and len(unique) == 1:
                entries[target] = next(iter(unique.values()))
                changed = True
        if not changed:
            break
    for mode, data in modes.items():
        if mode not in entries:
            diagnostics.append({'source': AEROSPACE, 'status': 'ambiguous',
                                'message': 'Mode ' + mode + ' has no unique parsed entry path; its rows require that mode already active.'})
        for binding, action in data.get('binding', {}).items():
            source = AEROSPACE + '#mode.' + mode + '.binding.' + binding
            try:
                commands = _commands(action)
                steps = entries.get(mode, []) + [_aero_step(binding)]
                status = 'parsed' if mode in entries else 'context-required'
                target = next((value for c in commands if (value := _target(c, values))), None)
                rows.append(_row('aerospace', mode, steps, commands, source, status=status,
                                 note='Release each chord before the next step. Mode persists until a mode command changes it.', destination=target))
            except ValueError as error:
                rows.append(_row('aerospace', mode, [], action, source, status='unsupported', note=str(error)))
    return rows


def _from(manipulator, event='press'):
    source = manipulator.get('from', {})
    if not isinstance(source, dict) or set(source) - {'key_code', 'modifiers'} or not isinstance(source.get('key_code'), str):
        raise ValueError('Only a single key_code source is parsed; simultaneous/device forms need manual reference.')
    modifiers = source.get('modifiers', {})
    if not isinstance(modifiers, dict) or set(modifiers) - {'mandatory', 'optional'}:
        raise ValueError('Unsupported modifier definition')
    mandatory, optional = modifiers.get('mandatory', []), modifiers.get('optional', [])
    if not isinstance(mandatory, list) or not isinstance(optional, list) or not all(isinstance(v, str) for v in mandatory + optional):
        raise ValueError('Invalid modifier lists')
    return _step(source['key_code'], mandatory, event, optional)


def _conditions(manipulator):
    conditions = manipulator.get('conditions', [])
    if not isinstance(conditions, list) or any(not isinstance(c, dict) or set(c) != {'type', 'name', 'value'} or
            c['type'] != 'variable_if' or not isinstance(c['name'], str) or type(c['value']) is not int or c['value'] not in (0, 1)
            for c in conditions):
        raise ValueError('Only explicit variable_if 0/1 layer conditions are parsed; other conditions remain raw.')
    return conditions


def _basic(manipulator):
    if manipulator.get('type') != 'basic':
        raise ValueError('Only basic manipulators are parsed.')
    extras = set(manipulator) - {'type', 'from', 'to', 'conditions', 'description', 'to_after_key_up', 'to_if_alone'}
    if extras:
        raise ValueError('Timing or extra manipulator behavior requires manual reference: ' + ', '.join(sorted(extras)))


def _action(action):
    if not isinstance(action, dict):
        raise ValueError('Output action requires manual reference.')
    if set(action) == {'shell_command'} and isinstance(action['shell_command'], str):
        return
    if set(action) in ({'key_code'}, {'key_code', 'modifiers'}) and isinstance(action['key_code'], str):
        modifiers = action.get('modifiers', [])
        if isinstance(modifiers, list) and all(isinstance(m, str) for m in modifiers):
            return
    if set(action) == {'set_variable'}:
        variable = action['set_variable']
        if isinstance(variable, dict) and set(variable) == {'name', 'value'} and isinstance(variable['name'], str) and type(variable['value']) is int:
            return
    raise ValueError('Output action requires manual reference.')


def _held_variable(manipulator):
    actions, release = manipulator.get('to'), manipulator.get('to_after_key_up')
    if isinstance(actions, list) and len(actions) == 1 and isinstance(actions[0], dict) and set(actions[0]) == {'set_variable'}:
        variable = actions[0]['set_variable']
        if (isinstance(variable, dict) and set(variable) == {'name', 'value'} and variable['value'] == 1 and
                isinstance(variable['name'], str) and release == [{'set_variable': {'name': variable['name'], 'value': 0}}]):
            return variable['name']
    return None


def _karabiner_rows(document, parsed, values, diagnostics):
    profiles = document.get('profiles', [])
    if not isinstance(profiles, list) or not all(isinstance(p, dict) for p in profiles):
        raise PreferenceError('Karabiner profiles must be objects')
    selected = [p for p in profiles if p.get('selected') is True]
    if len(selected) == 1:
        profile = selected[0]
    elif len(profiles) == 1 and not selected:
        profile = profiles[0]
    else:
        raise PreferenceError('Shortcut guide needs exactly one selected Karabiner profile (or a single profile)')
    profile_name = str(profile.get('name', 'unnamed'))
    manipulators = []
    complex_modifications = profile.get('complex_modifications', {})
    if not isinstance(complex_modifications, dict) or not isinstance(complex_modifications.get('rules', []), list):
        raise PreferenceError('Invalid Karabiner complex modification rules')
    for i, rule in enumerate(complex_modifications.get('rules', [])):
        if not isinstance(rule, dict) or not isinstance(rule.get('manipulators', []), list):
            raise PreferenceError('Invalid Karabiner rule')
        if rule.get('enabled', True) is False:
            diagnostics.append({'source': KARABINER + '#rule.' + str(i), 'status': 'disabled',
                                'message': 'Disabled rule omitted: ' + str(rule.get('description', i))})
            continue
        for j, manipulator in enumerate(rule.get('manipulators', [])):
            if not isinstance(manipulator, dict):
                raise PreferenceError('Karabiner manipulators must be objects')
            manipulators.append((manipulator, KARABINER + '#profile.' + profile_name + '.rule.' + str(i) + '.manipulator.' + str(j)))
    if not isinstance(profile.get('simple_modifications', []), list):
        raise PreferenceError('Invalid Karabiner simple modifications')
    for i, mapping in enumerate(profile.get('simple_modifications', [])):
        if not isinstance(mapping, dict):
            raise PreferenceError('Karabiner simple modifications must be objects')
        manipulators.append((dict(mapping, type='basic'), KARABINER + '#profile.' + profile_name + '.simple.' + str(i)))
    setters = defaultdict(list)
    for manipulator, source in manipulators:
        name = _held_variable(manipulator)
        if name:
            setters[name].append((manipulator, source))

    def holds(manipulator, stack=()):
        active = [c['name'] for c in _conditions(manipulator) if c['value'] == 1]
        if len(active) > 1:
            raise ValueError('Multiple active layer requirements need manual ordering; not inferred.')
        if not active:
            return []
        name = active[0]
        if name in stack or len(setters[name]) != 1:
            raise ValueError('Layer ' + name + ' has a missing, ambiguous, or cyclic hold definition.')
        parent, parent_source = setters[name][0]
        _basic(parent)
        _from(parent, 'hold')  # Validate before deriving descendants.
        return holds(parent, stack + (name,)) + [(parent, parent_source)]

    rows = []
    for manipulator, source in manipulators:
        actions = manipulator.get('to', [])
        conditions = manipulator.get('conditions', [])
        mode = 'profile: ' + profile_name
        try:
            _basic(manipulator)
            ancestors = holds(manipulator)
            prefix = [_from(parent, 'hold') for parent, _ in ancestors]
            activation = [{'step': i, 'conditions': _conditions(parent)} for i, (parent, _) in enumerate(ancestors)]
            held = _held_variable(manipulator)
            if manipulator.get('to_after_key_up') and not held:
                raise ValueError('Non-layer key-up behavior is not inferred.')
            if not isinstance(actions, list) or not actions:
                raise ValueError('Missing output actions')
            destination = None
            for action in actions:
                _action(action)
                if 'shell_command' in action:
                    destination = _target(action['shell_command'], values) or destination
                elif 'key_code' in action:
                    # Show the configured AeroSpace main-mode destination for a
                    # plain forwarded chord. Do not claim it in another mode.
                    modifiers = [re.sub(r'^(left|right)_', '', m) for m in action.get('modifiers', [])]
                    aliases = {'option': 'alt', 'control': 'ctrl', 'command': 'cmd'}
                    modifiers = [aliases.get(m, m) for m in modifiers]
                    binding = '-'.join(modifiers + [action['key_code']])
                    forwarded = parsed.get('mode', {}).get('main', {}).get('binding', {}).get(binding)
                    if isinstance(forwarded, str):
                        target = _target(forwarded, values)
                        if target:
                            destination = dict(target, requires_aerospace_mode='main')
            alone = manipulator.get('to_if_alone')
            if alone:
                if not isinstance(alone, list):
                    raise ValueError('Alone actions must be an array')
                for action in alone:
                    _action(action)
            steps = prefix + [_from(manipulator, 'hold' if held else 'press')]
            note = 'Hold steps stay held through the final press; release them afterward. Optional modifiers and inactive-layer guards remain in the structured record.'
            rows.append(_row('karabiner', mode, steps, actions, source, note=note, conditions=conditions, destination=destination, activation_conditions=activation))
            if alone:
                rows.append(_row('karabiner', mode, prefix + [_from(manipulator, 'tap')], alone, source + '.to_if_alone',
                                 note='Tap and release alone; timing follows Karabiner configuration.', conditions=conditions, activation_conditions=activation))
        except (ValueError, TypeError) as error:
            rows.append(_row('karabiner', mode, [], manipulator, source, status='unsupported', note=str(error), conditions=conditions))
    # Karabiner uses first matching manipulator. Identical input+guards are
    # ambiguous for a reference, including two conflicting layer setters.
    groups = defaultdict(list)
    for row in rows:
        if row['status'] == 'parsed':
            groups[_digest([row['steps'], row['conditions'], row['activation_conditions']])].append(row)
    for group in groups.values():
        if len(group) > 1:
            for row in group:
                row['status'] = 'ambiguous'
                row['note'] = 'Duplicate input and conditions; Karabiner first-match order applies. Inspect source before practicing.'
    return rows


def records(preferences):
    """Return deterministic JSON-ready reference data without writes/discovery."""
    values, _, preference_warnings = preferences.effective()
    template = (preferences.repo / AEROSPACE).read_text()
    raw_karabiner = (preferences.repo / KARABINER).read_text()
    try:
        karabiner = json.loads(raw_karabiner)
    except ValueError:
        raise PreferenceError('Karabiner source is not valid JSON') from None
    if not isinstance(karabiner, dict):
        raise PreferenceError('Karabiner source must be an object')
    # Render with a constant operational root so quoting differences between
    # isolated checkout paths cannot change a shortcut's identity. The actual
    # source template and effective values remain identical to deployment.
    rendered = aerospace(Path('/__dotfiles_reference__'), values, template=template)
    rendered = rendered.replace('/__dotfiles_reference__', '<DOTFILES_DIR>')
    parsed = parse_toml(rendered)
    diagnostics = [{'source': 'preferences', 'status': 'warning', 'message': message} for message in preference_warnings]
    rows = _aerospace_rows(parsed, values, diagnostics) + _karabiner_rows(karabiner, parsed, values, diagnostics)
    roles = {role: {'app': values['apps.' + role], 'workspace': values['workspaces.' + role]} for role in ROLES}
    sources = {AEROSPACE: hashlib.sha256(template.encode()).hexdigest(),
               KARABINER: hashlib.sha256(raw_karabiner.encode()).hexdigest()}
    result = {'version': 1, 'kind': 'dotfiles-shortcut-reference', 'reference_only': True,
              'sources': sources, 'roles': roles, 'records': rows, 'diagnostics': diagnostics}
    result['fingerprint'] = _digest(result)
    return result


def _cell(value):
    return str(value).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('|', '&#124;').replace('`', '&#96;').replace('\n', '<br>')


def guide(preferences):
    """Render a local Markdown guide; the caller chooses a private export path."""
    document = records(preferences)
    lines = ['# Your configured shortcuts', '',
             'Generated from the current checkout and effective preferences. This describes configured behavior; it does not verify which configuration is loaded in running apps.', '',
             'This is a read-only reference, not a course progress import. No mastery, repetition, or historical progress is read or written. Re-export after changing preferences or bindings.', '',
             'Each arrow is a successive step. AeroSpace chords are released before the next step. `Hold(key)` stays held through later steps; `Tap(key)` means press and release alone. Letter case is preserved; Shift and left/right modifiers are explicit. Hold notation describes a variable layer; its name does not imply an emitted Ctrl+Alt+Shift+Cmd chord.', '',
             'AeroSpace rows include a unique parsed entry chord where available. Karabiner rows describe the selected source profile, including guards in the JSON export. Browser/OS interception can prevent practicing these keys in a web trainer; use this reference beside the real tool.', '',
             '## Preferred destinations', '', '| Role | Application bundle ID | Workspace |', '|---|---|---|']
    for role, data in document['roles'].items():
        lines.append('| ' + ' | '.join(map(_cell, [role, data['app'] or 'Not configured', data['workspace']])) + ' |')
    for tool in ('aerospace', 'karabiner'):
        lines += ['', '## ' + ('AeroSpace' if tool == 'aerospace' else 'Karabiner'), '',
                  '| Mode/context | Ordered sequence | Configured action | Resolved destination | Status |', '|---|---|---|---|---|']
        for row in document['records']:
            if row['tool'] != tool:
                continue
            action = json.dumps(row['action'], ensure_ascii=False)
            target = json.dumps(row['destination'], ensure_ascii=False) if row['destination'] else '—'
            lines.append('| ' + ' | '.join(map(_cell, [row['mode'], ' → '.join(row['sequence']) or 'See raw source', action, target, row['status']])) + ' |')
    lines += ['', '## Coverage and source checks', '',
              'Only bindings explicitly present in the AeroSpace template and selected Karabiner profile are covered. Upstream defaults, arbitrary shell/tmux mappings, Raycast-installed shortcut assignments, running-app state, and course mastery are outside this export. Shell actions are shown as text and never executed. App bundle IDs are configured choices, not installation checks.', '',
              'Unsupported and ambiguous rows remain visible and must not be treated as verified key sequences. JSON includes their exact source location, conditions, optional modifiers, and explanation. Earlier application floating exceptions can override preferred workspace routing.', '',
              'Reference fingerprint: `' + document['fingerprint'] + '`', '']
    for source, digest in document['sources'].items():
        lines.append('- `' + source + '` SHA-256: `' + digest + '`')
    for diagnostic in document['diagnostics']:
        lines.append('- ' + _cell(diagnostic['status'] + ': ' + diagnostic['message']))
    return '\n'.join(lines) + '\n'
