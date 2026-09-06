"""Run minimal Neovim + Conform in disposable XDG roots, without Lazy/Mason startup."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[1]
conform = Path(os.environ.get('DOTFILES_TEST_CONFORM_DIR', Path.home()/'.local/share/nvim/lazy/conform.nvim'))
if not conform.is_dir():
    raise SystemExit('Set DOTFILES_TEST_CONFORM_DIR to a Conform checkout (prefer the lazy-lock.json revision).')
for command in ['nvim', 'prettier', 'biome']:
    if not shutil.which(command):
        raise SystemExit(f'{command} must already be installed; this test installs nothing.')
with tempfile.TemporaryDirectory(prefix='dotfiles-format-') as directory:
    root = Path(directory).resolve()
    env = dict(os.environ, DOTFILES_TEST_REPO=str(repo), DOTFILES_TEST_WORK=str(root),
               DOTFILES_TEST_CONFORM_DIR=str(conform), XDG_STATE_HOME=str(root/'state'),
               XDG_CACHE_HOME=str(root/'cache'), XDG_DATA_HOME=str(root/'data'), XDG_CONFIG_HOME=str(root/'config'))
    result = subprocess.run(['nvim','--headless','--noplugin','-u','NONE','-i','NONE','-l',str(repo/'tests/nvim/formatting.lua')],
                            cwd=root, env=env, timeout=90)
    raise SystemExit(result.returncode)
