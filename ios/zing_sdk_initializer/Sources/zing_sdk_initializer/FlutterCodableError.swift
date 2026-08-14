import Flutter
import ZingCoachSDK

protocol FlutterCodableError: Error {
    var flutterCode: String { get }
}

extension ZingSdkInitializerPlugin.PluginError: FlutterCodableError {
    var flutterCode: String {
        switch self {
        case .notInitialized: "not_initialized"
        case .alreadyInitialized: "already_initialized"
        case .nativeInitFailed: "native_init_failed"
        case .loginFailed: "login_failed"
        case .missingRoute: "missing_route"
        case .unknownRoute: "unknown_route"
        case .noRootViewController: "no_activity"
        }
    }
}

extension LoginError: FlutterCodableError {
    var flutterCode: String {
        "login_failed"
    }
}

extension LogoutError: FlutterCodableError {
    var flutterCode: String {
        "logout_failed"
    }
}

extension ZingSDK.ScreenPresentationError: FlutterCodableError {
    var flutterCode: String {
        switch self {
        case .notLoggedIn:
            "not_logged_in"
        }
    }
}

extension ZingSDK.ProfileUpdateError: FlutterCodableError {
    var flutterCode: String {
        "set_profile_params_failed"
    }
}

extension Error {
    func toFlutter() -> FlutterError {
        FlutterError(
            code: (self as? FlutterCodableError)?.flutterCode ?? "unknown",
            message: String(describing: self),
            details: nil
        )
    }
}
