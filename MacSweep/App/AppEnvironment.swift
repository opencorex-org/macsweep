import Foundation
import SwiftUI
import Combine

/// Central dependency injection container providing shared service instances
/// across the MacSweep application. Injected via SwiftUI environment.
@MainActor
public final class AppEnvironment: ObservableObject {
    // MARK: - Core Services
    public let diskSpaceService: DiskSpaceService
    public let fileSystemService: FileSystemService
    public let permissionManager: PermissionManager

    // MARK: - Scan & Clean Engines
    public let scanEngine: ScanEngine
    public let cleanEngine: CleanEngine
    public let safetyValidator: SafetyValidator

    // MARK: - Feature Services
    public let largeFileService: LargeFileService
    public let applicationService: ApplicationService

    public init() {
        self.diskSpaceService = DiskSpaceService()
        self.fileSystemService = FileSystemService()
        self.permissionManager = PermissionManager()
        self.safetyValidator = SafetyValidator()
        self.scanEngine = ScanEngine(safetyValidator: safetyValidator)
        self.cleanEngine = CleanEngine(safetyValidator: safetyValidator)
        self.largeFileService = LargeFileService()
        self.applicationService = ApplicationService()
    }
}
