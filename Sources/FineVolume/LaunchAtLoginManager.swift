import ServiceManagement

final class LaunchAtLoginManager {
    var status: SMAppService.Status {
        SMAppService.mainApp.status
    }

    func enable() throws {
        guard status == .notRegistered || status == .notFound else { return }
        try SMAppService.mainApp.register()
    }

    func disable() throws {
        guard status == .enabled || status == .requiresApproval else { return }
        try SMAppService.mainApp.unregister()
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
