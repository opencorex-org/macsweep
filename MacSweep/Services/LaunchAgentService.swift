import Foundation
import OSLog

/// Enumerates user LaunchAgents and Login Items for the Startup Items feature.
public final class LaunchAgentService: Sendable {
    private let fileManager = FileManager.default

    public init() {}

    private var launchAgentsDirectory: URL {
        fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents")
    }

    /// Discovers user-installed LaunchAgent plist files.
    public func discoverLaunchAgents() -> [LaunchAgentInfo] {
        guard fileManager.fileExists(atPath: launchAgentsDirectory.path) else { return [] }

        var agents: [LaunchAgentInfo] = []

        guard let contents = try? fileManager.contentsOfDirectory(
            at: launchAgentsDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return agents }

        for url in contents where url.pathExtension == "plist" {
            if let info = parseLaunchAgent(at: url) {
                agents.append(info)
            }
        }

        return agents.sorted { $0.label < $1.label }
    }

    private func parseLaunchAgent(at url: URL) -> LaunchAgentInfo? {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let label = plist["Label"] as? String else {
            return nil
        }

        return LaunchAgentInfo(
            url: url,
            label: label,
            isEnabled: !(plist["Disabled"] as? Bool ?? false)
        )
    }
}

/// Represents a discovered LaunchAgent.
public struct LaunchAgentInfo: Identifiable, Sendable {
    public let id = UUID()
    public let url: URL
    public let label: String
    public let isEnabled: Bool
}
