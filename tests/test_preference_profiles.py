"""Profile fixtures only read/plan personal state in disposable roots."""
import json
import shutil
import sys

from support import Fixture, REPO

sys.path.insert(0, str(REPO/'scripts/scripts/lib'))
from dotfiles_preferences.envfile import PreferenceError
from dotfiles_preferences.model import Preferences, FIELDS
from dotfiles_preferences.profiles import (
    allowed_keys, capture_snapshot, list_profiles, load, save_plan, show_profile, use_plan,
)
from dotfiles_preferences.storage import Plan


class PreferenceProfiles(Fixture):
    def setUp(self):
        super().setUp()
        self.repo = self.root/'repo with spaces'
        template = self.repo/'aerospace/templates/aerospace.toml.template'
        template.parent.mkdir(parents=True)
        shutil.copy2(REPO/'aerospace/templates/aerospace.toml.template', template)
        self.config = self.root/'personal'
        self.prefs = Preferences(self.repo, self.config, self.root/'home')
        self.file = self.config/'profiles.json'

    def install_saved_fixture(self, plan):
        """Emulate just a profile-file commit, never a real user transaction."""
        self.config.mkdir(exist_ok=True)
        self.file.write_bytes(plan.files[self.file])

    def write_overrides(self, values):
        self.config.mkdir(exist_ok=True)
        self.prefs.file.write_text(json.dumps({'version': 1, 'values': values}))

    def record(self, name='desk', **changes):
        result = {'name': name, 'owns': ['workspaces.browser'],
                  'values': {'workspaces.browser': '2'}, 'reset': []}
        result.update(changes)
        return result

    def serialized(self, *entries):
        return json.dumps({'version': 1, 'profiles': list(entries)}).encode()

    def test_starters_remain_unconfigured_and_reading_creates_no_files(self):
        entries = list_profiles(self.prefs)
        self.assertEqual([entry['name'] for entry in entries], ['laptop', 'desk', 'presentation'])
        self.assertEqual([entry['label'] for entry in entries], ['Laptop', 'Desk', 'Presentation'])
        self.assertTrue(all(entry['state'] == 'unconfigured' and not entry['owns'] for entry in entries))
        self.assertFalse(self.config.exists())
        for name in ('laptop', 'desk', 'presentation'):
            with self.assertRaisesRegex(PreferenceError, 'unconfigured'):
                use_plan(self.prefs, name)
        self.assertFalse(self.config.exists())

    def test_capture_saves_only_declared_effective_values_without_applying(self):
        self.config.mkdir()
        original = 'DOTFILES_SESSIONIZER_PATHS="$HOME/Work Projects\n$HOME/Personal"\nUNRELATED=keep\n'
        self.prefs.env.write_text(original)
        self.write_overrides({'workspaces.browser': '2', 'apps.editor': None})
        plan = save_plan(self.prefs, 'desk', ['projects.roots', 'workspaces.browser', 'apps.editor'])
        data = load(self.prefs, plan.files[self.file])
        self.assertEqual(data['profiles'][0]['values'], {
            'projects.roots': ['$HOME/Work Projects', '$HOME/Personal'],
            'workspaces.browser': '2', 'apps.editor': None,
        })
        self.assertEqual((plan.action, plan.name, plan.patch, plan.reset), ('save', 'desk', {}, ()))
        self.assertEqual(set(plan.files), {self.file})
        self.assertFalse(self.file.exists())
        self.assertEqual(self.prefs.env.read_text(), original)
        self.assertEqual(self.prefs.overrides()['values']['workspaces.browser'], '2')

    def test_use_changes_only_owned_preferences_and_keeps_display_state(self):
        saved = save_plan(self.prefs, 'desk', ['workspaces.browser'], values={'workspaces.browser': '2'})
        self.install_saved_fixture(saved)
        self.write_overrides({'display.builtin_serial': 'ABC123', 'apps.notes': 'org.example.Notes',
                              'projects.roots': ['~/Unrelated'], 'workspaces.browser': 'B'})
        state = self.config/'display-controller.json'
        state.write_text('{"mode":"manual","brightness":42,"calibration":"keep"}')
        plan = use_plan(self.prefs, 'desk')
        self.assertEqual((plan.patch, plan.reset, plan.files), ({'workspaces.browser': '2'}, (), {}))
        # The existing preference transaction consumes only the returned patch/reset.
        Plan(self.prefs, patch=plan.patch, reset=plan.reset).apply()
        values = self.prefs.overrides()['values']
        self.assertEqual(values['workspaces.browser'], '2')
        self.assertEqual(values['display.builtin_serial'], 'ABC123')
        self.assertEqual(values['apps.notes'], 'org.example.Notes')
        self.assertEqual(values['projects.roots'], ['~/Unrelated'])
        self.assertEqual(state.read_text(), '{"mode":"manual","brightness":42,"calibration":"keep"}')

    def test_saved_null_is_distinct_from_reset_and_reset_uses_current_fallback(self):
        self.write_overrides({'apps.editor': 'org.example.Editor', 'workspaces.browser': '2'})
        saved = save_plan(self.prefs, 'presentation', ['apps.editor', 'workspaces.browser'],
                          values={'apps.editor': None}, reset=['workspaces.browser'])
        self.install_saved_fixture(saved)
        plan = use_plan(self.prefs, 'presentation')
        self.assertEqual(plan.patch, {'apps.editor': None})
        self.assertEqual(plan.reset, ('workspaces.browser',))
        Plan(self.prefs, patch=plan.patch, reset=plan.reset).apply()
        self.assertIsNone(self.prefs.overrides()['values']['apps.editor'])
        self.assertNotIn('workspaces.browser', self.prefs.overrides()['values'])
        self.assertEqual(self.prefs.effective()[0]['workspaces.browser'], 'B')
        self.assertEqual(show_profile(self.prefs, 'presentation')['state'], 'matches')

    def test_reset_is_different_until_override_removed_even_if_value_matches(self):
        self.write_overrides({'workspaces.browser': 'B'})
        self.install_saved_fixture(save_plan(self.prefs, 'laptop', ['workspaces.browser'],
                                             values={}, reset=['workspaces.browser']))
        result = show_profile(self.prefs, 'laptop')
        self.assertEqual(result['state'], 'different')
        self.assertEqual(result['different'], ['workspaces.browser'])

    def test_matching_is_derived_and_multiple_profiles_can_match(self):
        self.install_saved_fixture(save_plan(self.prefs, 'laptop', ['workspaces.browser']))
        self.install_saved_fixture(save_plan(self.prefs, 'desk', ['workspaces.browser']))
        self.assertEqual(show_profile(self.prefs, 'laptop')['state'], 'matches')
        self.assertEqual(show_profile(self.prefs, 'desk')['state'], 'matches')
        self.write_overrides({'workspaces.browser': '2'})
        self.assertEqual(show_profile(self.prefs, 'laptop')['state'], 'different')
        self.assertEqual(show_profile(self.prefs, 'desk')['different'], ['workspaces.browser'])
        self.assertNotIn('active', self.file.read_text())

    def test_saved_profiles_are_stable_after_unrelated_manual_edits(self):
        self.install_saved_fixture(save_plan(self.prefs, 'desk', ['workspaces.browser']))
        original = self.file.read_bytes()
        self.write_overrides({'apps.notes': 'org.example.Notes'})
        self.assertEqual(show_profile(self.prefs, 'desk')['state'], 'matches')
        self.assertEqual(self.file.read_bytes(), original)

    def test_replacing_requires_explicit_flag_and_keeps_other_profiles(self):
        self.install_saved_fixture(save_plan(self.prefs, 'desk', ['workspaces.browser']))
        self.install_saved_fixture(save_plan(self.prefs, 'presentation', ['apps.editor']))
        original = self.file.read_bytes()
        with self.assertRaisesRegex(PreferenceError, '--replace'):
            save_plan(self.prefs, 'desk', ['workspaces.terminal'])
        self.assertEqual(self.file.read_bytes(), original)
        result = save_plan(self.prefs, 'desk', ['workspaces.terminal'], replace=True)
        data = load(self.prefs, result.files[self.file])
        self.assertEqual(len(data['profiles']), 2)
        self.assertEqual(data['profiles'][0]['owns'], ['workspaces.terminal'])
        self.assertEqual(data['profiles'][1], load(self.prefs)['profiles'][1])

    def test_snapshot_captures_all_inputs_as_exact_bytes(self):
        self.config.mkdir()
        self.prefs.env.write_text('UNKNOWN="line one\nline two"\n')
        self.write_overrides({'workspaces.browser': '2'})
        current = capture_snapshot(self.prefs)
        template = self.repo/'aerospace/templates/aerospace.toml.template'
        self.assertEqual(set(current.before), {self.file, self.prefs.file, self.prefs.env, template})
        self.assertIsNone(current.before[self.file])
        self.assertEqual(current.before[self.prefs.env], self.prefs.env.read_bytes())
        self.assertEqual(current.before[template], template.read_bytes())
        # A caller can detect this edit from the returned guards before applying.
        self.write_overrides({'workspaces.browser': 'B'})
        captured = save_plan(self.prefs, 'desk', ['workspaces.browser'], snapshot=current)
        self.assertEqual(load(self.prefs, captured.files[self.file])['profiles'][0]['values'],
                         {'workspaces.browser': '2'})
        self.assertNotEqual(captured.before[self.prefs.file], self.prefs.file.read_bytes())

    def test_use_guards_profile_bytes_so_newer_saved_values_cannot_be_lost(self):
        self.install_saved_fixture(save_plan(self.prefs, 'desk', ['workspaces.browser']))
        proposed = use_plan(self.prefs, 'desk')
        self.install_saved_fixture(save_plan(self.prefs, 'desk', ['workspaces.terminal'], replace=True))
        self.assertNotEqual(proposed.before[self.file], self.file.read_bytes())

    def test_invalid_or_future_json_is_rejected_without_rewriting(self):
        candidates = [b'{', b'[]', b'{"version":2,"profiles":[]}',
                      b'{"version":true,"profiles":[]}', b'{"version":1,"profiles":{}}',
                      b'{"version":1,"profiles":[],"active":"desk"}',
                      b'{"version":1,"profiles":[],"profiles":[]}',
                      b'{"version":1,"profiles":[],"extra":NaN}', b'\xff']
        self.config.mkdir()
        for candidate in candidates:
            with self.subTest(candidate=candidate):
                self.file.write_bytes(candidate)
                with self.assertRaises(PreferenceError):
                    list_profiles(self.prefs)
                with self.assertRaises(PreferenceError):
                    save_plan(self.prefs, 'desk', ['workspaces.browser'])
                self.assertEqual(self.file.read_bytes(), candidate)
                self.assertFalse(self.prefs.file.exists())

    def test_duplicate_names_ownership_and_json_value_keys_fail(self):
        entries = [
            (self.record(), self.record()),
            (self.record(owns=['workspaces.browser', 'workspaces.browser']),),
            (self.record(reset=['workspaces.browser'], values={}), self.record(name='desk')),
            (self.record(values={}, reset=['workspaces.browser', 'workspaces.browser']),),
        ]
        for candidate in entries:
            with self.subTest(candidate=candidate), self.assertRaises(PreferenceError):
                load(self.prefs, self.serialized(*candidate))
        duplicate = ('{"version":1,"profiles":[{"name":"desk","owns":["workspaces.browser"],'
                     '"values":{"workspaces.browser":"B","workspaces.browser":"2"},"reset":[]}]}')
        with self.assertRaises(PreferenceError):
            load(self.prefs, duplicate)

    def test_ownership_must_exactly_partition_saved_values_and_resets(self):
        for entry in [self.record(owns=[]), self.record(owns=['apps.browser']),
                      self.record(values={}), self.record(reset=['workspaces.browser']),
                      self.record(reset=['apps.editor']), self.record(owns='workspaces.browser'),
                      self.record(values=[]), self.record(reset={}), self.record(extra=True)]:
            with self.subTest(entry=entry), self.assertRaises(PreferenceError):
                load(self.prefs, self.serialized(entry))
        with self.assertRaises(PreferenceError):
            save_plan(self.prefs, 'desk', ['workspaces.browser'], reset=['apps.editor'])

    def test_unknown_or_display_keys_and_invalid_catalog_values_fail(self):
        for key, value in [('display.builtin_serial', 'ABC'), ('display.external_serial', None),
                           ('display.brightness', 50), ('bogus.key', 'x'),
                           ('workspaces.browser', 'no-such-workspace'), ('apps.browser', ';open app'),
                           ('monitors.external', '['), ('projects.roots', ['relative']),
                           ('apps.editor', False)]:
            with self.subTest(key=key, value=value), self.assertRaises(PreferenceError):
                save_plan(self.prefs, 'desk', [key], values={key: value})
        self.assertEqual(set(allowed_keys()), {key for key in FIELDS if not key.startswith('display.')})
        self.assertFalse(self.config.exists())

    def test_profile_names_are_unambiguous_and_cannot_be_paths(self):
        for name in ['Desk', 'my desk', '../desk', '', 'a'*49, '1desk', 'desk\n', None]:
            with self.subTest(name=name), self.assertRaises(PreferenceError):
                save_plan(self.prefs, name, ['workspaces.browser'])
        self.install_saved_fixture(save_plan(self.prefs, 'travel-desk', ['workspaces.browser']))
        self.assertEqual(list_profiles(self.prefs)[-1]['label'], 'Travel Desk')
        with self.assertRaisesRegex(PreferenceError, 'Unknown profile'):
            show_profile(self.prefs, 'not-saved')

    def test_current_app_route_conflict_stops_before_any_writes(self):
        self.install_saved_fixture(save_plan(self.prefs, 'desk', ['apps.browser'],
                                             values={'apps.browser': 'org.example.Shared'}))
        self.write_overrides({'apps.notes': 'org.example.Shared'})
        original = self.file.read_bytes()
        with self.assertRaisesRegex(PreferenceError, 'two different workspaces'):
            use_plan(self.prefs, 'desk')
        self.assertEqual(self.file.read_bytes(), original)
        self.assertNotIn('apps.browser', self.prefs.overrides()['values'])

    def test_save_checks_proposed_cross_field_rules(self):
        with self.assertRaisesRegex(PreferenceError, 'two different workspaces'):
            save_plan(self.prefs, 'desk', ['apps.notes'], values={'apps.notes': 'com.google.Chrome'})
        self.assertFalse(self.config.exists())

    def test_unknown_shell_content_is_never_evaluated_and_remains_private(self):
        self.config.mkdir()
        marker = self.root/'executed'
        original = 'SECRET=$(touch "'+str(marker)+'")\nOTHER="kept\nmultiline"\n'
        self.prefs.env.write_text(original)
        proposed = save_plan(self.prefs, 'desk', ['workspaces.browser'])
        self.assertNotIn(b'SECRET', proposed.files[self.file])
        self.assertNotIn(b'multiline', proposed.files[self.file])
        self.assertFalse(marker.exists())
        self.assertEqual(self.prefs.env.read_text(), original)

    def test_symlink_inputs_are_rejected_without_mutating_targets(self):
        self.config.mkdir()
        target = self.root/'external-profile.json'
        target.write_text('{"version":1,"profiles":[]}')
        self.file.symlink_to(target)
        with self.assertRaisesRegex(PreferenceError, 'symlink'):
            load(self.prefs)
        with self.assertRaisesRegex(PreferenceError, 'symlink'):
            save_plan(self.prefs, 'desk', ['workspaces.browser'])
        self.assertEqual(target.read_text(), '{"version":1,"profiles":[]}')

    def test_output_values_do_not_alias_snapshot_or_input_records(self):
        self.install_saved_fixture(save_plan(self.prefs, 'desk', ['projects.roots'],
                                             values={'projects.roots': ['~/Work']}))
        current = capture_snapshot(self.prefs)
        first = show_profile(self.prefs, 'desk', snapshot=current)
        first['values']['projects.roots'].append('~/Mutation')
        proposed = use_plan(self.prefs, 'desk', snapshot=current)
        proposed.patch['projects.roots'].append('~/Another Mutation')
        self.assertEqual(show_profile(self.prefs, 'desk', snapshot=current)['values']['projects.roots'], ['~/Work'])

    def test_capture_is_idempotent_and_input_values_do_not_alias_output(self):
        values = {'projects.roots': ['~/Work']}
        proposed = save_plan(self.prefs, 'desk', ['projects.roots'], values=values)
        original = proposed.files[self.file]
        values['projects.roots'].append('~/Extra')
        self.assertEqual(proposed.files[self.file], original)
        self.install_saved_fixture(proposed)
        second = save_plan(self.prefs, 'desk', ['projects.roots'], values={'projects.roots': ['~/Work']}, replace=True)
        self.assertEqual(second.files[self.file], original)
