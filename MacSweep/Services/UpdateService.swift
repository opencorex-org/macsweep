import Foundation
import OSLog

/// Checks for new versions of MacSweep via the GitHub Releases API.
public actor UpdateService {
    public init() {}

    /// Checks for a newer release on GitHub.
    public func checkForUpdate() async -> UpdateInfo? {
        guard let url = URL(string: "https://api.github.com/repos/OpenCorex/macsweep/releases/latest") else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)

            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
            guard release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "v")) != currentVersion else {
                return nil
            }

            return UpdateInfo(
                version: release.tagName,
                releaseURL: release.htmlURL,
                releaseNotes: release.body
            )
        } catch {
            Logger.app.debug("Update check failed: \(error.localizedDescription)")
            return nil
        }
    }
}

public struct UpdateInfo: Sendable {
    public let version: String
    public let releaseURL: String
    public let releaseNotes: String?
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: String
    let body: String?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case body
    }
}
