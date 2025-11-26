import Flutter
import UIKit

public class ZingSdkInitializerPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel?

  private enum Method {
    static let initialize = "initialize"
    static let updateAuthToken = "updateAuthToken"
    static let setTokenRefreshSupport = "setTokenRefreshSupport"
    static let refreshAuthToken = "refreshAuthToken"
    static let logout = "logout"
  }

  private enum Argument {
    static let token = "token"
    static let enabled = "enabled"
    static let supportsAuthTokenRefresh = "supportsAuthTokenRefresh"
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "zing_sdk_initializer",
      binaryMessenger: registrar.messenger()
    )
    let instance = ZingSdkInitializerPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case Method.initialize:
      handleInitialize(arguments: call.arguments, result: result)
    case Method.updateAuthToken:
      handleUpdateAuthToken(arguments: call.arguments, result: result)
    case Method.setTokenRefreshSupport:
      handleSetTokenRefreshSupport(arguments: call.arguments, result: result)
    case Method.logout:
      handleLogout(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleInitialize(arguments: Any?, result: FlutterResult) {
    guard arguments as? [String: Any?] != nil else {
      result(invalidArgumentsError(for: Method.initialize, message: "Expected argument dictionary"))
      return
    }
    // TODO(iOS SDK): Pass parsed config to the native SDK and return status.
    result(notConfiguredError(for: Method.initialize))
  }

  private func handleUpdateAuthToken(arguments: Any?, result: FlutterResult) {
    guard
      let raw = arguments as? [String: Any?],
      let token = raw[Argument.token] as? String,
      !token.isEmpty
    else {
      result(invalidArgumentsError(for: Method.updateAuthToken, message: "token is required"))
      return
    }
    // TODO(iOS SDK): Forward token to the native SDK.
    result(notConfiguredError(for: Method.updateAuthToken))
  }

  private func handleSetTokenRefreshSupport(arguments: Any?, result: FlutterResult) {
    guard
      let raw = arguments as? [String: Any?],
      raw[Argument.enabled] as? Bool != nil
    else {
      result(invalidArgumentsError(for: Method.setTokenRefreshSupport, message: "enabled flag is required"))
      return
    }
    // TODO(iOS SDK): Register/unregister native token refresh handler.
    result(notConfiguredError(for: Method.setTokenRefreshSupport))
  }

  private func handleLogout(result: FlutterResult) {
    // TODO(iOS SDK): Forward logout request to the native SDK.
    result(notConfiguredError(for: Method.logout))
  }

  private func invalidArgumentsError(for method: String, message: String) -> FlutterError {
    FlutterError(
      code: "invalid_args",
      message: "\(method): \(message)",
      details: nil
    )
  }

  private func notConfiguredError(for method: String) -> FlutterError {
    FlutterError(
      code: "ios_sdk_unavailable",
      message: "\(method) is not implemented on iOS. Integrate the native SDK and update the plugin implementation.",
      details: nil
    )
  }
}

