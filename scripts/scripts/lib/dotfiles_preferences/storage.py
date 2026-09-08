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


def targets(preferences, version=2):
    paths = {preferences.file, preferences.env, preferences.repo/'aerospace/.config/aerospace/aerospace.toml'}
    if version == 2:
        from .readability import output_paths
        paths.update(output_paths(preferences))
        paths.add(preferences.directory/'profiles.json')
    return paths


def inputs(preferences, version=2):
    return targets(preferences, version) | {preferences.repo/'aerospace/templates/aerospace.toml.template'}


def check_paths(preferences, paths):
    """Recheck ownership under the transaction lock, including replaced parents."""
    roots = (preferences.directory, preferences.repo)
    for path in paths:
        path = Path(path)
        root = next((base for base in roots if path == base or base in path.parents), None)
        if root is None:
            raise PreferenceError('Unexpected personalization path')
        current = path
        while True:
            if current.is_symlink():
                raise PreferenceError('Refusing a symlinked personalization target or parent: '+str(current))
            if current == root:
                break
            current = current.parent


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


def rollback(preferences, written, previous, records):
    failed = []
    for path in reversed(written):
        try:
            check_paths(preferences, [path])
            value = previous[path]
            if value is None:
                path.unlink(missing_ok=True)
            else:
                atomic(path, value, next(r['mode'] for r in records if r['path'] == str(path)))
        except (OSError, PreferenceError):
            failed.append(str(path))
    if failed:
        raise PreferenceError('Rollback could not safely restore changed targets; preserve the backup for recovery: '+', '.join(failed))


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
    def __init__(self, preferences, patch=None, reset=(), validate_apps=lambda _: None, render_only=False,
                 extra_before=None, extra_files=None, save_only=False, generated_only=False):
        from .model import validate_overrides
        from .readability import render_files, validate_owned, output_paths
        self.preferences = preferences
        output = preferences.repo/'aerospace/.config/aerospace/aerospace.toml'
        paths = inputs(preferences)
        self.before = {path: content(path) for path in paths}
        self.template = preferences.repo/'aerospace/templates/aerospace.toml.template'
        self.template_before = self.before[self.template]
        for path, value in (extra_before or {}).items():
            if path not in paths or self.before[path] != value:
                raise PreferenceError('Profile inputs changed during preview; retry')
        if set(extra_files or {}) - {preferences.directory/'profiles.json'}:
            raise PreferenceError('Unexpected profile output target')
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
        if not render_only and not save_only:
            for path, value in render_files(preferences, self.values).items():
                if path not in output_paths(preferences):
                    raise PreferenceError('Unexpected readability output target')
                validate_owned(path, self.before[path])
                self.files[path] = value
        if self.before[preferences.file] is None and not data['values']:
            self.files.pop(preferences.file)
        if self.before[preferences.env] is None and not self.files[preferences.env]:
            self.files.pop(preferences.env)
        if render_only:
            self.files = {output: self.files[output]}
        if generated_only:
            self.files = {p: v for p, v in self.files.items() if p not in (preferences.file, preferences.env)}
        if save_only:
            self.files = {}
        self.files.update(extra_files or {})
        self.changes = [path for path in self.files if self.before[path] != self.files[path]]
        check_paths(preferences, paths)

    def apply(self):
        if not self.changes:
            return None
        prefs = self.preferences
        with locked(prefs.directory):
            check_paths(prefs, self.before)
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
            manifest = {'version': 2, 'files': records, 'guards': guards}
            atomic(backup/'manifest.json', (json.dumps(manifest, indent=2)+'\n').encode())
            written = []
            try:
                for record in records:
                    path = Path(record['path'])
                    check_paths(prefs, [path])
                    atomic(path, self.files[path], record['mode'])
                    written.append(path)
            except (OSError, PreferenceError):
                rollback(prefs, written, self.before, records)
                raise
            return backup


def restore(preferences, identifier, apply=False):
    if not identifier or Path(identifier).name != identifier:
        raise PreferenceError('Use the backup directory name printed by apply')
    backup = preferences.directory/'backups'/identifier
    manifest = json.loads((backup/'manifest.json').read_text())
    if (not isinstance(manifest, dict) or type(manifest.get('version')) is not int or manifest['version'] not in (1, 2)
            or not isinstance(manifest.get('files'), list) or not isinstance(manifest.get('guards'), dict)):
        raise PreferenceError('Invalid personalization backup manifest')
    records, guards = manifest['files'], manifest['guards']
    allowed = targets(preferences, manifest['version'])
    input_paths = inputs(preferences, manifest['version'])
    def valid_hash(value, nullable=False):
        return (value is None and nullable) or (isinstance(value, str) and re.fullmatch(r'[0-9a-f]{64}', value) is not None)
    if set(guards) != {str(path) for path in input_paths} or not all(valid_hash(value, True) for value in guards.values()):
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
        check_paths(preferences, input_paths)
        for name, expected in guards.items():
            path = Path(name)
            if path not in input_paths or path.is_symlink() or digest(content(path)) != expected:
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
                    check_paths(preferences, [path])
                    if record['before'] is None:
                        path.unlink(missing_ok=True)
                    else:
                        atomic(path, (backup/str(i)).read_bytes(), record['mode'])
                    written.append(path)
            except (OSError, PreferenceError):
                rollback(preferences, written, previous, records)
                raise
    return [record['path'] for record in records]
