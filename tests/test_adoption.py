"""Fresh-home deployment of generated settings; no live installations or apps."""
import os
from pathlib import Path
import shutil
from support import Fixture, REPO, shell_function


class Adoption(Fixture):
    def setUp(self):
        super().setUp()
        self.repo=self.root/'repo with spaces';self.repo.mkdir()
        self.home=self.root/'home';self.home.mkdir()
        self.config=self.home/'.config/dotfiles'
        shutil.copy2(REPO/'personalize.sh',self.repo/'personalize.sh')
        lib=self.repo/'scripts/scripts/lib';lib.mkdir(parents=True)
        shutil.copy2(REPO/'scripts/scripts/lib/preferences-cli.py',lib/'preferences-cli.py')
        shutil.copytree(REPO/'scripts/scripts/lib/dotfiles_preferences',lib/'dotfiles_preferences',ignore=shutil.ignore_patterns('__pycache__'))
        template=self.repo/'aerospace/templates/aerospace.toml.template';template.parent.mkdir(parents=True)
        shutil.copy2(REPO/'aerospace/templates/aerospace.toml.template',template)
        for package in ['ghostty','kitty','sample']:
            folder=self.repo/package;folder.mkdir();(folder/('.'+package+'-fixture')).write_text('base')
        (self.repo/'stow-packages.txt').write_text('ghostty\nkitty\naerospace\nsample\n')
        self.env={'HOME':str(self.home),'DOTFILES_DIR':str(self.repo),'DOTFILES_USER_CONFIG_DIR':str(self.config),'DOTFILES_APPLICATION_DIRS':'[]'}
        self.calls=self.root/'stow-calls'
        self.stub('stow','''import os,sys
from pathlib import Path
directory=Path(os.environ['DOTFILES_USER_CONFIG_DIR'])/'readability'
assert (directory/'ghostty.conf').is_file() or sys.argv[-1]=='sample'
assert (directory/'kitty.conf').is_file() or sys.argv[-1]=='sample'
with Path(os.environ['ADOPTION_CALLS']).open('a') as file:file.write(sys.argv[-1]+'\\n')
''')
        self.env['ADOPTION_CALLS']=str(self.calls)

    def setup_stow(self):
        helper='\n'.join(shell_function('setup.sh',n) for n in ['print_header','print_success','print_warning','print_info','print_error'])
        code=helper+'\n'+shell_function('setup.sh','stow_packages')+'\nstow_packages'
        return self.run_command(['/bin/bash','-c',code],self.env)

    def test_fresh_setup_prepares_includes_before_consumers_and_is_idempotent(self):
        result=self.setup_stow();self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        for name in ['ghostty.conf','kitty.conf']:
            self.assertTrue(all(not line or line.startswith('#') for line in (self.config/'readability'/name).read_text().splitlines()))
        for name in ['personal.env','preferences.json','profiles.json']:
            self.assertFalse((self.config/name).exists())
        before={p:p.read_bytes() for p in self.config.rglob('*') if p.is_file()}
        result=self.setup_stow();self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        self.assertEqual({p:p.read_bytes() for p in self.config.rglob('*') if p.is_file()},before)
        self.assertEqual(self.calls.read_text().splitlines(),['ghostty','kitty','aerospace','sample']*2)

    def test_bad_owned_file_preserved_and_consumers_skipped(self):
        folder=self.config/'readability';folder.mkdir(parents=True)
        foreign=folder/'kitty.conf';foreign.write_text('font_size 27\n')
        result=self.setup_stow();self.assertNotEqual(result.returncode,0)
        self.assertEqual(foreign.read_text(),'font_size 27\n')
        self.assertEqual(self.calls.read_text().splitlines(),['sample'])
        self.assertFalse((self.config/'preferences.json').exists())

    def test_installer_render_phase_uses_same_generated_only_contract(self):
        source=(REPO/'install.sh').read_text()
        start=source.index('# Prepare generated settings before stowing consumers.')
        end=source.index('# Re-stow to handle updates',start)
        phase=source[start:end]
        helpers='print_dry() { :; }; record_failure() { exit 1; };\n'
        result=self.run_command(['/bin/bash','-c',helpers+'DRY_RUN=true\n'+phase],self.env)
        self.assertEqual(result.returncode,0,result.stderr);self.assertFalse(self.config.exists())
        result=self.run_command(['/bin/bash','-c',helpers+'DRY_RUN=false\n'+phase],self.env)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertTrue((self.config/'readability/kitty.conf').is_file())
        self.assertFalse((self.config/'preferences.json').exists())
