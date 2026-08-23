// unlock-watch — run ~/.wakeup when the Mac screen is unlocked.
//
// Why this exists: sleepwatcher's -W (display-wakeup) hook is unreliable on
// Apple Silicon / macOS 26. It registers, but its IOKit display-wrangler
// notifications frequently never fire, so the post-wake display re-assert in
// bd-wake.sh never runs and the external monitor stays dark after a lock/unlock.
//
// `com.apple.screenIsUnlocked` is the documented, reliable unlock signal,
// delivered to GUI-session agents through the distributed notification center.
// launchd has no native trigger for distributed notifications, so this tiny
// KeepAlive helper observes it and runs the same ~/.wakeup hook sleepwatcher
// would have — recovering the external monitor on every unlock.
//
// Complements sleepwatcher (which still owns real system wake via -w); it does
// not replace it. Built to ~/.local/bin/unlock-watch by setup.sh; run by
// com.lucas.unlock-watch.plist. stderr -> /tmp/unlock-watch.log.

import Foundation

let home = FileManager.default.homeDirectoryForCurrentUser.path
let hook = "\(home)/.wakeup"

func stamp() -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return f.string(from: Date())
}

func note(_ msg: String) {
    FileHandle.standardError.write(Data("[\(stamp())] \(msg)\n".utf8))
}

// Best-effort: a failed hook must never crash the listener (KeepAlive would
// just respawn it, but we want to keep observing across transient failures).
//
// `try p.run()` throws only when /bin/bash itself cannot be spawned, which never
// happens — so the success line used to be printed the instant the child forked,
// and the log said "-> ran ~/.wakeup" even when the hook was missing and bash
// exited 127. That made this log lie in the one situation it is ever read in:
// the external monitor did not come back after an unlock. Check the hook up
// front, then report the child's REAL exit status.
//
// The status is reported from terminationHandler rather than waitUntilExit()
// because this runs on the main queue that delivers the unlock notifications —
// blocking it for the length of bd-wake.sh (seconds of displayplacer + DDC work)
// would stall every notification behind it.
func fireHook(_ reason: String) {
    // /bin/bash READS the hook as a script, so readable is the correct test —
    // ~/.wakeup is a symlink to bd-wake.sh and needs no exec bit of its own.
    guard FileManager.default.isReadableFile(atPath: hook) else {
        note("\(reason) -> SKIPPED, hook missing or unreadable: \(hook)")
        return
    }
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/bin/bash")
    p.arguments = [hook]
    p.terminationHandler = { proc in
        if proc.terminationStatus == 0 {
            note("\(reason) -> ran \(hook)")
        } else {
            note("\(reason) -> \(hook) exited \(proc.terminationStatus)")
        }
    }
    do {
        try p.run()
    } catch {
        note("\(reason) -> FAILED to run \(hook): \(error)")
    }
}

let dnc = DistributedNotificationCenter.default()
dnc.addObserver(forName: Notification.Name("com.apple.screenIsUnlocked"),
                object: nil, queue: .main) { _ in
    fireHook("screenIsUnlocked")
}

note("unlock-watch started — observing com.apple.screenIsUnlocked; hook=\(hook)")
RunLoop.main.run()
