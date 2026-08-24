import Foundation
import OSLog

/// Provides safe, controlled subprocess execution for limited external tool interaction.
/// MacSweep avoids shell execution wherever possible, preferring native APIs.
/// This runner is used only for Xcode/developer tool metadata queries.
public actor ProcessRunner {
    /// Runs a process and returns its standard output as a trimmed string.
    /// - Parameters:
    ///   - executableURL: The full path to the executable (e.g., `/usr/bin/xcode-select`).
    ///   - arguments: The arguments to pass to the executable.
    ///   - timeout: Maximum execution time in seconds before termination.
    /// - Returns: The trimmed standard output string.
    /// - Throws: `MacSweepError` if the process fails or times out.
    public static func run(
        executableURL: URL,
        arguments: [String],
        timeout: TimeInterval = 30
    ) async throws -> String {
        Logger.app.debug("Running process: \(executableURL.path, privacy: .public) \(arguments.joined(separator: " "), privacy: .private)")

        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()

        // Enforce timeout
        let timeoutTask = Task {
            try await Task.sleep(for: .seconds(timeout))
            if process.isRunning {
                process.terminate()
                Logger.app.warning("Process timed out after \(timeout)s: \(executableURL.path, privacy: .public)")
            }
        }

        process.waitUntilExit()
        timeoutTask.cancel()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            Logger.app.error("Process failed with status \(process.terminationStatus): \(errorOutput, privacy: .private)")
            throw MacSweepError.operationCancelled
        }

        return output
    }
}
