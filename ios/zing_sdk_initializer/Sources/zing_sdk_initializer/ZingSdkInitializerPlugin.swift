import Flutter
import UIKit
import ZingCoachSDK

public class ZingSdkInitializerPlugin: NSObject, FlutterPlugin {
    private var sdk: ZingSDK?

    private enum Method {
        static let initialize = "initialize"
        static let logout = "logout"
        static let openScreen = "openScreen"
    }

    private enum Route: String {
        case customWorkout = "custom_workout"
        case aiAssistant = "ai_assistant"
        case workoutPlanDetails = "workout_plan_details"
        case fullSchedule = "full_schedule"
        case profileSettings = "profile_settings"
    }

    private enum ScreenError: Error {
        case noRootViewController
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        dispatchPrecondition(condition: .onQueue(.main))
        let channel = FlutterMethodChannel(
            name: "zing_sdk_initializer",
            binaryMessenger: registrar.messenger()
        )
        let instance = ZingSdkInitializerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case Method.initialize:
            self.handleInitialize(result: result)
        case Method.logout:
            self.handleLogout(result: result)
        case Method.openScreen:
            self.handleOpenScreen(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleInitialize(result: @escaping FlutterResult) {
        guard sdk == nil else {
            result(nil)
            return
        }

        Task {
            let initResult = await ZingSDK.initialize(
                with: .init(
                    authentication: .guest(apiKey: "any key"),
                    errorHandler: self
                )
            )

            switch initResult {
            case .success(let sdkInstance):
                self.sdk = sdkInstance
                sdkInstance.login()
                result(nil)
            case .failure(let error):
                result(FlutterError(
                    code: "native_init_failed",
                    message: error.localizedDescription,
                    details: String(describing: error)
                ))
            }
        }
    }

    private func handleLogout(result: FlutterResult) {
        sdk?.logout()
        result(nil)
    }

    private func handleOpenScreen(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard 
            let sdk 
        else {
            result(FlutterError(
                code: "sdk_not_initialized",
                message: "Call initialize first",
                details: nil
            ))
            return
        }

        guard
            let args = call.arguments as? [String: Any],
            let rawRoute = args["route"] as? String,
            let route = Route(rawValue: rawRoute)
        else {
            result(FlutterError(
                code: "missing_route",
                message: "Route argument required",
                details: nil
            ))
            return
        }

        Task { @MainActor in
            do {
                let viewController = self.makeViewController(for: route, sdk: sdk)
                try self.presentViewController(viewController)
                result(nil)
            } catch ScreenError.noRootViewController {
                result(FlutterError(
                    code: "launch_failed",
                    message: "No root view controller available",
                    details: nil
                ))
            } catch {
                result(FlutterError(
                    code: "launch_failed",
                    message: error.localizedDescription,
                    details: String(describing: error)
                ))
            }
        }
    }

    @MainActor
    private func makeViewController(for route: Route, sdk: ZingSDK) -> UIViewController {
        switch route {
        case .customWorkout:
            sdk.makeCustomWorkoutModule()
        case .aiAssistant:
            sdk.makeAssistantChat()
        case .workoutPlanDetails:
            sdk.makeProgramModule()
        case .fullSchedule:
            sdk.makeProgramModule()
        case .profileSettings:
            sdk.makeProfileSettings()
        }
    }

    @MainActor
    private func presentViewController(_ viewController: UIViewController) throws {
        guard
            let scene = UIApplication.shared.currentScene,
            let firstWindow = scene.windows.first,
            let rootViewController = firstWindow.rootViewController
        else {
            throw ScreenError.noRootViewController
        }

        let presenter = rootViewController.topPresentedViewController.topInNavigationController
        viewController.modalPresentationStyle = .fullScreen
        presenter.present(viewController, animated: true)
    }
}

extension ZingSdkInitializerPlugin: ZingSDK.ErrorHandler {
    public func didReceiveError(_ error: ZingSDK.Error) {
        print("[ZingSdkInitializer] SDK Error: \(error)")
    }
}

private extension UIApplication {
    var currentScene: UIWindowScene? {
        connectedScenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
    }
}

private extension UIViewController {
    var topPresentedViewController: UIViewController {
        presentedViewController.flatMap { $0.topPresentedViewController } ?? self
    }

    var topInNavigationController: UIViewController {
        (self as? UINavigationController)?.topViewController ?? self
    }
}
