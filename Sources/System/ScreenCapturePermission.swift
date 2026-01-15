import AppKit

enum ScreenCapturePermission {
    static func ensureAccess() -> Bool {
        // Screen Recording permission is required for capture APIs; prompt if missing.
        if CGPreflightScreenCaptureAccess() {
            return true
        }

        let granted = CGRequestScreenCaptureAccess()
        if !granted {
            showPermissionAlert()
        }
        return granted
    }

    private static func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText =
            "Enable screen recording access for OneShot in System Settings > Privacy & Security > " +
            "Screen Recording."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
