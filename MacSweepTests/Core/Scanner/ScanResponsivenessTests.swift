import Foundation
import Dispatch

/// Standalone regression checks; run with scripts/test-scan-performance.sh.
@main
struct ScanResponsivenessTests {
    @MainActor
    static func main() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("MacSweepTests-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        // Include hidden files and package descendants in allocated-size totals.
        let package = root.appendingPathComponent("Fixture.app/Contents")
        try FileManager.default.createDirectory(at: package, withIntermediateDirectories: true)
        let files = [root.appendingPathComponent("visible"), root.appendingPathComponent(".hidden"), package.appendingPathComponent("data")]
        var expected: Int64 = 0
        for url in files {
            try Data(repeating: 42, count: 8192).write(to: url)
            let values = try url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey])
            expected += Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
        }
        let size = await FileEnumerator.directorySize(root)
        precondition(size == expected, "Allocated-size totals must include hidden files and packages")

        var enumeratedFiles: Set<String> = []
        for await metadata in FileEnumerator.enumerate(directory: root, includeHidden: true, skipPackageDescendants: false) {
            if !metadata.isDirectory { enumeratedFiles.insert(metadata.url.resolvingSymlinksInPath().path) }
        }
        precondition(enumeratedFiles == Set(files.map { $0.resolvingSymlinksInPath().path }), "Pull-based enumeration must not drop entries")
        let stoppedControl = ScanControl()
        stoppedControl.cancel()
        var stoppedIterator = FileEnumerator.enumerate(directory: root, control: stoppedControl).makeAsyncIterator()
        let stoppedEntry = await stoppedIterator.next()
        precondition(stoppedEntry == nil, "Cancelled enumeration must stop before reading entries")

        // A paused worker must suspend without blocking UI tasks; cancellation must release it.
        let control = ScanControl()
        control.pause()
        let pausedScan = Task { await FileEnumerator.directorySize(root, control: control) }
        try await Task.sleep(for: .milliseconds(100))
        control.cancel()
        let cancelledSize = await pausedScan.value
        precondition(cancelledSize == 0, "Cancelled paused scans must not enumerate files")

        let taskControl = ScanControl()
        taskControl.pause()
        let taskCancelledScan = Task { await FileEnumerator.directorySize(root, control: taskControl) }
        try await Task.sleep(for: .milliseconds(100))
        taskCancelledScan.cancel()
        let taskCancelledSize = await taskCancelledScan.value
        precondition(taskCancelledSize == 0, "Task cancellation must release paused workers")

        let engine = CleanEngine(safetyValidator: SafetyValidator())
        let items = files.map { CleanupItem(url: $0, size: 8192, category: .systemCache, isDirectory: false, modificationDate: .distantPast) }
        let result = await engine.clean(items: items) { _ in
            // The caller is MainActor: cleanup must explicitly switch executors.
            dispatchPrecondition(condition: .notOnQueue(.main))
        }
        precondition(result.successCount == files.count && result.failureCount == 0)
        precondition(files.allSatisfy { !FileManager.default.fileExists(atPath: $0.path) })

        let retained = root.appendingPathComponent("cancelled-cleanup")
        try Data([1]).write(to: retained)
        let cancelledItem = CleanupItem(url: retained, size: 1, category: .systemCache, isDirectory: false, modificationDate: .distantPast)
        let cancelledCleanup = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return await engine.clean(items: [cancelledItem])
        }
        let cancelledResult = await cancelledCleanup.value
        precondition(cancelledResult.successCount == 0 && cancelledResult.failures.count == 1)
        precondition(!cancelledResult.isFullSuccess && FileManager.default.fileExists(atPath: retained.path))
        print("PASS: size totals, stream completeness/cancellation, pause/cancellation, background cleanup, and cancelled-item retention")
    }
}
