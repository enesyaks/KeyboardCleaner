import Foundation
import ServiceManagement

enum LaunchAtLogin {
    struct Result {
        let isEnabled: Bool
        let errorDescription: String?
    }

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Result {
        let service = SMAppService.mainApp
        do {
            if enabled {
                if service.status == .enabled {
                    return Result(isEnabled: true, errorDescription: nil)
                }
                try service.register()
                return Result(isEnabled: service.status == .enabled, errorDescription: nil)
            } else {
                if service.status == .notRegistered {
                    return Result(isEnabled: false, errorDescription: nil)
                }
                try service.unregister()
                return Result(isEnabled: false, errorDescription: nil)
            }
        } catch {
            let message: String
            if enabled {
                message = "Couldn’t enable launch at login. Move the app to Applications and try again."
            } else {
                message = "Couldn’t disable launch at login: \(error.localizedDescription)"
            }
            return Result(isEnabled: service.status == .enabled, errorDescription: message)
        }
    }
}
