import json
import os
from pathlib import Path
import shutil
from support import Fixture, REPO

LISTING = '''Persistent screen id: AAAA
Type: MacBook built in screen
Resolution: 1728x1117
Scaling: on
Origin: (0,0) - main display
Rotation: 0
Persistent screen id: BBBB
Type: external screen
Resolution: 1920x1080
Scaling: on
Origin: (1728,37)
Rotation: 0
'''


class Layout(Fixture):
    def setUp(self):
        super().setUp()
        self.cache=self.root/'cache';self.cache.mkdir()
        self.profile=self.cache/'bd-profile';self.profile.write_text('portrait-hires')
        # Only home and log paths are redirected; all displayplacer calls hit a fake.
        source=(REPO/'scripts/scripts/lib/display-layout.sh').read_text().replace('$HOME','$FIXTURE_HOME')
        source=source.replace('LOG="/tmp/display-restore.log"','LOG="'+str(self.root/'layout.log')+'"')
        self.script=self.root/'layout.sh';self.script.write_text(source)
        self.log=self.root/'calls'
        self.stub('displayplacer', '''import os,sys
from pathlib import Path
if sys.argv[1:]==['list']:print('''+repr(LISTING)+''')
else:
 with Path(os.environ['CALLS']).open('a') as f:f.write('write\\n')
 raise SystemExit(int(os.environ.get('DP_RESULT','7')))
''')
        self.env={'FIXTURE_HOME':str(self.root),'DOTFILES_DIR':str(self.root),
                  'DOTFILES_DISPLAY_STATE_DIR':str(self.cache),'CALLS':str(self.log),'DOTFILES_DISPLAY_LAYOUT_LOCKED':'1'}

    def test_failed_apply_returns_failure_and_retains_profile(self):
        result=self.run_command(['bash',str(self.script),'--daily','--force'],self.env)
        self.assertEqual(result.returncode,1,result.stderr)
        self.assertEqual(self.profile.read_text(),'portrait-hires')
        self.assertEqual(self.log.read_text(),'write\n')

    def test_dry_run_wins_in_both_orders_without_state_or_log_writes(self):
        for args in [['--dry-run','--force'],['--force','--dry-run']]:
            result=self.run_command(['bash',str(self.script),*args],self.env)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertFalse(self.log.exists())
            self.assertFalse((self.root/'layout.log').exists())
            self.assertEqual(self.profile.read_text(),'portrait-hires')

    def test_unchanged_layout_commits_profile_without_reapplying(self):
        result=self.run_command(['bash',str(self.script),'--daily'],self.env)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertFalse(self.log.exists())
        self.assertEqual(self.profile.read_text(),'daily\n')

    def test_failed_readback_does_not_commit_new_profile(self):
        result=self.run_command(['bash',str(self.script),'--portrait','--force'],dict(self.env,DP_RESULT='0'))
        self.assertEqual(result.returncode,1,result.stderr)
        self.assertEqual(self.profile.read_text(),'portrait-hires')

    def test_successful_apply_requires_readback_and_commits_atomically(self):
        result=self.run_command(['bash',str(self.script),'--daily','--force'],dict(self.env,DP_RESULT='0'))
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(self.profile.read_text(),'daily\n')
        self.assertEqual(list(self.cache.glob('.bd-profile.*')),[])

    def test_unknown_arguments_fail_before_any_display_command(self):
        result=self.run_command(['bash',str(self.script),'--portraitt'],self.env)
        self.assertEqual(result.returncode,2)
        self.assertFalse(self.log.exists())


class Watcher(Fixture):
    def test_each_poll_retries_pending_action_without_real_commands(self):
        target=self.root/'scripts/scripts';target.mkdir(parents=True)
        apply=target/'bd-apply.sh'
        apply.write_text('''#!/bin/bash
case "$1" in
 sensor) echo 25 ;;
 probe) exit 0 ;;
 ambient) echo "$*" >> "$CALLS"; exit 75 ;;
 *) exit 99 ;;
esac
''');apply.chmod(0o755)
        for name in ['sketchybar','sleep','ioreg']:
            self.stub(name,'pass')
        source=(REPO/'scripts/scripts/bd-lmu-watch.sh').read_text().replace('$HOME','$FIXTURE_HOME')
        source=source.replace('while true; do','for fixture_poll in 1 2; do')
        for name in ['bucket','watch.log','sensor-alert']:
            source=source.replace('/tmp/bd-lmu-'+name,str(self.root/name))
        result=self.run_command(['bash','-c',source],{'FIXTURE_HOME':str(self.root),'DOTFILES_DIR':str(self.root),'CALLS':str(self.root/'calls')})
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual((self.root/'calls').read_text().splitlines(),['ambient night','ambient night'])


class RaycastEnvironment(Fixture):
    def test_locale_normalization_is_local_to_script(self):
        target=self.root/'scripts/scripts';target.mkdir(parents=True)
        apply=target/'bd-apply.sh'
        apply.write_text('#!/bin/bash\nprintf "Manual · Ready\\n"\n')
        apply.chmod(0o755)
        script=self.root/'bd-status.sh'
        script.write_text((REPO/'raycast/script-commands/bd-status.sh').read_text().replace('$HOME','$FIXTURE_HOME'))
        script.chmod(0o755)
        result=self.run_command([str(script)],{'DOTFILES_DIR':str(self.root),'FIXTURE_HOME':str(self.root),
                                              'LC_ALL':'en-US-u-ca-gregory-co-standard-cu-usd'})
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(result.stdout.strip(),'Manual · Ready')
        self.assertEqual(result.stderr,'')
