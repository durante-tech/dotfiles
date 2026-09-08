"""One small setting catalog: defaults, validation, legacy keys, and consumers."""
import ast
from copy import deepcopy
import json
from pathlib import Path
import re
from .envfile import PreferenceError, literal_assignments, user_content

ROLES = ('terminal', 'browser', 'editor', 'notes')
FIELDS = {
    'monitors.builtin': ('Built-in Retina Display', 'pattern', 'DOTFILES_MONITOR_BUILTIN', 'AeroSpace monitor pinning'),
    'monitors.external': ('PORTRAIT-MONITOR', 'pattern', 'DOTFILES_MONITOR_EXTERNAL', 'AeroSpace monitor pinning'),
    'display.builtin_serial': (None, 'serial', 'DOTFILES_BD_DEV_SERIAL', 'Display controller identity'),
    'display.external_serial': (None, 'serial', 'DOTFILES_BD_PORT_SERIAL', 'Display controller identity'),
    'projects.roots': (None, 'paths', 'DOTFILES_SESSIONIZER_PATHS', 'tmux and Kitty project pickers'),
    'apps.terminal': ('com.mitchellh.ghostty', 'app', None, 'AeroSpace Alt+Enter and dotfiles-app'),
    'apps.browser': ('com.google.Chrome', 'app', None, 'Karabiner Hyper+O+C and dotfiles-app'),
    'apps.editor': (None, 'app', None, 'Preferred GUI editor routing and dotfiles-app; shell EDITOR is separate'),
    'apps.notes': ('notion.id', 'app', None, 'Karabiner Hyper+O+N and dotfiles-app'),
    'workspaces.terminal': ('T', 'workspace', None, 'Terminal app routing and Alt+T'),
    'workspaces.browser': ('B', 'workspace', None, 'Browser app routing and Alt+B'),
    'workspaces.editor': ('D', 'workspace', None, 'GUI editor routing and Alt+D'),
    'workspaces.notes': ('N', 'workspace', None, 'Notes app routing, Alt+O, and Hyper+N'),
}


def expand_home(value, home):
    if value == '~' or value == '$HOME' or value == '${HOME}':
        return str(home)
    for prefix in ('~/', '$HOME/', '${HOME}/'):
        if value.startswith(prefix):
            return str(Path(home)/value[len(prefix):])
    return value


def workspace_names(repo):
    text = (Path(repo)/'aerospace/templates/aerospace.toml.template').read_text()
    match = re.search(r'(?ms)^persistent-workspaces\s*=\s*(\[[^\]]*\])', text)
    try:
        values = ast.literal_eval(match.group(1)) if match else None
    except (ValueError, SyntaxError):
        values = None
    if not isinstance(values, list) or not values or not all(isinstance(v, str) for v in values):
        raise PreferenceError('Cannot read persistent workspaces from the AeroSpace template')
    return values


def validate_value(key, value, repo, home):
    if key not in FIELDS:
        raise PreferenceError('Unknown preference: ' + key)
    _, kind, _, _ = FIELDS[key]
    if kind in ('serial', 'app', 'paths') and value is None:
        return
    if kind == 'paths':
        if not isinstance(value, list) or not value:
            raise PreferenceError(key + ' requires a nonempty JSON array of paths, or null')
        for path in value:
            if not isinstance(path, str) or any(c in path for c in '\n\r\x00') or not Path(expand_home(path, home)).is_absolute():
                raise PreferenceError('Project roots must be absolute or home-relative paths without newlines')
        return
    if not isinstance(value, str) or not value or any(c in value for c in '\n\r\x00'):
        raise PreferenceError(key + ' requires a nonempty single-line string')
    if kind == 'pattern':
        try:
            re.compile(value)
        except re.error:
            raise PreferenceError(key + ' is not a valid regular expression') from None
    elif kind == 'app' and not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]*\.[A-Za-z0-9_.-]+', value):
        raise PreferenceError('Use an application bundle ID from list-apps')
    elif kind == 'serial' and not re.fullmatch(r'[A-Za-z0-9_-]+', value):
        raise PreferenceError('Invalid display serial')
    elif kind == 'workspace':
        if not re.fullmatch(r'[A-Za-z0-9_-]+', value) or value not in workspace_names(repo):
            raise PreferenceError('Workspace must be an existing persistent name using letters, digits, underscores, or dashes')


def validate_overrides(data, repo, home):
    if not isinstance(data, dict) or type(data.get('version')) is not int or data['version'] != 1:
        raise PreferenceError('Unsupported preferences version; existing file left untouched')
    if set(data) != {'version', 'values'} or not isinstance(data['values'], dict):
        raise PreferenceError('Preferences must contain version and values')
    for key, value in data['values'].items():
        validate_value(key, value, repo, home)
    return data


class Preferences:
    def __init__(self, repo, directory, home=None):
        self.repo, self.directory = Path(repo), Path(directory)
        self.home = Path.home() if home is None else Path(home)
        self.file = self.directory/'preferences.json'
        self.env = self.directory/'personal.env'

    def overrides(self):
        if not self.file.exists():
            return {'version': 1, 'values': {}}
        try:
            return validate_overrides(json.loads(self.file.read_text()), self.repo, self.home)
        except (ValueError, TypeError) as error:
            raise PreferenceError('Invalid preferences.json: ' + str(error)) from None

    def environment(self):
        return self.env.read_text() if self.env.exists() else ''

    def effective(self, data=None, environment=None):
        data = self.overrides() if data is None else validate_overrides(data, self.repo, self.home)
        values = {key: deepcopy(info[0]) for key, info in FIELDS.items()}
        sources = {key: 'repository default' for key in FIELDS}
        legacy, dynamic = literal_assignments(user_content(self.environment() if environment is None else environment))
        warnings = []
        for key, (_, kind, envkey, _) in FIELDS.items():
            if not envkey:
                continue
            if key in data['values']:
                continue  # An explicit valid override can repair an invalid legacy value.
            if envkey in dynamic and key not in data['values']:
                raise PreferenceError(envkey + ' is dynamic shell code; set an explicit preference before rendering')
            value = legacy.get(envkey)
            if value is None:
                continue
            if value == '':
                continue  # Legacy empty values used shell defaults.
            if kind == 'paths':
                value = [line for line in value.splitlines() if line]
            validate_value(key, value, self.repo, self.home)
            values[key], sources[key] = value, 'personal.env (legacy literal)'
        if 'DOTFILES_KEYBOARD_LAYOUT' in legacy:
            warnings.append('Legacy keyboard-layout hint is preserved; accent-safe bindings remain unchanged.')
        if any(key in legacy for key in ('DOTFILES_BD_DEV_TAG', 'DOTFILES_BD_PORT_TAG')):
            warnings.append('Legacy numeric display tags are preserved; the display controller uses serial identities.')
        for key, value in data['values'].items():
            values[key], sources[key] = deepcopy(value), 'preferences.json'
        assigned = {}
        for role in ROLES:
            app, workspace = values['apps.'+role], values['workspaces.'+role]
            if app and app in assigned and assigned[app] != workspace:
                raise PreferenceError('The same preferred app cannot route to two different workspaces: ' + app)
            if app:
                assigned[app] = workspace
        return values, sources, warnings

    def env_assignments(self, data):
        result = {}
        for key, value in data['values'].items():
            envkey = FIELDS[key][2]
            if envkey:
                if key == 'projects.roots' and value is not None:
                    value = '\n'.join(expand_home(path, self.home) for path in value)
                result[envkey] = value
        return result
