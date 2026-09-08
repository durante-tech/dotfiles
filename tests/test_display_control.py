"""Managed display policy: temporary state, fake hardware, no live panel writes."""
from copy import deepcopy
from datetime import datetime, timezone, timedelta
import fcntl
import json
from pathlib import Path
import subprocess
import sys
from support import Fixture, REPO

sys.path.insert(0, str(REPO/'scripts/scripts/lib'))
from display_control.policy import (initial, reduce, validate, PolicyError, Store,
                                    ambient_mode, read_profiles, XDR, SRGB)
from display_control.hardware import Hardware, ControlError, parse_devices, resolve
from display_control.cli import Controller, locked

DEVICES = [
    {'deviceType':'Display','tagID':2,'registryLocation':'IOService:/disp0@123/AppleCLCD','serial':'111','name':'Built-in'},
    {'deviceType':'Display','tagID':60,'registryLocation':'IOService:/dispext0@456/AppleCLCD2','serial':'222','name':'External'},
]


class FakeHardware(Hardware):
    def __init__(self):
        self.calls=[];self.fault=None;self.devices=deepcopy(DEVICES)
        self.values={('2','xdrPreset'):XDR,('2','autoBrightness'):'on',('2','hardwareBrightness'):'1.0',('2','softwareBrightness'):'0.6',
                     ('60','temperature'):'0.0',('60','hdr'):'off',('60','hardwareBrightness'):'1.0'}
        super().__init__('fake-betterdisplay', runner=self.run, sleep=lambda _:None)

    def run(self, argv, **kwargs):
        args=argv[1:];self.calls.append(args)
        params=dict(a[2:].split('=',1) if '=' in a else (a[2:],'') for a in args[1:])
        if self.fault and self.fault(args,params):
            return subprocess.CompletedProcess(argv,124,'','connection interrupted')
        if '--identifiers' in args:
            return subprocess.CompletedProcess(argv,0,json.dumps(self.devices),'')
        if args[0]=='perform': return subprocess.CompletedProcess(argv,0,'','')
        tag=params.get('tagID')
        if '--ddc' in args:
            self.values[(tag, params['vcp'])]=params['value']
            return subprocess.CompletedProcess(argv,0,'','')
        key=next((key for key in params if key!='tagID'), '')
        if args[0]=='get':
            return subprocess.CompletedProcess(argv,0,self.values.get((tag,key),'Failed.'),'')
        value=params[key]
        self.values[(tag,key)] = str(float(value[:-1])/100) if value.endswith('%') else value
        return subprocess.CompletedProcess(argv,0,'','')


class DisplayControl(Fixture):
    def setUp(self):
        super().setUp()
        self.store=Store(self.root)
        self.store.legacy.write_text('night|old|wake|x|Night')
        self.hardware=FakeHardware()
        self.controller=Controller(self.store,self.hardware,bucket_path=self.root/'bucket')

    def dispatch(self,action,args=None):
        with locked(self.root,0):
            return self.controller.dispatch(action,args or [],'manual')

    def test_migration_holds_legacy_and_backs_it_up_without_hardware(self):
        state=self.dispatch('migrate')
        self.assertEqual(state['owner'],'manual');self.assertEqual(state['base']['dev'],60)
        self.assertEqual(state['outcome']['status'],'unverified')
        self.assertEqual((self.root/'bd-state.before-intent-v1').read_text(),'night|old|wake|x|Night')
        self.assertEqual(self.hardware.calls,[])
        self.assertEqual(self.dispatch('migrate'),state)

    def test_manual_selection_survives_ambient_and_wake(self):
        manual=self.dispatch('preset',['read']);before=len(self.hardware.calls)
        ignored=self.dispatch('ambient',['night'])
        self.assertEqual(ignored,manual);self.assertEqual(len(self.hardware.calls),before)
        state=self.dispatch('reapply')
        self.assertEqual(state['base'],manual['base']);self.assertEqual(state['owner'],'manual')
        self.assertEqual(state['outcome']['status'],'dispatched')
        self.assertEqual(self.hardware.values[('2','autoBrightness')],'off')

    def test_adjustments_hold_actual_values_and_clamp(self):
        self.dispatch('set',['port','42'])
        self.dispatch('backlight',['30'])
        self.dispatch('up',['dev'])
        state=self.dispatch('reapply')
        self.assertEqual(state['base']['port'],42)
        self.assertEqual(state['base']['hardware'],40)
        self.assertEqual(state['base']['dev'],100)
        self.assertEqual(self.hardware.values[('2','hardwareBrightness')],'0.4')
        self.dispatch('set',['port','98']);self.assertEqual(self.dispatch('up',['port'])['base']['port'],100)
        self.dispatch('set',['port','2']);self.assertEqual(self.dispatch('down',['port'])['base']['port'],0)

    def test_srgb_choice_survives_recovery(self):
        state=self.dispatch('srgb')
        self.assertEqual(state['base']['xdr'],SRGB)
        self.dispatch('ambient',['day']);self.dispatch('reapply')
        self.assertEqual(self.hardware.values[('2','xdrPreset')],SRGB)
        with self.assertRaises(PolicyError):self.dispatch('set',['dev','150'])

    def test_auto_waits_for_fresh_sensor_then_uses_ambient(self):
        state=self.dispatch('auto')
        self.assertEqual(state['owner'],'auto');self.assertEqual(state['outcome']['status'],'awaiting-sensor')
        self.assertEqual(self.hardware.calls,[])
        state=self.dispatch('ambient',['evening'])
        self.assertEqual(state['base']['preset'],'evening')
        calls=len(self.hardware.calls)
        self.dispatch('ambient',['evening']);self.assertEqual(len(self.hardware.calls),calls)

    def test_auto_uses_current_bucket_on_explicit_request(self):
        (self.root/'bucket').write_text('2|300|'+datetime.now(timezone.utc).isoformat())
        self.assertEqual(self.dispatch('auto')['base']['preset'],'afternoon')
        (self.root/'bucket').write_text('2|300|'+(datetime.now(timezone.utc)-timedelta(hours=1)).isoformat())
        self.assertIsNone(ambient_mode(self.root/'bucket'))

    def test_pending_ambient_failure_retries_same_bucket(self):
        self.dispatch('auto')
        self.hardware.fault=lambda a,p:a[0]=='set' and p.get('vcp')=='luminance'
        state=self.dispatch('ambient',['day']);self.assertEqual(state['outcome']['status'],'failed')
        self.hardware.fault=None
        state=self.dispatch('ambient',['day']);self.assertEqual(state['outcome']['status'],'dispatched')
        self.assertEqual(state['base']['preset'],'day')

    def test_builtin_failure_is_not_masked_by_external_success(self):
        self.hardware.fault=lambda a,p:p.get('tagID')=='2' and 'softwareBrightness' in p
        state=self.dispatch('preset',['day'])
        self.assertEqual(state['outcome']['dev'],'failed')
        self.assertEqual(state['outcome']['port'],'dispatched')
        self.assertEqual(state['outcome']['status'],'failed')

    def test_nonzero_vcp_errors_are_never_dispatched(self):
        self.hardware.fault=lambda a,p:'--ddc' in a
        with self.assertRaises(ControlError):self.hardware.vcp('60','luminance',35)
        self.assertEqual(len([a for a in self.hardware.calls if '--ddc' in a]),3)

    def test_hdr_roundtrip_preserves_base_and_suppresses_ambient(self):
        self.dispatch('backlight',['25']);base=self.dispatch('set',['port','38'])['base']
        state=self.dispatch('hdr',['on']);self.assertTrue(state['hdr']['enabled'])
        self.assertEqual(float(self.hardware.values[('60','luminance')]),100)
        self.dispatch('ambient',['day']);self.dispatch('reapply')
        self.assertEqual(float(self.hardware.values[('60','luminance')]),100)
        state=self.dispatch('hdr',['off']);self.assertEqual(state['base'],base)
        self.assertEqual(float(self.hardware.values[('60','luminance')]),38)
        self.assertEqual(state['owner'],'manual')

    def test_hdr_brightness_failure_is_visible(self):
        self.hardware.values[('60','hdr')]='on'
        self.hardware.fault=lambda a,p:p.get('vcp')=='luminance'
        self.assertEqual(self.dispatch('hdr',['on'])['outcome']['status'],'failed')

    def test_failed_hdr_does_not_raise_sdr_backlight(self):
        self.hardware.fault=lambda a,p:'hdr' in p
        result=self.dispatch('hdr',['on'])
        self.assertEqual(result['outcome']['status'],'failed')
        self.assertFalse(any('--ddc' in args for args in self.hardware.calls))

    def test_pending_manual_retry_keeps_manual_values(self):
        self.hardware.fault=lambda a,p:p.get('vcp')=='luminance'
        result=self.dispatch('set',['port','42'])
        self.assertEqual(result['outcome']['status'],'failed')
        self.hardware.fault=None
        result=self.dispatch('ambient',['day'])
        self.assertEqual(result['outcome']['status'],'dispatched')
        self.assertEqual(result['base']['port'],42)
        self.assertEqual(result['owner'],'manual')

    def test_newer_manual_choice_wins_over_delayed_recovery(self):
        self.dispatch('preset',['night'])
        # A scheduled wake carries an action, never a captured preset name.
        self.dispatch('preset',['meeting'])
        self.assertEqual(self.dispatch('reapply')['base']['preset'],'meeting')

    def test_stream_returns_to_prior_values_and_owner(self):
        self.dispatch('auto');previous=self.dispatch('ambient',['afternoon'])
        self.dispatch('preset',['stream'])
        restored=self.dispatch('stream-stop')
        self.assertEqual(restored['base'],previous['base']);self.assertEqual(restored['owner'],'auto')
        self.dispatch('preset',['stream']);self.dispatch('preset',['read'])
        with self.assertRaises(PolicyError):self.dispatch('stream-stop')

    def test_identity_uses_serial_after_redock_and_refuses_ambiguity(self):
        state=self.dispatch('preset',['night']);self.assertEqual(state['identity']['port'],'222')
        self.hardware.devices[1]['tagID']=166
        self.hardware.values[('166','temperature')]='0.0'
        self.assertEqual(self.dispatch('reapply')['outcome']['status'],'dispatched')
        self.assertIn('166',[dict(x[2:].split('=',1) for x in a[1:] if '=' in x).get('tagID') for a in self.hardware.calls])
        self.hardware.devices.append({**DEVICES[1],'tagID':90,'serial':'333'})
        self.assertEqual(self.dispatch('reapply')['outcome']['status'],'dispatched')
        with self.assertRaises(PolicyError):resolve(parse_devices(json.dumps(self.hardware.devices)),{})
        with self.assertRaises(PolicyError):resolve(parse_devices(json.dumps(self.hardware.devices)),{'port':'missing'})

    def test_identity_unknown_role_invalid_response_and_duplicate_serial(self):
        for data in ['Failed.','{}','{"deviceType":"Display","tagID":12}']:
            with self.assertRaises(ValueError):parse_devices(data)
        devices=deepcopy(DEVICES);devices.append({**DEVICES[1],'tagID':90})
        with self.assertRaises(PolicyError):resolve(parse_devices(json.dumps(devices)),{'port':'222'})
        self.assertEqual(len(parse_devices('\n,\n'.join(json.dumps(d) for d in DEVICES))),2)

    def test_calibrated_presets_are_saved_outside_source_and_used_in_auto(self):
        self.dispatch('backlight',['25']);self.dispatch('set',['port','28'])
        self.dispatch('save-preset',['night'])
        profiles=read_profiles(self.controller.profiles_path)
        self.assertEqual(profiles['night']['hardware'],25)
        self.dispatch('preset',['day']);self.dispatch('auto')
        state=self.dispatch('ambient',['night'])
        self.assertEqual(state['base']['hardware'],25);self.assertEqual(state['base']['port'],28)
        self.dispatch('set',['port','26']);self.dispatch('save-preset',['night'])
        self.assertTrue(self.controller.profiles_path.with_name('display-profiles.json.previous').exists())

    def test_malformed_intent_is_never_overwritten(self):
        self.store.path.write_text('{"version":99}')
        with self.assertRaises(PolicyError):self.dispatch('preset',['day'])
        self.assertEqual(self.store.path.read_text(),'{"version":99}')
        self.assertEqual(self.hardware.calls,[])
        for value in [-1,161,'oops',True]:
            state=initial('');state['base']['dev']=value
            with self.assertRaises(PolicyError):validate(state)

    def test_lock_contention_changes_neither_state_nor_hardware(self):
        self.dispatch('migrate');before=self.store.path.read_bytes()
        with locked(self.root,0):
            result=self.run_command(['python3',str(REPO/'scripts/scripts/lib/display-control.py'),'day'],
                                    {'DOTFILES_DISPLAY_PROFILES_FILE':str(self.root/'profiles.json'),'DOTFILES_DISPLAY_STATE_DIR':str(self.root),'DOTFILES_DISPLAY_LOCK_TIMEOUT':'0'})
        self.assertEqual(result.returncode,75,result.stderr)
        self.assertEqual(self.store.path.read_bytes(),before);self.assertEqual(self.hardware.calls,[])

    def test_cli_status_has_no_lock_or_hardware_side_effects(self):
        directory=self.root/'empty';directory.mkdir()
        result=self.run_command(['python3',str(REPO/'scripts/scripts/lib/display-control.py'),'status','--json'],
                                {'DOTFILES_DISPLAY_STATE_DIR':str(directory)})
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(json.loads(result.stdout)['owner'],'manual');self.assertEqual(list(directory.iterdir()),[])

    def test_legacy_watcher_entry_cannot_replace_manual_intent(self):
        self.dispatch('preset',['read'])
        self.stub('betterdisplaycli', 'raise RuntimeError("unexpected hardware call")')
        result=self.run_command(['python3',str(REPO/'scripts/scripts/lib/display-control.py'),'night'],
                                {'DOTFILES_DISPLAY_PROFILES_FILE':str(self.root/'profiles.json'),'DOTFILES_DISPLAY_STATE_DIR':str(self.root),'BD_SOURCE':'lmu'})
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(self.store.load()['base']['preset'],'read')
        self.assertNotIn('unexpected',result.stderr)

    def test_native_auto_is_disabled_without_brightness_changes_on_hold(self):
        self.dispatch('migrate')
        before=dict(self.hardware.values)
        self.dispatch('manual')
        self.assertEqual(self.hardware.values[('2','autoBrightness')],'off')
        for key,value in before.items():
            if key!=('2','autoBrightness'): self.assertEqual(self.hardware.values[key],value)

    def test_favorite_slot_writes_are_inside_the_shared_executor(self):
        result=self.dispatch('favorite',['read','4'])
        self.assertEqual(result['outcome']['status'],'dispatched')
        self.assertEqual(self.hardware.values[('2','saveFavoriteMode')],'4')
        self.assertEqual(self.hardware.values[('60','saveFavoriteMode')],'4')

    def test_cli_argument_errors_do_not_touch_hardware(self):
        self.stub('betterdisplaycli', 'raise RuntimeError("unexpected hardware call")')
        for args in [['set','port','101'],['set','dev','NaN'],['hdr','oops'],['cycle','bad']]:
            result=self.run_command(['python3',str(REPO/'scripts/scripts/lib/display-control.py'),*args],
                                    {'DOTFILES_DISPLAY_PROFILES_FILE':str(self.root/'profiles.json'),'DOTFILES_DISPLAY_STATE_DIR':str(self.root)})
            self.assertEqual(result.returncode,2,result.stderr)
            self.assertNotIn('unexpected',result.stderr)
