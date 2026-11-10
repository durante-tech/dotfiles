"""Guards that only matter when something is missing or stale; disposable roots."""
import sys
import time
from support import Fixture, REPO, shell_function


class RuntimeRoot(Fixture):
    def check(self, selected, personal_env=None):
        home=self.root/'home';(home/'.config/dotfiles').mkdir(parents=True,exist_ok=True)
        env_file=home/'.config/dotfiles/personal.env'
        if personal_env is None:
            if env_file.exists():env_file.unlink()
        else:env_file.write_text(personal_env)
        body='print_error() { echo "ERROR $1"; }\n'+shell_function('setup.sh','check_runtime_root')+'\ncheck_runtime_root'
        return self.run_command(['/bin/bash','-c',body],{'HOME':str(home),'DOTFILES_SELECTED_ROOT':str(selected),'DOTFILES_DIR':str(selected)})

    def test_stale_personal_env_is_caught_by_value(self):
        a=self.root/'checkout-a';b=self.root/'checkout-b';a.mkdir();b.mkdir()
        stale=self.check(a,f'export DOTFILES_DIR="{b}"\n')
        self.assertNotEqual(stale.returncode,0,stale.stdout)
        self.assertIn(str(b),stale.stdout)
        self.assertEqual(self.check(a,f'export DOTFILES_DIR="{a}"\n').returncode,0)
        # No personal.env: runtime falls back to ~/dotfiles, which is not checkout A.
        self.assertNotEqual(self.check(a).returncode,0)
        default=self.root/'home/dotfiles';default.mkdir()
        self.assertEqual(self.check(default).returncode,0)

    def test_stale_value_wins_even_when_setup_sourced_it_first(self):
        # setup.sh sources personal.env before defaulting DOTFILES_DIR; by then a
        # comparison against $DOTFILES_DIR alone would be B against B.
        a=self.root/'a';b=self.root/'b';a.mkdir();b.mkdir()
        home=self.root/'home';(home/'.config/dotfiles').mkdir(parents=True)
        (home/'.config/dotfiles/personal.env').write_text(f'export DOTFILES_DIR="{b}"\n')
        body='print_error() { echo "ERROR $1"; }\n'+shell_function('setup.sh','check_runtime_root')+'\ncheck_runtime_root'
        result=self.run_command(['/bin/bash','-c',body],{'HOME':str(home),'DOTFILES_SELECTED_ROOT':str(a),'DOTFILES_DIR':str(b)})
        self.assertNotEqual(result.returncode,0,result.stdout)


class BoundedTimeout(Fixture):
    HELPER=REPO/'sketchybar/.config/sketchybar/timeout.sh'

    def run_limited(self, command):
        script=f'source "{self.HELPER}"; TIMEOUT_BIN=""; with_timeout 1s {command}; echo "status=$?"'
        started=time.monotonic()
        result=self.run_command(['/bin/bash','-c',script])
        return result,time.monotonic()-started

    def test_command_that_ignores_term_is_still_bounded(self):
        # One process, no children: a grandchild that outlived the kill would
        # hold this test's stdout pipe open and measure the pipe, not the helper.
        stubborn=self.root/'stubborn.py'
        stubborn.write_text('import signal,time\nsignal.signal(signal.SIGTERM,signal.SIG_IGN)\ntime.sleep(15)\n')
        result,elapsed=self.run_limited(f'"{sys.executable}" "{stubborn}"')
        self.assertIn('status=124',result.stdout)
        self.assertLess(elapsed,6)

    def test_hung_command_times_out_and_normal_statuses_pass_through(self):
        result,elapsed=self.run_limited('sleep 15')
        self.assertIn('status=124',result.stdout);self.assertLess(elapsed,5)
        self.assertIn('status=0',self.run_limited('true')[0].stdout)
        self.assertIn('status=1',self.run_limited('false')[0].stdout)
