#!/usr/bin/env python3
"""Restrict screen preferences to widgets in a confirmed dotfiles deployment."""
import json
import os
from pathlib import Path
import sys
import tempfile

BUILTIN = {'focus-widget-index-jsx', 'drift-warden-widget-index-jsx', 'clock-widget-index-jsx'}


def owned_widgets(source, deployed):
    source, deployed = Path(source), Path(deployed)
    if not source.is_dir() or not deployed.is_dir() or source.resolve() != deployed.resolve():
        raise ValueError('widget directory is not a confirmed dotfiles deployment')
    return {str(p.relative_to(source)).replace('.', '-').replace('/', '-')
            for p in source.glob('*.widget/index.jsx') if p.is_file()}


def update(data, owned, screen):
    if not isinstance(data, dict):
        raise ValueError('WidgetSettings must be an object')
    for key in owned & data.keys():
        item = data[key]
        if not isinstance(item, dict):
            raise ValueError('invalid owned widget settings: ' + key)
        main = key in BUILTIN
        item.update(showOnAllScreens=False, showOnMainScreen=main,
                    showOnSelectedScreens=not main, screens=[] if main else [screen])
    return data


def main():
    mode, source, deployed, *args = sys.argv[1:]
    owned = owned_widgets(source, deployed)
    if not owned:
        raise ValueError('no owned widgets found')
    if mode == 'verify':
        return
    settings, screen = Path(args[0]), int(args[1])
    raw = settings.read_bytes()
    data = json.loads(raw)
    changed = update(data, owned, screen) != json.loads(raw)
    if changed and mode == 'apply':
        # Recheck ownership and concurrent changes immediately before replacement.
        owned_widgets(source, deployed)
        with tempfile.NamedTemporaryFile(dir=settings.parent, prefix='.dotfiles-widget-', delete=False) as f:
            temporary = Path(f.name)
            try:
                f.write((json.dumps(data, ensure_ascii=False, indent=2) + '\n').encode())
                f.flush()
                os.fchmod(f.fileno(), settings.stat().st_mode & 0o777)
                if settings.read_bytes() != raw:
                    raise ValueError('settings changed concurrently; retry later')
                os.replace(temporary, settings)
            finally:
                temporary.unlink(missing_ok=True)
    print('changed' if changed else 'nochange')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, IndexError) as error:
        print('Übersicht sync skipped: ' + str(error), file=sys.stderr)
        sys.exit(1)
