"""CLI and Raycast views over the same preference transactions."""
import json
from .envfile import PreferenceError
from .storage import Plan, restore


def reload_hints(paths):
    names = {str(path) for path in paths}
    hints = []
    if any(name.endswith('/aerospace.toml') for name in names):
        hints.append('AeroSpace: aerospace reload-config')
    if any(name.endswith('/readability/ghostty.conf') for name in names):
        hints.append('Ghostty: Cmd+b, then lowercase r; some options need a new window')
    if any(name.endswith('/readability/kitty.conf') for name in names):
        hints.append('Kitty: Cmd+b, then lowercase r; some options need a new window')
    if any(name.endswith('/personal.env') for name in names):
        hints.append('Shell: open a new shell to read projected environment values')
    return hints


def backups(preferences, limit=10):
    result = []
    directory = preferences.directory/'backups'
    for path in sorted(directory.glob('personalization-*'), reverse=True):
        if not path.is_dir() or path.is_symlink():
            continue
        item = {'name': path.name, 'undo': 'unavailable', 'files': []}
        try:
            item['files'] = restore(preferences, path.name)
            item['undo'] = 'available'
        except (ValueError, OSError, TypeError, KeyError):
            item['reason'] = 'Inputs changed or backup validation failed; saved files were not touched.'
        result.append(item)
        if len(result) >= limit:
            break
    return result


def status(preferences):
    from .profiles import list_profiles
    values, sources, warnings = preferences.effective()
    plan = Plan(preferences)
    history = backups(preferences)
    return {
        'values': values, 'sources': sources, 'warnings': warnings,
        'configuration': 'drift' if plan.changes else 'consistent',
        'would_update': [str(path) for path in plan.changes],
        'profiles': list_profiles(preferences), 'backups': history,
        'reload_verification': 'unverified: this read-only view does not inspect or restart running applications',
        'reload_hints': reload_hints(history[0]['files']) if history else [],
    }


def status_text(report):
    lines = ['Dotfiles preferences', '', 'Saved/rendered configuration: '+report['configuration']]
    for key, value in report['values'].items():
        lines.append(key+' = '+json.dumps(value, ensure_ascii=False)+' ['+report['sources'][key]+']')
    lines += ['', 'Profiles:']
    for item in report['profiles']:
        lines.append(item['name']+': '+item['state'])
    lines += ['', 'Recent backups:']
    lines += [item['name']+' — undo '+item['undo'] for item in report['backups']] or ['None yet.']
    lines += ['', 'Reload confirmation is not tracked. After the latest applicable change:']
    lines += report['reload_hints'] or ['No reload instructions from the latest backup.']
    if report['would_update']:
        lines += ['', 'Preview configuration drift: personalize.sh apply --dry-run']
    lines += ['Note: '+warning for warning in report['warnings']]
    return '\n'.join(lines)


def profile_plan(preferences, params, replace=False):
    from .profiles import save_plan, use_plan
    if len(params) >= 3 and params[0] == 'save':
        # Explicit field ownership prevents capture from silently including new settings.
        source = save_plan(preferences, params[1], params[2:], replace=replace)
    elif len(params) == 2 and params[0] == 'use':
        source = use_plan(preferences, params[1])
    else:
        raise PreferenceError('Use profile save NAME KEY... or profile use NAME')
    return source
