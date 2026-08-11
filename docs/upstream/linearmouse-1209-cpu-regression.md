# Upstream bug report draft — LinearMouse

Ready to post at https://github.com/linearmouse/linearmouse/issues/new
Drafted 2026-08-11. Nothing here is inferred; every number is from a run on this machine.

---

**Title:** `Regression: #1209's parent-root FSEvents watch pegs a core on busy home directories (0.11.3+)`

---

### OS

macOS 26 (Darwin 25.6.0), Apple Silicon

### LinearMouse

0.11.4 (also reproduced on 0.12.0-beta.4)

### Describe the bug

Since 0.11.3, LinearMouse sustains **92–99% CPU** whenever the filesystem is busy. It is idle
(~1%) when the disk is quiet, so it presents as intermittent, but on a machine with an active
home directory it is effectively permanent.

The mouse is not involved. During a spike, `com.linearmouse.event-thread` is **idle** — 3314 of
3315 samples parked in `mach_msg_trap`. All the CPU is on the main thread inside the FSEvents
callback.

I believe this is a regression introduced by #1209 ("Fix config hot reload after directory
recreation"), which states:

> Replace the configuration-specific DispatchSource watchers with a generic FSEvents-backed
> FileWatcher.
> Watch stable parent roots so deleting and recreating the configuration directory still
> triggers reloads.

`lsof -p <pid>` confirms the watched set on 0.11.4:

```
/
/Users
/Users/<me>
/Users/<me>/.config
/Users/<me>/Library
```

On 0.11.2 the watched set is only:

```
/
/Users/<me>/.config/linearmouse
```

Because `$HOME` and `/Users` are watched, FSEvents delivers events for **all** filesystem
activity in the home directory, and the callback appears to do a full path resolution per event.

### Profile

`sample <pid> 5` captured during a spike. Hottest frames:

```
123  _FileManagerImpl.destinationOfSymbolicLink(atPath:)   (Foundation)
 59  _SwiftURL.init(filePath:pathStyle:directoryHint:relativeTo:)
 47  _SwiftURL.absoluteString(original:)
 45  _SwiftURL._makeCFURL(from:baseURL:)
 34  _SwiftURL.deletingLastPathComponent()
 26  _SwiftURL.path.getter
 20  RFC3986Parser.parse(filePath:isAbsolute:)
```

Call chain — 65% of all samples:

```
_dispatch_client_callout
  → receive_and_dispatch_rcv_msg        (FSEvents)
    → FSEventsD2F_server
      → _Xcallback_rpc
        → implementation_callback_rpc
          → <LinearMouse>
            → destinationOfSymbolicLink → readlink
            → _SwiftURL init / absoluteString / RFC3986 percent-encoding
```

So each delivered event costs a `readlink` plus a fresh `URL` construction and RFC3986 reparse.

### To reproduce

1. Install 0.11.3 or later.
2. Generate filesystem activity in `$HOME`:
   ```sh
   T=~/.lm-bench; mkdir -p $T
   for i in $(seq 1 3000); do echo x > $T/f$i; rm -f $T/f$i; done; rm -rf $T
   ```
3. Watch `ps -Ao pcpu,comm | grep LinearMouse`.

Note FSEvents **coalesces**: CPU stays ~1% *during* the loop and spikes *after* it finishes, as
the batch is delivered. Sampling only during the load will show nothing.

### Measurements

Identical load (above), same machine, same config file, app restarted before each run:

| build | watches `$HOME`? | peak CPU | time to drain below 10% |
|---|---|---|---|
| v0.11.2 | no | **1%** | n/a (never rose) |
| v0.11.4 | yes | 92% | 45s |
| v0.12.0-beta.4 | yes | 99% | 115s |

v0.12.0-beta.4 is *worse* than 0.11.4 at draining.

### Expected behavior

Config hot-reload should not require watching `$HOME` and `/Users`. Some options, in rough order
of preference:

1. Watch only the config directory, and re-arm the watch on delete by watching the **immediate**
   parent (`~/.config`) rather than every ancestor up to `/`.
2. Filter delivered events by path prefix **before** doing any `URL`/symlink resolution — the
   current cost is paid per event regardless of relevance.
3. Cache the resolved config path instead of re-running `destinationOfSymbolicLink` +
   `RFC3986Parser` on every event.
4. Use `kFSEventStreamCreateFlagFileEvents` scoped to the config directory, or fall back to the
   pre-#1209 DispatchSource watcher plus a coarse re-arm timer.

### Anything else?

The workaround is to pin v0.11.2 — the last release before #1209, and still after the earlier
CPU fixes in #1168 / #1185.

Worth noting: #1205, the issue #1209 was fixing, was reported by someone keeping their
LinearMouse config on a dotfiles branch. That is my setup too, so I would like the hot-reload fix
to survive — just without the `$HOME`-wide watch.

Happy to run further profiles or test a patch build.
