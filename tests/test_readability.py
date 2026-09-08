"""Readability rendering stays inside fixtures; native checks use headless parsers."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from unittest.mock import patch
from support import Fixture, REPO

sys.path.insert(0, str(REPO/'scripts/scripts/lib'))
from dotfiles_preferences.envfile import PreferenceError
from dotfiles_preferences.model import Preferences, validate_value
from dotfiles_preferences.readability import (HEADER, KEYS, MARKER, discover_fonts,
    families_from_profiler, output_paths, render_files, require_font, validate_owned)


class Readability(Fixture):
    def setUp(self):
        super().setUp()
        self.home = self.root/'home with spaces'
        self.prefs = Preferences(REPO, self.home/'.config/dotfiles', self.home)
        self.values = self.prefs.effective()[0]

    def test_unset_preserves_distinct_base_sizes_and_creates_no_files(self):
        files = render_files(self.prefs, self.values)
        self.assertEqual(set(files), set(output_paths(self.prefs)))
        self.assertTrue(all(value == HEADER for value in files.values()))
        self.assertFalse(self.home.exists())
        self.assertIn('font-size = 16\n', (REPO/'ghostty/.config/ghostty/config').read_text())
        self.assertIn('font_size 14.0\n', (REPO/'kitty/.config/kitty/kitty.conf').read_text())

    def test_only_requested_terminal_size_changes_and_reset_removes_directive(self):
        self.values['readability.kitty_font_size'] = 17.5
        ghostty, kitty = output_paths(self.prefs)
        files = render_files(self.prefs, self.values)
        self.assertEqual(files[ghostty], HEADER)
        self.assertIn(b'font_size 17.5\n', files[kitty])
        self.values['readability.kitty_font_size'] = None
        self.assertEqual(render_files(self.prefs, self.values)[kitty], HEADER)

    def test_family_and_opacity_project_as_literal_directives(self):
        self.values.update({'readability.font_family': "O'Brien Mono (Test)",
                            'readability.background_opacity': 1})
        ghostty, kitty = (value.decode() for value in render_files(self.prefs, self.values).values())
        self.assertIn("font-family =\nfont-family = O'Brien Mono (Test)\n", ghostty)
        self.assertIn("font_family O'Brien Mono (Test)\n", kitty)
        self.assertIn('background-opacity = 1\n', ghostty)
        self.assertIn('background_opacity 1\n', kitty)

    def test_invalid_numbers_and_config_syntax_are_rejected_before_rendering(self):
        for key in ('readability.ghostty_font_size', 'readability.kitty_font_size', 'readability.background_opacity'):
            for value in (True, '16', float('nan'), float('inf'), -1, {}, 100, 10 ** 1000):
                with self.subTest(key=key, value=value):
                    with self.assertRaises(PreferenceError):
                        validate_value(key, value, REPO, self.home)
        for value in ('Mono\ninclude bad', 'Mono\rmap cmd+x quit', '\\Mono', '"Mono"', 'family=Mono',
                      '$(touch marker)', 'Mono; command', 'Mono#comment', ' Mono', 'Mono ', '\tMono', ''):
            with self.subTest(value=value):
                with self.assertRaises(PreferenceError):
                    render_files(self.prefs, dict(self.values, **{'readability.font_family': value}))
        self.assertFalse(self.home.exists())

    def test_numeric_boundaries_and_null_are_supported(self):
        for key in KEYS:
            validate_value(key, None, REPO, self.home)
        for key in ('readability.ghostty_font_size', 'readability.kitty_font_size'):
            for value in (8, 16.25, 40):
                validate_value(key, value, REPO, self.home)
        for value in (0.2, 0.75, 1):
            validate_value('readability.background_opacity', value, REPO, self.home)

    def test_ownership_rejects_foreign_files_and_symlinks(self):
        path = output_paths(self.prefs)[0]
        validate_owned(path, None)
        validate_owned(path, HEADER)
        for value in (b'font-size = 17\n', b'# custom\n'+MARKER, MARKER.rstrip(b'\n')):
            with self.assertRaises(PreferenceError):
                validate_owned(path, value)
        path.parent.mkdir(parents=True)
        target = self.root/'foreign'; target.write_bytes(HEADER)
        path.symlink_to(target)
        with self.assertRaises(PreferenceError): validate_owned(path, HEADER)
        path.unlink(); path.parent.rmdir(); path.parent.symlink_to(self.root, target_is_directory=True)
        with self.assertRaises(PreferenceError): validate_owned(path, None)

    def test_font_metadata_requires_enabled_valid_named_faces(self):
        data = {'SPFontsDataType': [
            {'typefaces': [{'family': 'Mono A'}, {'family': 'Mono B', 'enabled': 'no'},
                           {'family': 'Mono C', 'valid': 'no'}, {'family': 1}, {'family': 'Mono A'}]},
            {'enabled': 'no', 'typefaces': [{'family': 'Disabled Font'}]},
            {'typefaces': 'invalid'}, None,
        ]}
        self.assertEqual(families_from_profiler(data), ['Mono A'])
        require_font({'readability.font_family': 'mono a'}, ['Mono A'])
        require_font({'readability.font_family': None}, [])
        with self.assertRaises(PreferenceError): require_font({'readability.font_family': 'Missing'}, ['Mono A'])
        with self.assertRaises(PreferenceError): families_from_profiler([])

    def test_font_discovery_is_one_read_only_command_and_reports_failure(self):
        success = subprocess.CompletedProcess([], 0, json.dumps({'SPFontsDataType': [
            {'typefaces': [{'family': 'Fixture Mono'}]}]}), '')
        with patch('dotfiles_preferences.readability.sys.platform', 'darwin'), \
                patch('dotfiles_preferences.readability.subprocess.run', return_value=success) as run:
            self.assertEqual(discover_fonts(), ['Fixture Mono'])
            self.assertEqual(run.call_args.args[0], ['/usr/sbin/system_profiler', 'SPFontsDataType', '-json'])
            self.assertEqual(run.call_count, 1)
            run.return_value = subprocess.CompletedProcess([], 1, '', 'private diagnostic')
            with self.assertRaisesRegex(PreferenceError, 'Font discovery failed'): discover_fonts()
            run.side_effect = subprocess.TimeoutExpired('fixture', 20)
            with self.assertRaisesRegex(PreferenceError, 'unavailable'): discover_fonts()

    def test_native_ghostty_optional_include_precedence_and_reset(self):
        executable = shutil.which('ghostty') or '/Applications/Ghostty.app/Contents/MacOS/ghostty'
        if not Path(executable).is_file(): self.skipTest('Ghostty headless parser is not installed')
        config = self.home/'.config/ghostty'; config.parent.mkdir(parents=True)
        shutil.copytree(REPO/'ghostty/.config/ghostty', config)
        env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home/'.config'))
        def read():
            process = subprocess.run([executable, '+show-config'], env=env, capture_output=True, text=True, timeout=10)
            self.assertEqual(process.returncode, 0, process.stderr)
            self.assertNotIn('FileNotFound', process.stderr)
            return process.stdout
        self.assertIn('font-size = 16\n', read())
        self.values.update({'readability.ghostty_font_size': 19.5,
                            'readability.font_family': "O'Brien Mono (Test)",
                            'readability.background_opacity': 0.95})
        path = output_paths(self.prefs)[0]; path.parent.mkdir(parents=True)
        path.write_bytes(render_files(self.prefs, self.values)[path])
        effective = read()
        self.assertIn('font-size = 19.5\n', effective)
        self.assertIn("font-family = O'Brien Mono (Test)\n", effective)
        self.assertNotIn('font-family = JetBrainsMono', effective)
        self.assertIn('background-opacity = 0.95\n', effective)
        path.write_bytes(HEADER)
        self.assertIn('font-size = 16\n', read())

    def test_native_kitty_home_include_through_stow_link_and_reset(self):
        executable = shutil.which('kitty')
        if not executable: self.skipTest('Kitty headless parser is not installed')
        source = self.root/'checkout/kitty/.config/kitty'
        shutil.copytree(REPO/'kitty/.config/kitty', source)
        (self.home/'.config').mkdir(parents=True)
        (self.home/'.config/kitty').symlink_to(source, target_is_directory=True)
        env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home/'.config'),
                   KITTY_CONFIG_DIRECTORY=str(self.home/'.config/kitty'))
        script = ('import json; from kitty.config import load_config; bad=[]; o=load_config('
                  + repr(str(self.home/'.config/kitty/kitty.conf')) + ',accumulate_bad_lines=bad); '
                  'print(json.dumps({"size":o.font_size,"opacity":o.background_opacity,"bad":str(bad)}))')
        def read():
            process = subprocess.run([executable, '+runpy', script], env=env, capture_output=True, text=True, timeout=10)
            self.assertEqual(process.returncode, 0, process.stderr)
            data = json.loads(process.stdout); self.assertEqual(data['bad'], '[]')
            return data, process.stderr
        initial, diagnostic = read()
        self.assertEqual(initial['size'], 14)
        self.assertIn('Could not find included config file', diagnostic)
        self.values.update({'readability.kitty_font_size': 18.5, 'readability.background_opacity': 1})
        path = output_paths(self.prefs)[1]; path.parent.mkdir(parents=True)
        path.write_bytes(render_files(self.prefs, self.values)[path])
        effective, diagnostic = read()
        self.assertEqual(effective['size'], 18.5); self.assertEqual(effective['opacity'], 1)
        self.assertNotIn('Could not find included config file', diagnostic)
        path.write_bytes(HEADER)
        self.assertEqual(read()[0]['size'], 14)
