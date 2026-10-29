import Foundation
import os

/// Thread-safe cooperative control shared by every worker in one scan.
public nonisolated final class ScanControl: @unchecked Sendable {
    private nonisolated enum State {
        case running
        case paused
        case cancelled
    }

    private let state = OSAllocatedUnfairLock(initialState: State.running)

    public init() {}

    public var isPaused: Bool {
        state.withLock { $0 == .paused }
    }

    public var isCancelled: Bool {
        state.withLock { $0 == .cancelled }
    }

    public func pause() {
        state.withLock { current in
            guard current == .running else { return }
            current = .paused
        }
    }

    public func resume() {
        state.withLock { current in
            guard current == .paused else { return }
            current = .running
        }
    }

    public func cancel() {
        state.withLock { $0 = .cancelled }
    }

    /// Suspends a worker while paused and returns false when it should stop.
    public func waitUntilRunnable() async -> Bool {
        while true {
            if Task.isCancelled { return false }

            switch state.withLock({ $0 }) {
            case .running:
                return true
            case .cancelled:
                return false
            case .paused:
                do {
                    try await Task.sleep(for: .milliseconds(75))
                } catch {
                    return false
                }
            }
        }
    }
}
