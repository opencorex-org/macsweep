import Foundation
import OSLog
import Security

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
            isEnabled: !(plist["Disabled"] as? Bool ?? false),
            executablePath: (plist["Program"] as? String) ?? (plist["ProgramArguments"] as? [String])?.first,
            runsAtLoad: plist["RunAtLoad"] as? Bool ?? false,
            keepsAlive: (plist["KeepAlive"] as? Bool) ?? false
        )
    }
}

/// Represents a discovered LaunchAgent.
public struct LaunchAgentInfo: Identifiable, Sendable {
    public let id = UUID()
    public let url: URL
    public let label: String
    public let isEnabled: Bool
    public let executablePath: String?
    public let runsAtLoad: Bool
    public let keepsAlive: Bool

    public var publisher: String {
        let parts = label.split(separator: ".")
        guard parts.count >= 2 else { return "Unknown publisher" }
        if parts.first == "com" { return String(parts.dropFirst().first ?? "Unknown").capitalized }
        return String(parts.first!).capitalized
    }

    public var impact: String {
        if keepsAlive { return "High" }
        if runsAtLoad { return "Medium" }
        return "Low"
    }

    public var signatureStatus: String {
        guard let executablePath else { return "Unknown" }
        let expanded = NSString(string: executablePath).expandingTildeInPath as CFString
        var code: SecStaticCode?
        guard SecStaticCodeCreateWithPath(URL(fileURLWithPath: expanded as String) as CFURL, [], &code) == errSecSuccess,
              let code else { return "Unsigned" }
        return SecStaticCodeCheckValidity(code, [], nil) == errSecSuccess ? "Signed" : "Unsigned"
    }
}
