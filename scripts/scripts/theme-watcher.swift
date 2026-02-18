import Foundation

let center = DistributedNotificationCenter.default()
center.addObserver(
    forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
    object: nil,
    queue: .main
) { _ in
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.arguments = ["-c", "\(NSHomeDirectory())/scripts/theme-switch auto"]
    try? task.run()
}

RunLoop.main.run()
