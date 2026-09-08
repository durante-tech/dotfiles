"""Preview first, validate before writes, retain backups, and detect concurrent edits."""
from contextlib import contextmanager
from datetime import datetime, timezone
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import tempfile
import time
from .envfile import PreferenceError, project
from .render import aerospace


def content(path):
    return Path(path).read_bytes() if Path(path).exists() else None


def digest(value):
    return hashlib.sha256(value).hexdigest() if value is not None else None


def atomic(path, value, mode=0o600):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix='.'+path.name+'-', dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(value)
            stream.flush()
            os.fsync(stream.fileno())
            os.fchmod(stream.fileno(), mode)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


@contextmanager
def locked(directory):
    directory = Path(directory)
    directory.mkdir(parents=True, exist_ok=True)
    with (directory/'preferences.lock').open('a') as file:
        try:
            fcntl.flock(file, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise PreferenceError('Another personalization update is running') from None
        try:
            yield
        finally:
            fcntl.flock(file, fcntl.LOCK_UN)


class Plan:
    def __init__(self, preferences, patch=None, reset=(), validate_apps=lambda _: None, render_only=False):
        from .model import validate_overrides
        self.preferences = preferences
        output = preferences.repo/'aerospace/.config/aerospace/aerospace.toml'
        paths = [preferences.file, preferences.env, output]
        self.before = {path: content(path) for path in paths}
        self.template = preferences.repo/'aerospace/templates/aerospace.toml.template'
        self.template_before = content(self.template)
        data = json.loads(self.before[preferences.file]) if self.before[preferences.file] is not None else {'version': 1, 'values': {}}
        validate_overrides(data, preferences.repo, preferences.home)
        for key in reset:
            data['values'].pop(key, None)
        data['values'].update(patch or {})
        self.values, self.sources, self.warnings = preferences.effective(data, (self.before[preferences.env] or b'').decode())
        validate_apps(data['values'])
        self.data = data
        self.files = {
            preferences.file: (json.dumps(data, ensure_ascii=False, indent=2)+'\n').encode(),
            preferences.env: project((self.before[preferences.env] or b'').decode(), preferences.env_assignments(data)).encode(),
            output: aerospace(preferences.repo, self.values, self.template_before.decode()).encode(),
        }
        if render_only:
            self.files = {output: self.files[output]}
        self.changes = [path for path in self.files if self.before[path] != self.files[path]]
        for path in paths:
            if path.is_symlink():
                raise PreferenceError('Refusing to replace a symlink; inspect ownership: ' + str(path))

    def apply(self):
        if not self.changes:
            return None
        prefs = self.preferences
        with locked(prefs.directory):
            if content(self.template) != self.template_before or any(content(p) != old for p, old in self.before.items()):
                raise PreferenceError('Configuration changed during preview; retry with a fresh preview')
            backup = prefs.directory/'backups'/('personalization-'+datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S')+'-'+str(time.time_ns()))
            backup.mkdir(parents=True, mode=0o700)
            records = []
            for index, path in enumerate(self.changes):
                old = self.before[path]
                mode = path.stat().st_mode & 0o777 if old is not None else 0o644 if path.suffix == '.toml' else 0o600
                if old is not None:
                    atomic(backup/str(index), old, mode)
                records.append({'path': str(path), 'before': digest(old), 'after': digest(self.files[path]), 'mode': mode})
            guards = {str(path): digest(self.files[path] if path in self.files else value) for path, value in self.before.items()}
            guards[str(self.template)] = digest(self.template_before)
            manifest = {'version': 1, 'files': records, 'guards': guards}
            atomic(backup/'manifest.json', (json.dumps(manifest, indent=2)+'\n').encode())
            written = []
            try:
                for record in records:
                    path = Path(record['path'])
                    atomic(path, self.files[path], record['mode'])
                    written.append(path)
            except OSError:
                for path in reversed(written):
                    old = self.before[path]
                    if old is None:
                        path.unlink(missing_ok=True)
                    else:
                        atomic(path, old, next(r['mode'] for r in records if r['path'] == str(path)))
                raise
            return backup


def restore(preferences, identifier, apply=False):
    if not identifier or Path(identifier).name != identifier:
        raise PreferenceError('Use the backup directory name printed by apply')
    backup = preferences.directory/'backups'/identifier
    manifest = json.loads((backup/'manifest.json').read_text())
    if not isinstance(manifest, dict) or manifest.get('version') != 1 or not isinstance(manifest.get('files'), list) or not isinstance(manifest.get('guards'), dict):
        raise PreferenceError('Invalid personalization backup manifest')
    records, guards = manifest['files'], manifest['guards']
    allowed = {preferences.file, preferences.env, preferences.repo/'aerospace/.config/aerospace/aerospace.toml'}
    inputs = allowed | {preferences.repo/'aerospace/templates/aerospace.toml.template'}
    def valid_hash(value, nullable=False):
        return (value is None and nullable) or (isinstance(value, str) and re.fullmatch(r'[0-9a-f]{64}', value) is not None)
    if set(guards) != {str(path) for path in inputs} or not all(valid_hash(value, True) for value in guards.values()):
        raise PreferenceError('Invalid personalization backup guards')
    seen = set()
    for record in records:
        if (not isinstance(record, dict) or set(record) != {'path', 'before', 'after', 'mode'}
                or not isinstance(record['path'], str) or record['path'] in seen
                or not valid_hash(record['before'], True) or not valid_hash(record['after'])
                or type(record['mode']) is not int or not 0 <= record['mode'] <= 0o777):
            raise PreferenceError('Invalid personalization backup record')
        seen.add(record['path'])
    def check_guards():
        for name, expected in guards.items():
            path = Path(name)
            if path not in allowed | {preferences.repo/'aerospace/templates/aerospace.toml.template'} or digest(content(path)) != expected:
                raise PreferenceError('A configuration input changed after apply; preserve newer work before undo')
    check_guards()
    for i, record in enumerate(records):
        path = Path(record['path'])
        if path not in allowed or path.is_symlink():
            raise PreferenceError('Backup contains an unexpected target')
        if digest(content(path)) != record['after']:
            raise PreferenceError('A file changed after apply; refusing to overwrite newer work')
        if record['before'] is not None and digest((backup/str(i)).read_bytes()) != record['before']:
            raise PreferenceError('Backup content failed its checksum')
    if apply:
        with locked(preferences.directory):
            check_guards()
            for record in records:
                if digest(content(record['path'])) != record['after']:
                    raise PreferenceError('A file changed during undo preview')
            previous = {Path(record['path']): content(record['path']) for record in records}
            written = []
            try:
                for i, record in enumerate(records):
                    path = Path(record['path'])
                    if record['before'] is None:
                        path.unlink(missing_ok=True)
                    else:
                        atomic(path, (backup/str(i)).read_bytes(), record['mode'])
                    written.append(path)
            except OSError:
                for path in reversed(written):
                    value = previous[path]
                    if value is None:
                        path.unlink(missing_ok=True)
                    else:
                        atomic(path, value, next(r['mode'] for r in records if r['path'] == str(path)))
                raise
    return [record['path'] for record in records]
