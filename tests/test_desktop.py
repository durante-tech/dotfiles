import importlib.util
import json
import plistlib
import os
import shutil
import subprocess
from pathlib import Path
from support import Fixture, REPO, shell_function


class DesktopTests(Fixture):
    def setUp(self):
        super().setUp()
        (self.root/'colors.sh').write_text('RED=red\nGREEN=green\nGREY=grey\nYELLOW=yellow\n')
        self.stub('sketchybar', 'import sys,json\nprint(json.dumps(sys.argv[1:]))')
        self.env = {'CONFIG_DIR': str(self.root), 'NAME': 'fixture'}

    def test_memory_single_snapshot_and_invalid(self):
        counter=self.root/'vm-count'
        self.stub('vm_stat', f'from pathlib import Path\np=Path({str(counter)!r})\np.write_text(p.read_text()+"x" if p.exists() else "x")\nprint("Pages free: 10.\\nPages inactive: 20.\\nPages speculative: 30.")')
        self.stub('pagesize', 'print(4096)')
        self.stub('sysctl', 'print(409600)')
        script=REPO/'sketchybar/.config/sketchybar/plugins/memory.sh'
        result=self.run_command(['bash',str(script)],self.env)
        self.assertIn('label=40%',result.stdout)
        self.assertEqual(counter.read_text(),'x')
        self.stub('vm_stat','print("not metrics")')
        result=self.run_command(['bash',str(script)],self.env)
        self.assertIn('label=?',result.stdout)

    def test_spotify_one_query_and_stopped(self):
        self.stub('pgrep','import sys\nsys.exit(0)')
        count=self.root/'apple-events'
        self.stub('osascript', f'import json\nfrom pathlib import Path\np=Path({str(count)!r});p.write_text(p.read_text()+"x" if p.exists() else "x")\nprint(json.dumps({{"state":"playing","track":"a $(touch nope)\\nb","artist":"someone"}}))')
        script=REPO/'sketchybar/.config/sketchybar/plugins/spotify.sh'
        result=self.run_command(['bash',str(script)],self.env)
        self.assertIn('label=a $(touch nope) b - someone',result.stdout)
        self.assertFalse((self.root/'nope').exists())
        self.assertEqual(count.read_text(),'x')
        self.stub('pgrep','import sys\nsys.exit(1)')
        result=self.run_command(['bash',str(script)],self.env)
        self.assertIn('label=Off',result.stdout)
        self.assertEqual(count.read_text(),'x')

    def test_fzf_generated_once(self):
        source=(REPO/'zsh/.zshrc').read_text()
        block=source[source.index('if command -v fzf &>'):source.index('# FZF with Git')]
        count=self.root/'calls'
        self.stub('fzf',f'from pathlib import Path\np=Path({str(count)!r});p.write_text(p.read_text()+"x" if p.exists() else "x")\nprint("export FIXTURE_FZF=ready")')
        result=self.run_command(['zsh','-f','-c',block+'\nprint $FIXTURE_FZF'])
        self.assertEqual(result.stdout.strip(),'ready')
        self.assertEqual(count.read_text(),'x')

    def test_lock_failure_preserves_intent_and_no_hardware(self):
        (self.root/'bd-apply.lock').mkdir()
        state=self.root/'bd-state';state.write_text('night|old|manual|x|Night')
        self.stub('betterdisplaycli', 'raise RuntimeError("hardware must not be called")')
        result=self.run_command(['python3',str(REPO/'scripts/scripts/lib/display-control.py'),'night'],
                                {'DOTFILES_DISPLAY_PROFILES_FILE':str(self.root/'profiles.json'),'DOTFILES_DISPLAY_STATE_DIR':str(self.root),'DOTFILES_DISPLAY_LOCK_TIMEOUT':'0'})
        self.assertEqual(result.returncode,75,result.stderr)
        self.assertNotIn('hardware',result.stderr)
        self.assertEqual(state.read_text(),'night|old|manual|x|Night')

    def test_native_lock_ownership(self):
        if not Path('/usr/bin/lockf').is_file(): self.skipTest('native macOS lockf only')
        lock=self.root/'lock'
        proc=subprocess.Popen(['bash','-c','exec 9>"$1"; /usr/bin/lockf -t 0 9; echo ready; read -r _', 'fixture', str(lock)],stdout=subprocess.PIPE,stdin=subprocess.PIPE,text=True)
        self.addCleanup(lambda: proc.poll() is None and proc.kill())
        self.assertEqual(proc.stdout.readline().strip(),'ready')
        blocked=self.run_command(['/usr/bin/lockf','-k','-t','0',str(lock),'true'])
        self.assertEqual(blocked.returncode,75)
        # An unsuccessful waiter must not release the owner's lock.
        self.assertEqual(self.run_command(['/usr/bin/lockf','-k','-t','0',str(lock),'true']).returncode,75)
        proc.communicate('\n')
        self.assertEqual(self.run_command(['/usr/bin/lockf','-k','-t','0',str(lock),'true']).returncode,0)

    def test_widget_ownership_and_foreign_preservation(self):
        helper=REPO/'scripts/scripts/lib/widget-settings.py'
        source=self.root/'source';source.mkdir()
        (source/'clock.widget').mkdir();(source/'clock.widget/index.jsx').touch()
        (source/'moon.widget').mkdir();(source/'moon.widget/index.jsx').touch()
        deployed=self.root/'deployed';deployed.mkdir()
        result=self.run_command(['python3',str(helper),'verify',str(source),str(deployed)])
        self.assertEqual(result.returncode,1)
        deployed.rmdir();deployed.symlink_to(source)
        settings=self.root/'settings.json'
        original={'foreign-widget-index-jsx':{'screens':[99],'custom':'preserve'},'clock-widget-index-jsx':{'custom':7},'moon-widget-index-jsx':{}}
        settings.write_text(json.dumps(original))
        result=self.run_command(['python3',str(helper),'apply',str(source),str(deployed),str(settings),'42'])
        self.assertEqual(result.returncode,0,result.stderr)
        data=json.loads(settings.read_text())
        self.assertEqual(data['foreign-widget-index-jsx'],original['foreign-widget-index-jsx'])
        self.assertEqual(data['clock-widget-index-jsx']['custom'],7)
        self.assertEqual(data['moon-widget-index-jsx']['screens'],[42])
        self.assertEqual(self.run_command(['python3',str(helper),'check',str(source),str(deployed),str(settings),'42']).stdout.strip(),'nochange')

    def test_widget_unconfirmed_deployment_has_no_effects(self):
        script=(REPO/'scripts/scripts/ubersicht-screen-sync.sh').read_text().replace('$HOME','$FIXTURE_ROOT')
        script=script.replace('HELPER="${BASH_SOURCE[0]%/*}/lib/widget-settings.py"','HELPER="'+str(REPO/'scripts/scripts/lib/widget-settings.py')+'"')
        for name in ['swift','osascript','open','pgrep','pkill']:
            self.stub(name,'raise RuntimeError("unexpected desktop action")')
        result=self.run_command(['bash','-c',script],{'FIXTURE_ROOT':str(self.root),'DOTFILES_DIR':str(REPO)})
        self.assertEqual(result.returncode,0)
        self.assertIn('not a confirmed',result.stderr)
        self.assertNotIn('unexpected',result.stderr)

    def test_widget_stubborn_app_leaves_settings(self):
        repo=self.root/'repo'
        source=repo/'ubersicht/Library/Application Support/Übersicht/widgets'
        (source/'moon.widget').mkdir(parents=True)
        (source/'moon.widget/index.jsx').touch()
        deployed=self.root/'Library/Application Support/Übersicht/widgets'
        deployed.parent.mkdir(parents=True);deployed.symlink_to(source)
        settings=self.root/'Library/Application Support/tracesOf.Uebersicht/WidgetSettings.json'
        settings.parent.mkdir(parents=True);settings.write_text('{"moon-widget-index-jsx":{"screens":[1]}}')
        before=settings.read_bytes()
        script=(REPO/'scripts/scripts/ubersicht-screen-sync.sh').read_text().replace('$HOME','$FIXTURE_ROOT')
        script=script.replace('HELPER="${BASH_SOURCE[0]%/*}/lib/widget-settings.py"','HELPER="'+str(REPO/'scripts/scripts/lib/widget-settings.py')+'"')
        bundle=self.root/'fixture.app/Contents';bundle.mkdir(parents=True)
        (bundle/'Info.plist').write_bytes(plistlib.dumps({'CFBundleExecutable':'Übersicht'}))
        script=script.replace('APP="/Applications/Übersicht.app"','APP="'+str(bundle.parent)+'"')
        self.stub('swift','print(42)')
        self.stub('pgrep', "import sys;assert sys.argv[1:] == ['-x', 'Übersicht'];sys.exit(0)")
        self.stub('osascript','pass');self.stub('sleep','pass')
        for name in ['open','pkill']: self.stub(name,'raise RuntimeError("unexpected action")')
        result=self.run_command(['bash','-c',script],{'FIXTURE_ROOT':str(self.root),'DOTFILES_DIR':str(repo)})
        self.assertEqual(settings.read_bytes(),before)
        self.assertIn('did not quit cleanly',result.stderr)
        self.assertNotIn('unexpected',result.stderr)

    def test_optional_obs_actions(self):
        if not shutil.which('nvim'): self.skipTest('Neovim required for optional OBS fixture')
        env={'DOTFILES_TEST_REPO':str(REPO),'XDG_CONFIG_HOME':str(self.root/'config'),'XDG_DATA_HOME':str(self.root/'data'),'XDG_STATE_HOME':str(self.root/'state'),'XDG_CACHE_HOME':str(self.root/'cache')}
        result=self.run_command(['nvim','--headless','--noplugin','-u','NONE','-i','NONE','-c','luafile '+str(REPO/'tests/nvim/obs.lua'),'-c','qa!'],env)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('fixtures passed',result.stderr)
