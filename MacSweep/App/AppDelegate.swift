import AppKit
import OSLog

/// Handles NSApplication lifecycle events for MacSweep.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.app.info("MacSweep launched successfully")
    }

    func applicationWillTerminate(_ notification: Notification) {
        Logger.app.info("MacSweep terminating")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
