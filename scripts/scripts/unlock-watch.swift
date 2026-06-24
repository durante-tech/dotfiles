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
func fireHook(_ reason: String) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/bin/bash")
    p.arguments = [hook]
    do {
        try p.run()
        note("\(reason) -> ran \(hook)")
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
