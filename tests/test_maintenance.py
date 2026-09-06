import itertools
import json
import os
import shutil
from support import Fixture, REPO, shell_function


class Maintenance(Fixture):
    def options(self, args):
        code = 'source "$1"; shift; dotfiles_options "$@" || exit $?; printf "%s\\n" "$PROVISION_TOOLS" "$SKIP_BREW" "$SKIP_CASKS" "$UPDATE_ONLY"; dotfiles_bundle_args; printf "%s\\n" "${BUNDLE_ARGS[@]}"'
        return self.run_command(['/bin/bash', '-c', code, 'fixture', str(REPO/'lib/install-options.sh'), *args], {'DOTFILES_DIR': str(self.root)})

    def test_flag_order_and_category_filters(self):
        flags = ['--update','--with-tools','--skip-brew','--skip-casks']
        for length in range(5):
            for selected in itertools.combinations(flags, length):
                expected_tools = '--update' not in selected or '--with-tools' in selected
                expected_brew = '--skip-brew' in selected or not expected_tools
                expected_casks = '--skip-casks' in selected or not expected_tools
                for args in itertools.permutations(selected):
                    with self.subTest(args=args):
                        result = self.options(args)
                        self.assertEqual(result.returncode, 0, result.stderr)
                        lines = result.stdout.splitlines()
                        self.assertEqual(lines[:3], [str(x).lower() for x in [expected_tools,expected_brew,expected_casks]])
                        self.assertEqual('--no-formula' in lines, expected_brew)
                        self.assertEqual('--no-cask' in lines, expected_casks)

    def test_dry_run_never_calls_effectful_tools(self):
        self.root.joinpath('stow-packages.txt').write_text('zsh\ntmux\n')
        forbidden = self.root/'forbidden'
        for name in ['brew','curl','git','nvim','tmux','launchctl','npm','mise','uv','espanso','swiftc','stow','xcode-select']:
            self.stub(name, f"from pathlib import Path\nPath({str(forbidden)!r}).write_text({name!r})\nraise SystemExit(99)\n")
        for args in [[], ['--update'], ['--update','--with-tools'], ['--skip-brew','--skip-casks']]:
            result = self.run_command(['/bin/bash',str(REPO/'install.sh'),'--dry-run',*args], {'DOTFILES_DIR':str(self.root)})
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse(forbidden.exists())

    def test_update_does_not_provision_or_register(self):
        log = self.root/'calls'
        setup = self.root/'setup.sh'
        setup.write_text('#!/bin/bash\nprintf "setup %s\\n" "$*" >> "$REVIEW_LOG"\n')
        setup.chmod(0o755)
        for name in ['brew','curl','nvim','launchctl','npm','mise','uv','espanso','swiftc','git']:
            self.stub(name, "import os,sys\nfrom pathlib import Path\nwith Path(os.environ['REVIEW_LOG']).open('a') as f:f.write("+repr(name)+"+' '+str(sys.argv[1:])+'\\n')\n")
        result = self.run_command(['/bin/bash',str(REPO/'install.sh'),'--update'], {'DOTFILES_DIR':str(self.root),'REVIEW_LOG':str(log)})
        calls = log.read_text()
        self.assertIn('setup --stow',calls)
        self.assertIn('setup --check',calls)
        self.assertIn('nvim ',calls)
        for forbidden in ['brew ','curl ','launchctl ','npm ','mise ','uv ','espanso ','swiftc ','setup --configure','setup --provision']:
            self.assertNotIn(forbidden,calls)
        self.assertNotIn('git pull',calls)
        self.assertIn(result.returncode,[0,1])  # A missing local TPM is reported, never installed.

    def test_update_aggregates_failures(self):
        setup=self.root/'setup.sh';setup.write_text('#!/bin/bash\nprintf "%s\\n" "$1"\nexit 1\n');setup.chmod(0o755)
        script='source "$1"; dotfiles_sync_plugins() { echo plugin-phase; return 1; }; dotfiles_update'
        r=self.run_command(['/bin/bash','-c',script,'fixture',str(REPO/'lib/maintenance.sh')],{'DOTFILES_DIR':str(self.root)})
        self.assertEqual(r.returncode,1)
        for phase in ['--stow','plugin-phase','--check']:self.assertIn(phase,r.stdout)
        self.assertNotIn('update completed',r.stdout)

    def test_check_preserves_dependency_failure(self):
        code='check_dependencies() { return 1; }; verify_config() { echo verified; return 0; };\n'+shell_function('setup.sh','main')+'\nmain --check'
        r=self.run_command(['/bin/bash','-c',code])
        self.assertEqual(r.returncode,1)
        self.assertIn('verified',r.stdout)

    def test_provisioned_update_reports_failure_and_keeps_desktop_registration_out(self):
        # Copy the executable with only home references redirected to a fixture;
        # all effectful commands are intercepted, including provider tools.
        repo=self.root/'repo';repo.mkdir();(repo/'lib').mkdir()
        for name in ['install-options.sh','maintenance.sh']:
            source=(REPO/'lib'/name).read_text().replace('$HOME','$FIXTURE_HOME')
            (repo/'lib'/name).write_text(source)
        (repo/'install.sh').write_text((REPO/'install.sh').read_text().replace('$HOME','$FIXTURE_HOME'))
        (repo/'stow-packages.txt').write_text('sample\n')
        (repo/'sample').mkdir();(repo/'Brewfile').touch()
        (repo/'tmux/.config/tmux').mkdir(parents=True)
        (repo/'tmux/.config/tmux/tmux.conf').write_text("set -g @plugin 'tmux-plugins/tpm'\n")
        (self.root/'.config/tmux/.tmux/plugins/tpm/.git').mkdir(parents=True)
        (self.root/'.sdkman/bin').mkdir(parents=True)
        (self.root/'.sdkman/bin/sdkman-init.sh').write_text('sdk() { return 0; };\n')
        log=self.root/'calls'
        source="import os,sys\nfrom pathlib import Path\na=sys.argv[1:]\nwith Path(os.environ['REVIEW_LOG']).open('a') as f:f.write(Path(sys.argv[0]).name+' '+str(a)+'\\n')\n"
        for name in ['brew','curl','nvim','launchctl','npm','mise','uv','espanso','swiftc','git','xcode-select','bun','go','gh','fabric','opencode','tmux','stow','starship','zoxide','fzf']:
            self.stub(name, source + ("raise SystemExit(1)\n" if name=='go' else "print('fixture')\n"))
        setup=repo/'setup.sh';setup.write_text('#!/bin/bash\nprintf "setup %s\\n" "$1" >> "$REVIEW_LOG"\n');setup.chmod(0o755)
        result=self.run_command(['bash',str(repo/'install.sh'),'--skip-brew','--with-tools','--update','--skip-casks'],{'FIXTURE_HOME':str(self.root),'DOTFILES_DIR':str(repo),'REVIEW_LOG':str(log)})
        self.assertEqual(result.returncode,1,result.stdout+result.stderr)
        self.assertIn('Fabric upgrade failed',result.stdout)
        calls=log.read_text()
        self.assertIn('setup --provision',calls)
        self.assertIn('nvim ',calls)
        for forbidden in ['brew ', 'launchctl ', 'espanso ', 'setup --configure', 'core.hooksPath']:
            self.assertNotIn(forbidden,calls)


class StowStatus(Fixture):
    def run_function(self,name):
        helpers='\n'.join(shell_function('setup.sh',n) for n in ['print_header','print_success','print_warning','print_info','print_error'])
        body=shell_function('setup.sh',name).replace('$HOME','$DOTFILES_FIXTURE_HOME').replace('-t ~','-t "$DOTFILES_FIXTURE_HOME"')
        return self.run_command(['/bin/bash','-c',helpers+'\n'+body+'\n'+name],{'DOTFILES_DIR':str(self.root/'repo'),'DOTFILES_FIXTURE_HOME':str(self.root/'target')})

    def test_conflict_and_missing_manifest_fail(self):
        if not shutil.which('stow'):self.skipTest('stow required')
        r=self.root/'repo';t=self.root/'target';r.mkdir();t.mkdir()
        for name in ['stow_packages','check_stow_drift']:
            self.assertNotEqual(self.run_function(name).returncode,0)
        (r/'sample').mkdir();(r/'sample/.sample').write_text('repo');(t/'.sample').write_text('user')
        (r/'stow-packages.txt').write_text('sample\n')
        for name in ['stow_packages','check_stow_drift']:
            self.assertNotEqual(self.run_function(name).returncode,0)
            self.assertEqual((t/'.sample').read_text(),'user')

    def test_runtime_exclusion_keeps_existing_link(self):
        if not shutil.which('stow'):self.skipTest('stow required')
        r=self.root/'repo';p=r/'tmux';t=self.root/'target'
        (p/'.dos').mkdir(parents=True);t.mkdir();(t/'.dos').mkdir()
        (p/'.dos/isc-state.json').write_text('private runtime')
        (t/'.dos/isc-state.json').symlink_to(p/'.dos/isc-state.json')
        shutil.copy2(REPO/'tmux/.stow-local-ignore',p/'.stow-local-ignore')
        result=self.run_command(['stow','-n','-v','-R','-d',str(r),'-t',str(t),'tmux'])
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertNotIn('isc-state.json',result.stderr)
        self.assertTrue((t/'.dos/isc-state.json').is_symlink())


class PullPreview(Fixture):
    def setUp(self):
        super().setUp()
        (self.root/'docs').mkdir();shutil.copy2(REPO/'docs/POSTPULL_PROMPT.md',self.root/'docs/POSTPULL_PROMPT.md')
        self.log=self.root/'calls'
        self.stub('git', r'''import os,sys
from pathlib import Path
a=sys.argv[1:]
with Path(os.environ['REVIEW_LOG']).open('a') as f:f.write('git '+' '.join(a)+'\n')
if a[0]=='pull':raise SystemExit(1)
if a[0]=='rev-parse':print('a'*40)
if a[0]=='rev-list':print('a'*40)
''')
        self.stub('claude', "raise SystemExit('agent launch forbidden in fixture')\n")

    def test_one_commit_preview_and_noop_range(self):
        for args in [['--print-prompt'],['--no-pull','--print-prompt']]:
            result=self.run_command(['/bin/bash',str(REPO/'smart-pull.sh'),*args],{'DOTFILES_DIR':str(self.root),'REVIEW_LOG':str(self.log)})
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertIn('no Claude session opened',result.stdout)
            self.assertNotIn('git pull',self.log.read_text())

    def test_failed_pull_does_not_report_up_to_date(self):
        result=self.run_command(['/bin/bash',str(REPO/'smart-pull.sh')],{'DOTFILES_DIR':str(self.root),'REVIEW_LOG':str(self.log)})
        self.assertNotEqual(result.returncode,0)
        self.assertNotIn('Already up to date',result.stdout)
        self.assertIn('Pull failed',result.stderr)
        self.assertIn('git pull --ff-only',self.log.read_text())
