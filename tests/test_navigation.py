import hashlib
import json
import os
from support import Fixture, REPO


class Navigation(Fixture):
    def setUp(self):
        super().setUp()
        self.state = self.root/'state.json'
        self.state.write_text('{"sessions":{},"calls":[]}')
        self.environment = {'REVIEW_STATE':str(self.state)}
        self.stub('tmux', r'''import os,sys,json
from pathlib import Path
p=Path(os.environ['REVIEW_STATE']);d=json.loads(p.read_text());a=sys.argv[1:];d['calls'].append(a)
def target():return a[a.index('-t')+1].removeprefix('=').removesuffix(':')
rc=0
if a[0]=='has-session':rc=0 if target() in d['sessions'] else 1
elif a[0]=='new-session':
 name=a[a.index('-s')+1]
 if name in d['sessions']:rc=1
 else:d['sessions'][name]={'path':a[a.index('-c')+1],'metadata':''}
elif a[0] in ['show-option','display-message']:
 if target() not in d['sessions']:rc=1
 else:print(d['sessions'][target()]['metadata' if a[0]=='show-option' else 'path'])
elif a[0]=='set-option':d['sessions'][target()]['metadata']=a[-1]
elif a[0] in ['kill-session','rename-session','setenv']:raise SystemExit('forbidden mutation')
p.write_text(json.dumps(d));raise SystemExit(rc)
''')
        self.stub('kitty', r'''import os,sys,json
from pathlib import Path
p=Path(os.environ['REVIEW_STATE']);d=json.loads(p.read_text());d['calls'].append(['kitty',*sys.argv[1:]]);p.write_text(json.dumps(d))
''')

    def project(self, name):
        p=self.root/name;p.mkdir(parents=True,exist_ok=True)
        (p/'.tmux-sessionizer').write_text('printf hydrated\n')
        return p

    def run_picker(self, path, program='tmux-sessionizer', extra=None):
        return self.run_command(['/bin/bash',str(REPO/'scripts/scripts'/program),str(path)],dict(self.environment,**(extra or {})))

    def data(self):return json.loads(self.state.read_text())

    def test_same_basename_and_alias_have_correct_owners(self):
        first=self.project('a/app');second=self.project('b/app');alias=self.root/'alias';alias.symlink_to(first)
        for p in [first,second,alias]:
            r=self.run_picker(p);self.assertEqual(r.returncode,0,r.stderr)
        data=self.data();self.assertEqual(len(data['sessions']),2)
        for path in [first,second]:
            name='app--'+hashlib.sha256(str(path.resolve()).encode()).hexdigest()[:12]
            self.assertEqual(data['sessions'][name]['metadata'],str(path.resolve()))

    def test_legacy_session_reused_only_for_its_project(self):
        first=self.project('a/app');second=self.project('b/app')
        self.state.write_text(json.dumps({'sessions':{'app':{'path':str(first.resolve()),'metadata':''}},'calls':[]}))
        self.assertEqual(self.run_picker(first).returncode,0)
        self.assertEqual(len(self.data()['sessions']),1)
        self.assertFalse(any(c[0]=='send-keys' for c in self.data()['calls']))
        self.assertEqual(self.run_picker(second).returncode,0)
        self.assertEqual(len(self.data()['sessions']),2)
        self.assertEqual(self.data()['sessions']['app']['path'],str(first.resolve()))

    def test_digest_collision_refuses_reuse(self):
        self.stub('sha256sum', "print('a'*64+'  -')\n")
        first=self.project('a/app');second=self.project('b/app')
        self.assertEqual(self.run_picker(first).returncode,0)
        before=self.data()['sessions']
        r=self.run_picker(second)
        self.assertNotEqual(r.returncode,0)
        self.assertIn('collision',r.stderr)
        self.assertEqual(self.data()['sessions'],before)

    def test_hydration_is_literal_and_paths_keep_newlines(self):
        p=self.project('app $(touch injected)\n')
        result=self.run_picker(p);self.assertEqual(result.returncode,0,result.stderr)
        command=next(c[-1] for c in self.data()['calls'] if c[0]=='send-keys' and '-l' in c)
        result=self.run_command(['/bin/zsh','-dfc',command],{'ZDOTDIR':str(self.root)})
        self.assertEqual(result.stdout,'hydrated')
        self.assertFalse((self.root/'injected').exists())
        self.assertEqual(next(iter(self.data()['sessions'].values()))['path'],str(p.resolve()))

    def test_kitty_connection_is_required_and_preserved(self):
        p=self.project('project')
        r=self.run_picker(p,'kitty-sessionizer',{'KITTY_LISTEN_ON':''})
        self.assertNotEqual(r.returncode,0);self.assertEqual(self.data()['calls'],[])
        for socket in ['unix:/tmp/fixture-one','unix:/tmp/fixture-two']:
            r=self.run_picker(p,'kitty-sessionizer',{'KITTY_LISTEN_ON':socket})
            self.assertEqual(r.returncode,0,r.stderr)
            self.assertIn(socket,self.data()['calls'][-1])

    def test_null_discovery_and_cancellation(self):
        p=self.project('root with spaces/app\nname')
        self.stub('fd', r'''import os,sys,json
from pathlib import Path
Path(os.environ['REVIEW_ARGS']).write_text(json.dumps(sys.argv[1:]));sys.stdout.buffer.write(os.environ['REVIEW_SELECTED'].encode()+b'\0')
''')
        self.stub('fzf', r'''import os,sys
if os.environ.get('REVIEW_CANCEL'):raise SystemExit(130)
sys.stdout.buffer.write(sys.stdin.buffer.read())
''')
        args=self.root/'fd-args.json'
        env=dict(self.environment,DOTFILES_SESSIONIZER_PATHS=str(p.parent),REVIEW_SELECTED=str(p),REVIEW_ARGS=str(args))
        r=self.run_command(['/bin/bash',str(REPO/'scripts/scripts/tmux-sessionizer')],env)
        self.assertEqual(r.returncode,0,r.stderr)
        self.assertIn(str(p.parent),json.loads(args.read_text()))
        self.assertEqual(next(iter(self.data()['sessions'].values()))['path'],str(p.resolve()))
        count=len(self.data()['calls'])
        r=self.run_command(['/bin/bash',str(REPO/'scripts/scripts/tmux-sessionizer')],dict(env,REVIEW_CANCEL='1'))
        self.assertEqual(r.returncode,0,r.stderr);self.assertEqual(len(self.data()['calls']),count)

    def test_missing_directory_and_roots_fail(self):
        self.assertNotEqual(self.run_picker(self.root/'absent').returncode,0)
        code='source "$1"; sessionizer_roots'
        result=self.run_command(['/bin/bash','-uc',code,'fixture',str(REPO/'scripts/scripts/lib/sessionizer.sh')],{'DOTFILES_SESSIONIZER_PATHS':str(self.root/'absent')})
        self.assertEqual(result.returncode,2,result.stderr)

    def test_shell_never_invents_kitty_identity(self):
        source=(REPO/'zsh/.zshrc').read_text()
        self.assertNotIn('tmux setenv KITTY_',source)
        self.assertNotIn('_kitty_wid',source)
