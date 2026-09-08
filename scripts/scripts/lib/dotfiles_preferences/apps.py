"""Local bundle discovery and explicit launches; no installation or app guessing."""
import json
import os
from pathlib import Path
import plistlib
import subprocess
import sys
from xml.parsers.expat import ExpatError
from .envfile import PreferenceError
from .model import ROLES


def discover(roots=None):
    if roots is None:
        configured = os.environ.get('DOTFILES_APPLICATION_DIRS')
        roots = json.loads(configured) if configured else ['/Applications', '/Applications/Setapp', '/System/Applications',
                                                         '/System/Applications/Utilities', str(Path.home()/'Applications')]
    found = {}
    for root in roots:
        for path in sorted(Path(root).glob('*.app')):
            try:
                info = path/'Contents/Info.plist'
                try:
                    data = plistlib.loads(info.read_bytes())
                except (ValueError, plistlib.InvalidFileException, ExpatError):
                    if sys.platform != 'darwin':
                        continue
                    # Apple's reader accepts some app metadata that strict XML
                    # parsers reject. Convert to stdout only; do not modify it.
                    parsed = subprocess.run(['/usr/bin/plutil', '-convert', 'json', '-o', '-', str(info)],
                                            text=True, capture_output=True, timeout=2)
                    if parsed.returncode:
                        continue
                    data = json.loads(parsed.stdout)
                if not isinstance(data, dict):
                    continue
                identifier = data.get('CFBundleIdentifier')
                if isinstance(identifier, str) and identifier:
                    name = data.get('CFBundleDisplayName') or data.get('CFBundleName') or path.stem
                    if not isinstance(name, str):
                        name = path.stem
                    found.setdefault(identifier, []).append({'id': identifier, 'name': name,
                                                            'path': str(path)})
            except (OSError, ValueError, plistlib.InvalidFileException, ExpatError, subprocess.TimeoutExpired):
                continue
    return found


def require_selected(values, applications):
    for key, identifier in values.items():
        if key.startswith('apps.') and identifier and identifier not in applications:
            raise PreferenceError(key + ': app is not installed; use list-apps to choose a bundle ID')
        if key.startswith('apps.') and identifier and len({str(Path(item['path']).resolve()) for item in applications[identifier]}) != 1:
            raise PreferenceError(key + ': multiple installed apps share this bundle ID')


def launch(preferences, role, new=False, runner=subprocess.run, applications=None):
    if role not in ROLES:
        raise PreferenceError('App role must be terminal, browser, editor, or notes')
    values, _, _ = preferences.effective()
    identifier = values['apps.'+role]
    if not identifier:
        raise PreferenceError('No preferred GUI app for this role; configure apps.'+role)
    applications = discover() if applications is None else applications
    require_selected({'apps.'+role: identifier}, applications)
    candidates = applications[identifier]
    # A duplicate bundle ID can belong to different installed builds. Use the
    # ordinary /Applications entry only if unique, otherwise ask for cleanup.
    unique = {str(Path(app['path']).resolve()) for app in candidates}
    if len(unique) != 1:
        raise PreferenceError('Multiple installations have this bundle ID; select a unique installation before launching')
    command = ['/usr/bin/open']
    if new:
        command.append('-n')
    command += ['-a', next(iter(unique))]
    return runner(command, check=False).returncode


def workspace(preferences, role, runner=subprocess.run):
    if role not in ROLES:
        raise PreferenceError('Unknown workspace role')
    values, _, _ = preferences.effective()
    from shutil import which
    command = which('aerospace') or '/opt/homebrew/bin/aerospace'
    return runner([command, 'workspace', values['workspaces.'+role]], check=False).returncode
