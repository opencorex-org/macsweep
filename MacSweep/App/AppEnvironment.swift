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
    public let updateService: UpdateService
    public let volumeService: VolumeService
    public let appFolderMoverService: AppFolderMoverService
    public let cleanupHistoryService: CleanupHistoryService
    public let exclusionService: ExclusionService
    public let notificationService: NotificationService
    public let loginItemService: LoginItemService
    public let storageHistoryService: StorageHistoryService
    public let customRuleService: CustomRuleService
    public let diagnosticReportService: DiagnosticReportService
    public let externalDriveMonitor: ExternalDriveMonitor
    public lazy var automationService = AutomationService(
        scanEngine: scanEngine,
        cleanEngine: cleanEngine,
        exclusionService: exclusionService,
        customRuleService: customRuleService,
        historyService: cleanupHistoryService,
        notificationService: notificationService
    )

    public init() {
        self.diskSpaceService = DiskSpaceService()
        self.fileSystemService = FileSystemService()
        self.permissionManager = PermissionManager()
        self.safetyValidator = SafetyValidator()
        self.scanEngine = ScanEngine(safetyValidator: safetyValidator)
        self.cleanEngine = CleanEngine(safetyValidator: safetyValidator)
        self.largeFileService = LargeFileService()
        self.applicationService = ApplicationService()
        self.updateService = UpdateService()
        self.volumeService = VolumeService()
        self.appFolderMoverService = AppFolderMoverService()
        self.cleanupHistoryService = CleanupHistoryService()
        self.exclusionService = ExclusionService()
        self.notificationService = NotificationService()
        self.loginItemService = LoginItemService()
        self.storageHistoryService = StorageHistoryService()
        self.customRuleService = CustomRuleService()
        self.diagnosticReportService = DiagnosticReportService()
        self.externalDriveMonitor = ExternalDriveMonitor()

        let notifier = notificationService
        externalDriveMonitor.onMount = { volumeURL in
            guard UserDefaults.standard.bool(forKey: "externalDriveAutoScan") else { return }
            Task.detached {
                let size = await FileEnumerator.directorySize(volumeURL)
                await MainActor.run {
                    notifier.send(
                        title: "External drive analyzed",
                        body: "\(volumeURL.lastPathComponent) contains approximately \(ByteFormatter.format(size)). Open Storage Manager for details."
                    )
                }
            }
        }
        notificationService.requestAuthorization()
        _ = automationService
    }
}
