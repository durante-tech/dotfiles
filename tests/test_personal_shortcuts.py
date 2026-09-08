"""Personal shortcut exports inspect fake inputs; they never invoke app actions."""
from copy import deepcopy
import json
from pathlib import Path
import shutil
import sys
from unittest.mock import patch
from support import Fixture, REPO

sys.path.insert(0, str(REPO/'scripts/scripts/lib'))
from dotfiles_preferences.envfile import PreferenceError
from dotfiles_preferences.model import Preferences
from dotfiles_preferences.shortcuts import guide, records, AEROSPACE, KARABINER


class PersonalShortcuts(Fixture):
    def setUp(self):
        super().setUp()
        self.repo = self.root/'checkout with spaces'
        for relative in (AEROSPACE, KARABINER):
            target = self.repo/relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO/relative, target)
        self.config = self.root/'private'
        self.prefs = Preferences(self.repo, self.config, self.root/'home')

    def preferences(self, **values):
        self.config.mkdir(exist_ok=True)
        self.prefs.file.write_text(json.dumps({'version': 1, 'values': values}))

    def karabiner(self, change):
        path = self.repo/KARABINER
        source = json.loads(path.read_text())
        change(source)
        path.write_text(json.dumps(source))

    def row(self, document, suffix):
        return next(row for row in document['records'] if row['source'].endswith(suffix))

    def test_reads_actual_bindings_and_unique_mode_entry_sequences(self):
        doc = records(self.prefs)
        self.assertEqual(doc['kind'], 'dotfiles-shortcut-reference')
        self.assertTrue(doc['reference_only'])
        self.assertEqual(self.row(doc, '.main.binding.alt-t')['destination'], {'workspace': 'T'})
        self.assertEqual(self.row(doc, '.resize.binding.h')['sequence'], ['Alt+Shift+r', 'h'])
        self.assertEqual(self.row(doc, '.resize.binding.shift-h')['sequence'], ['Alt+Shift+r', 'Shift+h'])
        self.assertEqual(self.row(doc, '.bd-mode.binding.u')['sequence'], ['Alt+Shift+x', 'u'])
        self.assertTrue(all(row['reference_only'] for row in doc['records']))

    def test_personal_roles_match_aerospace_and_karabiner_without_stale_descriptions(self):
        self.preferences(**{'workspaces.browser': '2', 'workspaces.notes': '1', 'apps.browser': 'org.example.Browser'})
        doc = records(self.prefs)
        self.assertEqual(self.row(doc, '.main.binding.alt-b')['destination']['workspace'], '2')
        launch = next(r for r in doc['records'] if r['destination'] and r['destination'].get('app') == 'org.example.Browser')
        self.assertEqual(launch['sequence'], ['Hold(CapsLock)', 'Hold(o)', 'c'])
        self.assertEqual(launch['destination']['workspace'], '2')
        notes = next(r for r in doc['records'] if r['destination'] and r['destination'].get('role') == 'notes' and 'app' not in r['destination'])
        self.assertEqual(notes['sequence'], ['Hold(CapsLock)', 'n'])
        self.assertEqual(notes['destination']['workspace'], '1')
        forwarded = next(r for r in doc['records'] if r['sequence'] == ['Hold(CapsLock)', 'b'])
        self.assertEqual(forwarded['destination'], {'workspace': '2', 'requires_aerospace_mode': 'main'})

    def test_output_is_deterministic_and_checkout_location_is_not_identity(self):
        first = records(self.prefs)
        self.assertEqual(first, records(self.prefs))
        other = self.root/"other O'Brien checkout"
        shutil.copytree(self.repo, other)
        self.assertEqual(first, records(Preferences(other, self.config, self.prefs.home)))
        self.assertEqual(guide(self.prefs), guide(self.prefs))

    def test_source_drift_changes_fingerprint_and_behavior_changes_id(self):
        before = records(self.prefs)
        path = self.repo/AEROSPACE
        path.write_text(path.read_text().replace("alt-h = 'focus --boundaries-action wrap-around-the-workspace left'", "alt-h = 'focus right'"))
        after = records(self.prefs)
        self.assertNotEqual(before['fingerprint'], after['fingerprint'])
        self.assertNotEqual(self.row(before, '.main.binding.alt-h')['id'], self.row(after, '.main.binding.alt-h')['id'])
        self.assertEqual(self.row(before, '.main.binding.alt-j')['id'], self.row(after, '.main.binding.alt-j')['id'])

    def test_changed_personal_destination_does_not_reuse_shortcut_identity(self):
        before = records(self.prefs)
        self.preferences(**{'workspaces.browser': '2'})
        after = records(self.prefs)
        self.assertNotEqual(self.row(before, '.main.binding.alt-b')['id'], self.row(after, '.main.binding.alt-b')['id'])
        for doc in (before, after):
            self.assertFalse(any(key in json.dumps(doc) for key in ('repetitions', 'easeFactor', 'localStorage')))

    def test_case_side_modifiers_and_tap_vs_hold_preserved(self):
        doc = records(self.prefs)
        tap = next(r for r in doc['records'] if r['sequence'] == ['Tap(CapsLock)'])
        self.assertEqual(tap['action'], [{'key_code': 'escape'}])
        simple = next(r for r in doc['records'] if '.simple.' in r['source'])
        self.assertEqual(simple['steps'][0]['key'], 'right_command')
        self.assertEqual(simple['action'], [{'key_code': 'right_option'}])
        self.karabiner(lambda x: x['profiles'][0]['simple_modifications'].append({'from': {'key_code': 'Q', 'modifiers': {'mandatory': ['right_command', 'left_shift']}}, 'to': [{'key_code': 'q'}]}))
        self.assertTrue(any(r['sequence'] == ['RightCmd+LeftShift+Q'] for r in records(self.prefs)['records']))

    def test_disabled_rules_omitted_and_profile_selection_is_explicit(self):
        doc = records(self.prefs)
        self.assertTrue(any(d['status'] == 'disabled' for d in doc['diagnostics']))
        self.assertFalse(any(r['action'] == [{'key_code': 'f12'}] for r in doc['records']))
        self.karabiner(lambda x: x['profiles'].append(deepcopy(x['profiles'][0])))
        with self.assertRaises(PreferenceError):
            records(self.prefs)
        self.karabiner(lambda x: x['profiles'][0].update(selected=True))
        self.assertTrue(records(self.prefs)['records'])

    def test_unrecognized_conditions_and_duplicate_inputs_are_visible(self):
        def mutate(x):
            rule = x['profiles'][0]['complex_modifications']['rules'][1]
            rule['manipulators'].append(deepcopy(rule['manipulators'][0]))
            rule['manipulators'].append({'type': 'basic', 'from': {'key_code': 'x'}, 'conditions': [{'type': 'frontmost_application_if', 'bundle_identifiers': ['org.example']}], 'to': [{'key_code': 'y'}]})
        self.karabiner(mutate)
        doc = records(self.prefs)
        self.assertEqual(sum(r['status'] == 'ambiguous' for r in doc['records']), 2)
        unsupported = next(r for r in doc['records'] if r['status'] == 'unsupported')
        self.assertEqual(unsupported['sequence'], [])
        self.assertIn('frontmost_application_if', json.dumps(unsupported['conditions']))

    def test_ambiguous_hold_definition_does_not_invent_sequence(self):
        def mutate(x):
            rule = x['profiles'][0]['complex_modifications']['rules'][2]
            rule['manipulators'].append(deepcopy(rule['manipulators'][0]))
        self.karabiner(mutate)
        rows = records(self.prefs)['records']
        self.assertTrue(any(r['status'] == 'unsupported' and 'ambiguous' in r['note'] for r in rows))
        self.assertFalse(any(r['sequence'] == ['Hold(CapsLock)', 'b'] for r in rows))

    def test_layer_activation_guards_are_retained_in_child_identity(self):
        before = next(r for r in records(self.prefs)['records'] if r['sequence'] == ['Hold(CapsLock)', 'Hold(o)', 'c'])
        def mutate(x):
            rule = x['profiles'][0]['complex_modifications']['rules'][3]
            rule['manipulators'][0]['conditions'].append({'name': 'extra_layer', 'type': 'variable_if', 'value': 0})
        self.karabiner(mutate)
        after = next(r for r in records(self.prefs)['records'] if r['sequence'] == ['Hold(CapsLock)', 'Hold(o)', 'c'])
        self.assertNotEqual(before['id'], after['id'])
        self.assertIn('extra_layer', json.dumps(after['activation_conditions']))

    def test_unsupported_holder_timing_also_marks_its_children_unsupported(self):
        def mutate(x):
            rule = x['profiles'][0]['complex_modifications']['rules'][2]
            rule['manipulators'][0]['to_delayed_action'] = {'to_if_invoked': [{'key_code': 'x'}]}
        self.karabiner(mutate)
        rows = records(self.prefs)['records']
        self.assertTrue(any(r['status'] == 'unsupported' and 'Timing' in r['note'] for r in rows))
        self.assertFalse(any(r['sequence'] == ['Hold(CapsLock)', 'b'] for r in rows))

    def test_multiple_mode_entries_require_context_instead_of_guessing(self):
        path = self.repo/AEROSPACE
        path.write_text(path.read_text().replace("alt-shift-r = 'mode resize'", "alt-shift-r = 'mode resize'\nalt-shift-q = 'mode resize'"))
        doc = records(self.prefs)
        row = self.row(doc, '.resize.binding.h')
        self.assertEqual(row['status'], 'context-required')
        self.assertEqual(row['sequence'], ['h'])
        self.assertTrue(any('resize' in d['message'] for d in doc['diagnostics']))

    def test_read_only_guide_never_executes_shell_actions_or_creates_state(self):
        marker = self.root/'executed'
        self.karabiner(lambda x: x['profiles'][0]['simple_modifications'].append({'from': {'key_code': 'f5'}, 'to': [{'shell_command': 'touch ' + str(marker)}]}))
        with patch('dotfiles_preferences.apps.launch', side_effect=AssertionError('must not launch')):
            output = guide(self.prefs)
        self.assertIn('touch ', output)
        self.assertFalse(marker.exists())
        self.assertFalse(self.config.exists())
        self.assertFalse((self.repo/'aerospace/.config').exists())
        self.assertIn('read-only reference', output)

    def test_unknown_environment_values_are_not_exported(self):
        self.config.mkdir()
        self.prefs.env.write_text("PRIVATE_TOKEN='never-export-me'\n")
        self.assertNotIn('never-export-me', guide(self.prefs))
        self.assertNotIn('never-export-me', json.dumps(records(self.prefs)))
