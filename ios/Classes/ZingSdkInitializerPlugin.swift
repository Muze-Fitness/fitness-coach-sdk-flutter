import Flutter
import UIKit

public class ZingSdkInitializerPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel?

  private enum Method {
    static let initialize = "initialize"
    static let logout = "logout"
    static let openScreen = "openScreen"
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
      handleInitialize(result: result)
    case Method.logout:
      handleLogout(result: result)
    case Method.openScreen:
      handleOpenScreen(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleInitialize(result: FlutterResult) {
    // TODO(iOS SDK): Pass parsed config to the native SDK and return status.
    result(notConfiguredError(for: Method.initialize))
  }

  private func handleLogout(result: FlutterResult) {
    // TODO(iOS SDK): Forward logout request to the native SDK.
    result(notConfiguredError(for: Method.logout))
  }

  private func handleOpenScreen(result: FlutterResult) {
    // TODO(iOS SDK): Forward specific route launch to the native SDK.
    result(notConfiguredError(for: Method.openScreen))
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

