"""Render only declared preferences; retain template rules and floating exceptions."""
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
from .envfile import PreferenceError
from .model import ROLES, workspace_names

MARKER = '# @DOTFILES_PREFERRED_APPS@'


def parse_toml(text):
    try:
        import tomllib
    except ImportError:
        # Full installs already provision Bun before rendering. No downloads here.
        bun = shutil.which('bun') or str(Path.home()/'.bun/bin/bun')
        if not Path(bun).is_file():
            raise PreferenceError('TOML validation needs Python 3.11+ or an installed Bun') from None
        result = subprocess.run([bun, '--no-install', '--no-env-file', '--config=/dev/null', '-e', 'console.log(JSON.stringify(Bun.TOML.parse(await Bun.stdin.text())))'],
                                input=text, text=True, capture_output=True, timeout=10,
                                env={k: v for k, v in os.environ.items() if k not in ('BUN_OPTIONS', 'NODE_OPTIONS')})
        if result.returncode:
            raise PreferenceError('Rendered AeroSpace configuration is not valid TOML')
        return json.loads(result.stdout)
    try:
        return tomllib.loads(text)
    except ValueError:
        raise PreferenceError('Rendered AeroSpace configuration is not valid TOML') from None


def aerospace(repo, values, template=None):
    repo = Path(repo)
    template = (repo/'aerospace/templates/aerospace.toml.template').read_text() if template is None else template
    parse_toml(template)
    if template.count(MARKER) != 1:
        raise PreferenceError('AeroSpace template must have one preferred-app insertion point')
    substitutions = {
        '@DOTFILES_MONITOR_BUILTIN@': values['monitors.builtin'],
        '@DOTFILES_MONITOR_EXTERNAL@': values['monitors.external'],
        '@DOTFILES_LAUNCH_TERMINAL@': 'exec-and-forget ' + shlex.quote(str(repo/'scripts/scripts/dotfiles-app')) + ' terminal --new',
    }
    for role in ROLES:
        substitutions['@DOTFILES_WS_'+role.upper()+'@'] = values['workspaces.'+role]
    string_pattern = re.compile(r'"(?:[^"\\]|\\.)*"|\'[^\']*\'')
    def replace(match):
        original = match.group()
        if '@DOTFILES_' not in original:
            return original
        text = original[1:-1] if original[0] == "'" else json.loads(original)
        # Replace the redundant nested shell in the existing brightness chord
        # with a quoted direct command, including repositories with spaces.
        brightness = re.fullmatch(r'exec-and-forget /bin/bash -c "@DOTFILES_DIR@/scripts/scripts/bd-apply.sh ([a-z-]+)"', text)
        if brightness:
            text = 'exec-and-forget ' + shlex.quote(str(repo/'scripts/scripts/bd-apply.sh')) + ' ' + brightness.group(1)
        else:
            for key, value in substitutions.items():
                text = text.replace(key, value)
        if '@DOTFILES_' in text:
            raise PreferenceError('Unresolved placeholder in AeroSpace template value')
        return json.dumps(text, ensure_ascii=False)
    lines = []
    for line in template.splitlines():
        if line.lstrip().startswith('#'):
            for key, value in substitutions.items():
                line = line.replace(key, value)
        else:
            line = string_pattern.sub(replace, line)
        lines.append(line)
    result = '\n'.join(lines) + '\n'
    rules, seen = [], set()
    for role in ROLES:
        app = values['apps.'+role]
        if not app or app in seen:
            continue
        seen.add(app)
        target = values['workspaces.'+role]
        commands = ['move-node-to-workspace ' + target]
        if role == 'editor':
            commands.insert(0, 'layout tiling')
        rules.append('\n'.join(['# Preferred '+role+' (user preferences)', '[[on-window-detected]]',
                                'if.app-id = '+json.dumps(app), 'run = '+json.dumps(commands), '']))
    result = result.replace(MARKER, '# Preferred apps: generated; edit preferences.json.\n' + '\n'.join(rules))
    parsed = parse_toml(result)
    allowed = set(parsed.get('persistent-workspaces', []))
    for role in ROLES:
        if values['workspaces.'+role] not in allowed:
            raise PreferenceError('Preferred workspace is not persistent')
    bindings = parsed['mode']['main']['binding']
    for role, key in [('terminal', 'alt-t'), ('browser', 'alt-b'), ('editor', 'alt-d'), ('notes', 'alt-o')]:
        if bindings[key] != 'workspace ' + values['workspaces.'+role]:
            raise PreferenceError('Role shortcut and routing disagree: ' + role)
    return result
