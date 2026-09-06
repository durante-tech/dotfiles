"""Disposable fixtures: never source a complete user startup file or call live tools."""
from pathlib import Path
import os
import re
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


def shell_function(path, name):
    source = (REPO / path).read_text()
    match = re.search(r'(?ms)^' + re.escape(name) + r'\(\) \{.*?^\}', source)
    if not match:
        raise AssertionError(f'Missing function {name} in {path}')
    return match.group()


class Fixture(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='dotfiles-test-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()

    def stub(self, name, source):
        path = self.bin / name
        path.write_text('#!/usr/bin/env python3\n' + source)
        path.chmod(0o755)
        return path

    def run_command(self, args, env=None, **kwargs):
        environment = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ['PATH'])
        environment.update(env or {})
        return subprocess.run(args, cwd=self.root, env=environment, text=True,
                              capture_output=True, timeout=20, **kwargs)
