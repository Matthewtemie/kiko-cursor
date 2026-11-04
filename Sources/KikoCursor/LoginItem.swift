import Foundation
import ServiceManagement

/// Start at login, through macOS's own login items list, so it also shows up in
/// System Settings > General > Login Items and can be turned off from there.
enum LoginItem {
    private struct NotInApplications: LocalizedError {
        var errorDescription: String? {
            "Drag Kiko Cursor to your Applications folder in Finder, open it from there, then switch this on."
        }
    }

    static var isOn: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Registered, but waiting for the user to allow it in System Settings.
    static var needsApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    static func set(_ on: Bool) throws {
        if on {
            // macOS runs a downloaded app from a temporary folder until it's been moved, so a login
            // item made from there would point at nothing after a restart.
            if Bundle.main.bundlePath.contains("/AppTranslocation/") {
                throw NotInApplications()
            }
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    static var statusName: String {
        switch SMAppService.mainApp.status {
        case .notRegistered: return "off"
        case .enabled: return "on"
        case .requiresApproval: return "needs approval"
        case .notFound: return "not found"
        @unknown default: return "unknown"
        }
    }
}
