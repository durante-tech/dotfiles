"""Fixtures never source a real personal.env or launch applications/services."""
from copy import deepcopy
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
from unittest.mock import patch
from support import Fixture, REPO

sys.path.insert(0, str(REPO/'scripts/scripts/lib'))
from dotfiles_preferences.envfile import PreferenceError, project, literal_assignments, BEGIN, END
from dotfiles_preferences.model import Preferences, FIELDS
from dotfiles_preferences.render import aerospace, parse_toml
from dotfiles_preferences.storage import Plan, restore, atomic
from dotfiles_preferences.apps import discover, launch, workspace, require_selected


class Personalization(Fixture):
    def setUp(self):
        super().setUp()
        self.repo=self.root/'repo with spaces'
        template=self.repo/'aerospace/templates/aerospace.toml.template'
        template.parent.mkdir(parents=True)
        shutil.copy2(REPO/'aerospace/templates/aerospace.toml.template',template)
        self.config=self.root/'personal'
        self.prefs=Preferences(self.repo,self.config,self.root/'home')

    def write_env(self,text):
        self.config.mkdir(exist_ok=True)
        self.prefs.env.write_text(text)

    def test_multiline_unknown_content_and_comments_survive_updates(self):
        original='''# Do not lose this comment
export DOTFILES_SESSIONIZER_PATHS="$HOME/Work\n$HOME/Personal Projects"
DOTFILES_DISPLAY_LAYOUT='id:one res:1728x1117\nid:two res:1440x2560'
CUSTOM='quotes " and ; $(not-an-execution)'
'''
        self.write_env(original)
        plan=Plan(self.prefs,{'monitors.builtin':'Laptop (X)','monitors.external':"^Desk O'Brien \\(2\\)$"})
        backup=plan.apply()
        self.assertTrue(self.prefs.env.read_text().startswith(original))
        self.assertEqual(self.prefs.env.read_text().count(BEGIN),1)
        self.assertEqual(self.prefs.env.read_text().count(END),1)
        self.assertEqual(self.prefs.effective()[0]['monitors.external'],"^Desk O'Brien \\(2\\)$")
        self.assertEqual(self.prefs.effective()[0]['projects.roots'],['$HOME/Work','$HOME/Personal Projects'])
        self.assertTrue(backup.is_dir())
        self.assertEqual(Plan(self.prefs).changes,[])

    def test_updated_roots_are_exported_without_shell_injection(self):
        roots=['~/A Space',str(self.root/'$(touch marker);quote\'')]
        self.write_env('KEEP=yes\n')
        Plan(self.prefs,{'projects.roots':roots}).apply()
        code='source "$1"; python3 -c \'import os,json;print(json.dumps(os.environ["DOTFILES_SESSIONIZER_PATHS"]))\''
        result=self.run_command(['bash','-c',code,'fixture',str(self.prefs.env)])
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(json.loads(result.stdout),str(self.prefs.home/'A Space')+'\n'+roots[1])
        self.assertFalse((self.root/'marker').exists())

    def test_user_shell_code_is_never_executed_while_reading_or_editing(self):
        marker=self.root/'executed'
        original='UNKNOWN=$(touch '+str(marker)+')\nDOTFILES_MONITOR_BUILTIN="Safe"\n'
        self.write_env(original)
        Plan(self.prefs,{'workspaces.browser':'2'}).apply()
        self.assertFalse(marker.exists())
        self.assertTrue(self.prefs.env.read_text().startswith(original))
        self.write_env('DOTFILES_MONITOR_BUILTIN=$(touch '+str(marker)+')\n')
        with self.assertRaises(PreferenceError):self.prefs.effective()
        self.assertFalse(marker.exists())

    def test_nested_assignments_are_not_mistaken_for_effective_literals(self):
        self.write_env('if false; then\nDOTFILES_MONITOR_BUILTIN=hidden\nfi\n')
        with self.assertRaises(PreferenceError):self.prefs.effective()

    def test_explicit_override_repairs_invalid_legacy_without_rewriting_it(self):
        self.write_env('DOTFILES_MONITOR_BUILTIN="["\n')
        with self.assertRaises(PreferenceError):self.prefs.effective()
        Plan(self.prefs,{'monitors.builtin':'Valid'}).apply()
        self.assertEqual(self.prefs.effective()[0]['monitors.builtin'],'Valid')
        self.assertTrue(self.prefs.env.read_text().startswith('DOTFILES_MONITOR_BUILTIN="["\n'))

    def test_invalid_input_fails_before_any_write(self):
        for changes in [{'workspaces.browser':'unknown'}, {'apps.notes':'bad; app'},
                        {'monitors.builtin':'['}, {'projects.roots':['relative/path']}, {'invented':1}]:
            with self.subTest(changes=changes):
                with self.assertRaises(PreferenceError):Plan(self.prefs,changes)
                self.assertFalse(self.config.exists())
        self.write_env('SECRET="unfinished\n')
        before=self.prefs.env.read_bytes()
        with self.assertRaises(PreferenceError):Plan(self.prefs,{'workspaces.notes':'2'})
        self.assertEqual(self.prefs.env.read_bytes(),before)

    def test_future_preferences_and_symlinks_are_not_overwritten(self):
        self.config.mkdir()
        self.prefs.file.write_text('{"version":2,"values":{}}')
        with self.assertRaises(PreferenceError):Plan(self.prefs)
        self.assertEqual(self.prefs.file.read_text(),'{"version":2,"values":{}}')
        self.prefs.file.unlink();target=self.root/'elsewhere';target.write_text('KEEP=yes\n')
        self.prefs.env.symlink_to(target)
        with self.assertRaises(PreferenceError):Plan(self.prefs,{'workspaces.browser':'2'})
        self.assertEqual(target.read_text(),'KEEP=yes\n')

    def test_preferred_app_workspace_conflicts_are_rejected(self):
        with self.assertRaises(PreferenceError):Plan(self.prefs,{'apps.notes':'com.google.Chrome'})
        plan=Plan(self.prefs,{'apps.notes':'com.google.Chrome','workspaces.notes':'B'})
        self.assertEqual(plan.values['apps.notes'],'com.google.Chrome')

    def test_preferred_rules_and_shortcuts_share_the_same_destination(self):
        data=Plan(self.prefs,{'apps.browser':'org.example.Browser','workspaces.browser':'2',
                              'apps.editor':'org.example.Editor','workspaces.editor':'1'})
        text=data.files[self.repo/'aerospace/.config/aerospace/aerospace.toml'].decode()
        document=parse_toml(text)
        self.assertEqual(document['mode']['main']['binding']['alt-b'],'workspace 2')
        self.assertEqual(document['mode']['main']['binding']['alt-shift-b'],'move-node-to-workspace 2')
        rule=next(r for r in document['on-window-detected'] if r.get('if',{}).get('app-id')=='org.example.Browser')
        self.assertEqual(rule['run'],['move-node-to-workspace 2'])
        finder=document['on-window-detected'][0]
        self.assertEqual(finder['if']['app-id'],'com.apple.finder');self.assertEqual(finder['run'],'layout floating')
        self.assertIn("'"+str(self.repo/'scripts/scripts/dotfiles-app')+"' terminal --new",document['mode']['main']['binding']['alt-enter'])
        self.assertNotIn('@DOTFILES_WS_',text)

    def test_monitor_patterns_are_serialized_as_data(self):
        pattern='^Display "Quoted" \\(2\\) | O\'Brien$'
        values=self.prefs.effective()[0];values['monitors.external']=pattern
        result=parse_toml(aerospace(self.repo,values))
        self.assertEqual(result['workspace-to-monitor-force-assignment']['2'][0],'^'+pattern+'$')
        self.assertIn(pattern,next(iter(result['gaps']['outer']['top'][1]['monitor'])))

    def test_reset_restores_legacy_value_and_keeps_unknown_settings(self):
        self.write_env('DOTFILES_MONITOR_BUILTIN=Legacy\nOTHER="one\ntwo"\n')
        Plan(self.prefs,{'monitors.builtin':'Override'}).apply()
        self.assertEqual(self.prefs.effective()[0]['monitors.builtin'],'Override')
        Plan(self.prefs,reset=['monitors.builtin']).apply()
        self.assertEqual(self.prefs.effective()[0]['monitors.builtin'],'Legacy')
        self.assertIn('OTHER="one\ntwo"',self.prefs.env.read_text())

    def test_concurrent_edit_is_preserved(self):
        self.write_env('KEEP=yes\n');plan=Plan(self.prefs,{'workspaces.notes':'2'})
        self.prefs.env.write_text('KEEP=changed\n')
        with self.assertRaises(PreferenceError):plan.apply()
        self.assertEqual(self.prefs.env.read_text(),'KEEP=changed\n')
        self.assertFalse(self.prefs.file.exists())

    def test_partial_write_failure_rolls_back(self):
        self.write_env('KEEP=yes\n');plan=Plan(self.prefs,{'monitors.builtin':'Changed'})
        calls=0
        def fail_once(path,value,mode=0o600):
            nonlocal calls
            if Path(path) in plan.changes:
                calls+=1
                if calls==2:raise OSError('simulated write failure')
            atomic(path,value,mode)
        with patch('dotfiles_preferences.storage.atomic',side_effect=fail_once):
            with self.assertRaises(OSError):plan.apply()
        self.assertFalse(self.prefs.file.exists())
        self.assertEqual(self.prefs.env.read_text(),'KEEP=yes\n')

    def test_undo_checks_newer_work_and_restores_original_content(self):
        original='KEEP="one\ntwo"\n';self.write_env(original)
        backup=Plan(self.prefs,{'workspaces.notes':'2'}).apply()
        restore(self.prefs,backup.name,apply=True)
        self.assertEqual(self.prefs.env.read_text(),original);self.assertFalse(self.prefs.file.exists())
        backup=Plan(self.prefs,{'workspaces.notes':'2'}).apply()
        self.prefs.env.write_text('KEEP=newer\n')
        with self.assertRaises(PreferenceError):restore(self.prefs,backup.name,apply=True)
        self.assertEqual(self.prefs.env.read_text(),'KEEP=newer\n')

    def test_marker_inside_user_literal_is_not_replaced(self):
        original="VALUE='first\n"+BEGIN+'\n'+END+"\nlast'\n"
        with self.assertRaises(PreferenceError):project(original,{'DOTFILES_MONITOR_BUILTIN':'new'})

    def test_malformed_undo_manifest_does_not_change_configuration(self):
        backup=Plan(self.prefs,{'monitors.builtin':'Changed'}).apply()
        file=backup/'manifest.json';original=json.loads(file.read_text())
        before=self.prefs.file.read_bytes()
        for kind in ['guards','duplicate','mode','record']:
            data=deepcopy(original)
            if kind=='guards':data['guards']={}
            elif kind=='duplicate':data['files'].append(data['files'][0])
            elif kind=='mode':data['files'][0]['mode']=True
            else:data['files'][0]=None
            file.write_text(json.dumps(data))
            with self.assertRaises(PreferenceError):restore(self.prefs,backup.name,apply=True)
            self.assertEqual(self.prefs.file.read_bytes(),before)

    def test_app_discovery_missing_validation_and_quoted_launch(self):
        apps=self.root/'apps';bundle=apps/"Browser O'Brien.app";contents=bundle/'Contents';contents.mkdir(parents=True)
        (contents/'Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier':'org.example.Browser','CFBundleName':'Browser'}))
        found=discover([apps]);self.assertIn('org.example.Browser',found)
        with self.assertRaises(PreferenceError):require_selected({'apps.browser':'org.missing.App'},found)
        Plan(self.prefs,{'apps.browser':'org.example.Browser'}).apply()
        calls=[]
        def runner(args,**kwargs):calls.append(args);return subprocess.CompletedProcess(args,0)
        launch(self.prefs,'browser',runner=runner,applications=found)
        self.assertEqual(calls,[['/usr/bin/open','-a',str(bundle.resolve())]])
        calls.clear();workspace(self.prefs,'browser',runner=runner)
        self.assertEqual(calls[0][-2:],['workspace','B'])
        with self.assertRaises(PreferenceError):launch(self.prefs,'editor',runner=runner,applications=found)

    def test_cli_preview_writes_nothing_and_hardware_discovery_is_skipped(self):
        marker=self.root/'effect'
        for name in ['betterdisplaycli','aerospace','launchctl','brew','open']:
            self.stub(name,'from pathlib import Path\nPath('+repr(str(marker))+').touch()\nraise SystemExit(1)')
        env={'DOTFILES_DIR':str(self.repo),'DOTFILES_USER_CONFIG_DIR':str(self.config),'DOTFILES_APPLICATION_DIRS':'[]'}
        cli=REPO/'scripts/scripts/lib/preferences-cli.py'
        for flags in [['--apply','--dry-run'],['--dry-run','--apply']]:
            result=self.run_command(['python3',str(cli),'set','workspaces.browser','2',*flags],env)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertFalse(self.config.exists());self.assertFalse(marker.exists())
        result=self.run_command(['python3',str(cli),'discover','--dry-run'],env)
        self.assertEqual(result.returncode,0,result.stderr);self.assertFalse(marker.exists())

    def test_empty_legacy_values_keep_defaults(self):
        self.write_env('DOTFILES_MONITOR_BUILTIN=""\nDOTFILES_SESSIONIZER_PATHS=""\n')
        values=self.prefs.effective()[0]
        self.assertEqual(values['monitors.builtin'],FIELDS['monitors.builtin'][0])
        self.assertIsNone(values['projects.roots'])

    def test_wizard_dry_recheck_does_not_query_tools_or_write(self):
        marker=self.root/'effect'
        for name in ['betterdisplaycli','aerospace','launchctl','open']:
            self.stub(name,'from pathlib import Path\nPath('+repr(str(marker))+').touch()')
        env={'DOTFILES_DIR':str(self.repo),'DOTFILES_USER_CONFIG_DIR':str(self.config),'DOTFILES_APPLICATION_DIRS':'[]'}
        result=self.run_command(['python3',str(REPO/'scripts/scripts/lib/preferences-cli.py'),'--recheck','--dry-run'],env,input='\n'*13)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertFalse(marker.exists());self.assertFalse(self.config.exists())

    def test_no_unknown_content_is_printed_by_preview(self):
        self.write_env('CUSTOM_SECRET=fixture-private-value\n')
        env={'DOTFILES_DIR':str(self.repo),'DOTFILES_USER_CONFIG_DIR':str(self.config),'DOTFILES_APPLICATION_DIRS':'[]'}
        result=self.run_command(['python3',str(REPO/'scripts/scripts/lib/preferences-cli.py'),'set','workspaces.notes','2'],env)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertNotIn('fixture-private-value',result.stdout+result.stderr)

    def test_render_only_does_not_create_preference_or_environment_files(self):
        plan=Plan(self.prefs,render_only=True);plan.apply()
        self.assertFalse(self.prefs.file.exists());self.assertFalse(self.prefs.env.exists())
        self.assertEqual(Plan(self.prefs,render_only=True).changes,[])

    def test_undo_failure_rolls_back_its_own_changes(self):
        self.write_env('KEEP=yes\n')
        backup=Plan(self.prefs,{'monitors.builtin':'Changed'}).apply()
        paths=[self.prefs.file,self.prefs.env,self.repo/'aerospace/.config/aerospace/aerospace.toml']
        before={p:p.read_bytes() for p in paths}
        calls=0
        def fail_once(path,value,mode=0o600):
            nonlocal calls
            if Path(path) in paths:
                calls+=1
                if calls==1:raise OSError('simulated undo write failure')
            atomic(path,value,mode)
        with patch('dotfiles_preferences.storage.atomic',side_effect=fail_once):
            with self.assertRaises(OSError):restore(self.prefs,backup.name,apply=True)
        self.assertEqual({p:p.read_bytes() for p in paths},before)

    def test_projection_exports_only_overrides_and_resets_to_legacy(self):
        self.write_env('DOTFILES_MONITOR_BUILTIN=Existing\n')
        Plan(self.prefs,{'workspaces.notes':'2'}).apply()
        self.assertEqual(self.prefs.env.read_text(),'DOTFILES_MONITOR_BUILTIN=Existing\n')
        Plan(self.prefs,{'display.external_serial':'12345'}).apply()
        self.assertIn('export DOTFILES_BD_PORT_SERIAL=12345',self.prefs.env.read_text())
        Plan(self.prefs,{'display.external_serial':None}).apply()
        self.assertIn('unset DOTFILES_BD_PORT_SERIAL',self.prefs.env.read_text())
