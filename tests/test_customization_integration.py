"""Cross-feature transactions and Raycast argument handling, using disposable roots."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from unittest.mock import patch
from support import Fixture, REPO

sys.path.insert(0, str(REPO/'scripts/scripts/lib'))
from dotfiles_preferences.model import Preferences
from dotfiles_preferences.storage import Plan, restore, atomic, inputs
from dotfiles_preferences.profiles import save_plan, use_plan
from dotfiles_preferences.envfile import PreferenceError
from dotfiles_preferences.operations import status


class CustomizationIntegration(Fixture):
    def setUp(self):
        super().setUp()
        self.repo = self.root/'repo'
        for relative in ['aerospace/templates/aerospace.toml.template', 'karabiner/.config/karabiner/karabiner.json']:
            target=self.repo/relative; target.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(REPO/relative,target)
        self.prefs=Preferences(self.repo,self.root/'config',self.root/'home')
        self.env={'DOTFILES_DIR':str(self.repo),'DOTFILES_USER_CONFIG_DIR':str(self.prefs.directory),
                  'DOTFILES_APPLICATION_DIRS':'[]','HOME':str(self.prefs.home)}

    def cli(self,*args):
        return self.run_command([sys.executable,'-B',str(REPO/'scripts/scripts/lib/preferences-cli.py'),*args],self.env)

    def test_profile_capture_preview_apply_and_undo_only_touch_owned_outputs(self):
        Plan(self.prefs,{'readability.ghostty_font_size':20,'workspaces.notes':'2'}).apply()
        before={p:p.read_bytes() if p.exists() else None for p in inputs(self.prefs)}
        preview=self.cli('profile','save','presentation','readability.ghostty_font_size','--dry-run','--apply')
        self.assertEqual(preview.returncode,0,preview.stderr)
        self.assertIn('20',preview.stdout)
        self.assertFalse((self.prefs.directory/'profiles.json').exists())
        saved=self.cli('profile','save','presentation','readability.ghostty_font_size','--apply')
        self.assertEqual(saved.returncode,0,saved.stderr)
        for p,value in before.items():
            if p.name!='profiles.json':self.assertEqual(p.read_bytes() if p.exists() else None,value)
        Plan(self.prefs,{'readability.ghostty_font_size':16,'workspaces.notes':'N'}).apply()
        used=self.cli('profile','use','presentation','--apply')
        self.assertEqual(used.returncode,0,used.stderr)
        self.assertEqual(self.prefs.effective()[0]['readability.ghostty_font_size'],20)
        self.assertEqual(self.prefs.effective()[0]['workspaces.notes'],'N')
        backup=sorted((self.prefs.directory/'backups').iterdir())[-1]
        restore(self.prefs,backup.name,True)
        self.assertEqual(self.prefs.effective()[0]['readability.ghostty_font_size'],16)

    def test_profile_snapshot_change_blocks_apply(self):
        source=save_plan(self.prefs,'desk',['workspaces.browser'])
        self.prefs.directory.mkdir();self.prefs.env.write_text('KEEP=newer\n')
        with self.assertRaises(PreferenceError):
            Plan(self.prefs,extra_before=source.before,extra_files=source.files,save_only=True)
        self.assertFalse((self.prefs.directory/'profiles.json').exists())

    def test_readability_failure_rolls_back_preferences_and_both_terminal_files(self):
        Plan(self.prefs,{'readability.ghostty_font_size':18}).apply()
        before={p:p.read_bytes() if p.exists() else None for p in inputs(self.prefs)}
        plan=Plan(self.prefs,{'readability.background_opacity':1})
        failed=False
        def writer(path,data,mode=0o600):
            nonlocal failed
            if Path(path).name=='kitty.conf' and not failed:
                failed=True;raise OSError('fixture failed write')
            atomic(path,data,mode)
        with patch('dotfiles_preferences.storage.atomic',side_effect=writer):
            with self.assertRaises(OSError):plan.apply()
        self.assertTrue(failed)
        self.assertEqual({p:p.read_bytes() if p.exists() else None for p in before},before)

    def test_v1_undo_remains_compatible(self):
        backup=Plan(self.prefs,render_only=True).apply()
        manifest=json.loads((backup/'manifest.json').read_text())
        manifest['version']=1
        manifest['guards']={k:v for k,v in manifest['guards'].items() if Path(k) in inputs(self.prefs,1)}
        (backup/'manifest.json').write_text(json.dumps(manifest))
        restore(self.prefs,backup.name,True)
        self.assertFalse((self.repo/'aerospace/.config/aerospace/aerospace.toml').exists())

    def test_parent_or_leaf_symlink_swaps_block_apply_and_undo(self):
        backup=Plan(self.prefs,{'readability.ghostty_font_size':16}).apply()
        plan=Plan(self.prefs,{'readability.ghostty_font_size':20})
        directory=self.prefs.directory/'readability';foreign=self.root/'foreign'
        directory.rename(foreign);directory.symlink_to(foreign,target_is_directory=True)
        old=(foreign/'ghostty.conf').read_bytes()
        with self.assertRaises(PreferenceError):plan.apply()
        with self.assertRaises(PreferenceError):restore(self.prefs,backup.name,True)
        self.assertEqual((foreign/'ghostty.conf').read_bytes(),old)
        directory.unlink();foreign.rename(directory)
        plan=Plan(self.prefs,{'readability.ghostty_font_size':20})
        leaf=directory/'ghostty.conf';other=self.root/'external.conf'
        leaf.rename(other);leaf.symlink_to(other)
        with self.assertRaises(PreferenceError):plan.apply()
        self.assertEqual(other.read_bytes(),old)

    def test_option_shaped_profile_keys_cannot_change_the_requested_action(self):
        source=save_plan(self.prefs,'desk',['workspaces.notes'])
        Plan(self.prefs,extra_before=source.before,extra_files=source.files,save_only=True).apply()
        path=self.prefs.directory/'profiles.json';before=path.read_bytes()
        result=self.cli('--apply','--','profile','save','desk','workspaces.notes','--replace')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(path.read_bytes(),before)

    def test_mid_transaction_ownership_failure_rolls_back_safe_earlier_writes(self):
        Plan(self.prefs,{'readability.ghostty_font_size':16}).apply()
        directory=self.prefs.directory/'readability';foreign=self.root/'foreign'
        old=self.prefs.file.read_bytes()
        moved=False
        def writer(path,data,mode=0o600):
            nonlocal moved
            atomic(path,data,mode)
            if Path(path)==self.prefs.file and not moved:
                moved=True;directory.rename(foreign);directory.symlink_to(foreign,target_is_directory=True)
        plan=Plan(self.prefs,{'readability.ghostty_font_size':20})
        with patch('dotfiles_preferences.storage.atomic',side_effect=writer):
            with self.assertRaises(PreferenceError):plan.apply()
        self.assertEqual(self.prefs.file.read_bytes(),old)
        directory.unlink();foreign.rename(directory)
        backup=Plan(self.prefs,{'readability.ghostty_font_size':20}).apply()
        current=self.prefs.file.read_bytes();moved=False
        with patch('dotfiles_preferences.storage.atomic',side_effect=writer):
            with self.assertRaises(PreferenceError):restore(self.prefs,backup.name,True)
        self.assertEqual(self.prefs.file.read_bytes(),current)

    def test_generated_only_keeps_personal_inputs_absent(self):
        plan=Plan(self.prefs,generated_only=True);plan.apply()
        self.assertFalse(self.prefs.file.exists());self.assertFalse(self.prefs.env.exists())
        self.assertEqual(Plan(self.prefs,generated_only=True).changes,[])
        self.assertEqual(status(self.prefs)['configuration'],'consistent')

    def test_status_shortcuts_and_dry_run_do_not_launch_or_discover(self):
        marker=self.root/'effect'
        for tool in ['open','aerospace','betterdisplaycli','brew','launchctl','fc-list','system_profiler']:
            self.stub(tool,'from pathlib import Path\nPath('+repr(str(marker))+').touch()')
        for args in [('status','--json'),('shortcuts','--json'),('profile','list'),
                     ('list-fonts','--dry-run'),('set','readability.ghostty_font_size','20','--dry-run','--apply')]:
            result=self.cli(*args);self.assertEqual(result.returncode,0,result.stderr)
        self.assertFalse(marker.exists());self.assertFalse(self.prefs.directory.exists())

    def test_font_validation_happens_before_apply_writes(self):
        from dotfiles_preferences.cli import main
        with patch.dict(os.environ,self.env),patch('dotfiles_preferences.readability.discover_fonts',return_value=['Other Font']):
            self.assertEqual(main(['set','readability.font_family','Missing Font','--apply']),2)
        self.assertFalse(self.prefs.directory.exists())

    def test_actual_preference_entry_never_executes_personal_environment(self):
        marker=self.root/'executed'
        folder=self.prefs.home/'.config/dotfiles';folder.mkdir(parents=True)
        (folder/'personal.env').write_text('touch '+str(marker)+'\n')
        entry=REPO/'scripts/scripts/dotfiles-preferences'
        result=self.run_command([str(entry),'profile','list','--dry-run'],self.env)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertFalse(marker.exists())


class RaycastPreferences(Fixture):
    def setUp(self):
        super().setUp()
        self.home=self.root/'home';folder=self.home/'scripts';folder.mkdir(parents=True)
        self.record=self.root/'argv.json'
        helper=folder/'dotfiles-preferences'
        helper.write_text('#!/usr/bin/env python3\nimport json,sys\nfrom pathlib import Path\nPath('+repr(str(self.record))+').write_text(json.dumps(sys.argv[1:]))\n')
        helper.chmod(0o755)

    def run_script(self,name,*args):
        result=self.run_command(['/bin/bash',str(REPO/'raycast/script-commands'/('dotfiles-'+name+'.sh')),*args],{'HOME':str(self.home)})
        self.assertEqual(result.returncode,0,result.stderr)
        return json.loads(self.record.read_text())

    def test_user_values_are_literal_arguments_and_preview_is_default(self):
        value='Name; $(touch should-not-exist) "quotes"'
        self.assertEqual(self.run_script('preference-set','readability.font_family',value),['--dry-run','--','set','readability.font_family',value])
        self.assertFalse((self.root/'should-not-exist').exists())
        self.assertEqual(self.run_script('preference-profile','desk','apply'),['--apply','--','profile','use','desk'])
        self.assertEqual(self.run_script('preference-undo','backup'),['--dry-run','--','undo','backup'])
        self.assertEqual(self.run_script('preference-capture','desk','workspaces.browser projects.roots'),['--dry-run','--','profile','save','desk','workspaces.browser','projects.roots'])
        self.assertEqual(self.run_script('preference-capture','desk','workspaces.notes --replace','save'),['--apply','--','profile','save','desk','workspaces.notes','--replace'])

    def test_all_command_metadata_is_valid_and_noninteractive(self):
        files=list((REPO/'raycast/script-commands').glob('dotfiles-*.sh'))
        self.assertEqual(len(files),6)
        for file in files:
            args=[]
            for line in file.read_text().splitlines():
                if line.startswith('# @raycast.argument'):
                    value=json.loads(line.split(' ',2)[2]);args.append(value)
                    if value['type']=='dropdown':self.assertEqual(value['data'][0]['value'],'preview')
            self.assertLessEqual(len(args),3)
            self.assertIn('# @raycast.mode fullOutput',file.read_text())
