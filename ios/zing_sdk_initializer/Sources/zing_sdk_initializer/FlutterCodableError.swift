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
        case .missingRoute: "missing_route"
        case .unknownRoute: "unknown_route"
        case .noRootViewController: "no_activity"
        }
    }
}

extension ZingSDK.Error: FlutterCodableError {
    var flutterCode: String {
        switch self {
        case .authError: "auth_error"
        case .loginError: "login_failed"
        }
    }
}

extension ZingSDK.AuthError: FlutterCodableError {
    var flutterCode: String {
        "auth_error"
    }
}

extension ZingSDK.LoginError: FlutterCodableError {
    var flutterCode: String {
        "login_failed"
    }
}

extension ZingSDK.LogoutError: FlutterCodableError {
    var flutterCode: String {
        "logout_failed"
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
