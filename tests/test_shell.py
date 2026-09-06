from support import Fixture, REPO


class ShellStartup(Fixture):
    def block(self):
        source = (REPO / 'zsh/.zshrc').read_text()
        return source[source.index('# Google Cloud SDK —'):]

    def test_missing_sdk_is_optional(self):
        result = self.run_command(['/bin/zsh', '-dfc', self.block() + '\ntrue'],
                                  {'ZDOTDIR': str(self.root), 'DOTFILES_GCLOUD_SDK_DIR': str(self.root/'absent'), 'ZSH_PROFILE': ''})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, '')
        self.assertEqual(result.stderr, '')

    def test_spaces_and_profile_order(self):
        sdk = self.root / 'SDK with spaces'
        sdk.mkdir()
        (sdk/'path.zsh.inc').write_text('print -r -- sdk-path\n')
        (sdk/'completion.zsh.inc').write_text('print -r -- sdk-completion\n')
        result = self.run_command(['/bin/zsh', '-dfc', 'zprof() { print -r -- profile; }\n' + self.block()],
                                  {'ZDOTDIR': str(self.root), 'DOTFILES_GCLOUD_SDK_DIR': str(sdk), 'ZSH_PROFILE': '1'})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), ['sdk-path', 'sdk-completion', 'profile'])

    def test_startup_files_parse(self):
        for filename in ['.zshrc', '.zprofile']:
            result = self.run_command(['/bin/zsh', '-n', str(REPO/'zsh'/filename)])
            self.assertEqual(result.returncode, 0, result.stderr)
