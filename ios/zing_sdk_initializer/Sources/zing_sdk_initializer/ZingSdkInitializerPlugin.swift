import Flutter
import UIKit
import DesignSystem
import ZingCoachSDK

public class ZingSdkInitializerPlugin: NSObject, FlutterPlugin {
    private var sdk: ZingSDK?
    private var authTokenChannel: FlutterMethodChannel?
    private var authStateChannel: FlutterEventChannel?

    private enum Channel {
        static let initializer = "zing_sdk_initializer"
        static let authState = "zing_sdk_initializer/auth_state"
        static let authTokenCallback = "zing_sdk_initializer/auth_token_callback"
    }

    private enum Method {
        static let initialize = "init"
        static let login = "login"
        static let logout = "logout"
        static let openScreen = "openScreen"
    }

    private enum Route: String {
        case customWorkout = "custom_workout"
        case aiAssistant = "ai_assistant"
        case workoutPlanDetails = "workout_plan_details"
        case fullSchedule = "full_schedule"
        case home = "home"
        case profileSettings = "profile_settings"
        case bodyScan = "body_scan"
        case flexibilityTest = "flexibility_test"
        case fitnessTest = "fitness_test"
    }

    enum PluginError: Error {
        case notInitialized
        case alreadyInitialized
        case nativeInitFailed
        case missingRoute
        case unknownRoute(String)
        case noRootViewController
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        dispatchPrecondition(condition: .onQueue(.main))

        let initializerChannel = FlutterMethodChannel(
            name: Channel.initializer,
            binaryMessenger: registrar.messenger()
        )
        let authStateChannel = FlutterEventChannel(
            name: Channel.authState,
            binaryMessenger: registrar.messenger()
        )

        let instance = ZingSdkInitializerPlugin()
        instance.authStateChannel = authStateChannel
        instance.authTokenChannel = FlutterMethodChannel(
            name: Channel.authTokenCallback,
            binaryMessenger: registrar.messenger()
        )

        registrar.addMethodCallDelegate(instance, channel: initializerChannel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case Method.initialize:
            handleInitialize(method: call, result)
        case Method.login:
            handleLogin(result)
        case Method.logout:
            handleLogout(result)
        case Method.openScreen:
            handleOpenScreen(method: call, result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleInitialize(method: FlutterMethodCall, _ completion: @escaping FlutterResult) {
        guard sdk == nil else {
            completion(PluginError.alreadyInitialized.toFlutter())
            return
        }

        guard
            let args = method.arguments as? [String: Any],
            let type = args["type"] as? String
        else {
            completion(PluginError.nativeInitFailed.toFlutter())
            return
        }

        let authentication: ZingSDK.AuthenticationType
        switch type {
        case "apiKey":
            guard let key = args["apiKey"] as? String else {
                completion(PluginError.nativeInitFailed.toFlutter())
                return
            }
            authentication = .apiKey(key: key)
        case "externalToken":
            guard let channel = authTokenChannel else {
                completion(PluginError.nativeInitFailed.toFlutter())
                return
            }
            authentication = .externalToken(provider: AuthAdapter(channel: channel), errorHandler: self)
        default:
            completion(PluginError.nativeInitFailed.toFlutter())
            return
        }

        let configuration: ZingSDK.Configuration
        if let configDict = args["configuration"] as? [String: Any] {
            guard
                let coachesRaw = configDict["coachesAvailability"] as? String,
                let coaches = CoachesAvailability(rawValue: coachesRaw),
                let genderRaw = configDict["genderAvailability"] as? String,
                let gender = GenderAvailability(rawValue: genderRaw)
            else {
                completion(PluginError.nativeInitFailed.toFlutter())
                return
            }
            configuration = ZingSDK.Configuration(
                coachesAvailability: coaches,
                genderAvailability: gender
            )
        } else {
            configuration = ZingSDK.Configuration()
        }

        let theme = (args["theme"] as? [String: Any]).map { FlutterTheme(arguments: $0).build() }
        let parameters = ZingSDK.InitializationParameters(
            authentication: authentication,
            theme: theme,
            configuration: configuration
        )

        Task { @MainActor in
            let result = await ZingSDK.initialize(with: parameters)
            switch result {
            case .success(let sdkInstance):
                self.sdk = sdkInstance
                self.authStateChannel?.setStreamHandler(AuthStateStreamHandler(sdk: sdkInstance))
                completion(nil)
            case .failure:
                completion(PluginError.nativeInitFailed.toFlutter())
            }
        }
    }

    private func handleLogin(_ completion: @escaping FlutterResult) {
        guard let sdk else {
            completion(PluginError.notInitialized.toFlutter())
            return
        }
        Task { @MainActor in
            switch await sdk.login() {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error.toFlutter())
            }
        }
    }

    private func handleLogout(_ completion: @escaping FlutterResult) {
        guard let sdk else {
            completion(PluginError.notInitialized.toFlutter())
            return
        }
        Task { @MainActor in
            switch await sdk.logout() {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error.toFlutter())
            }
        }
    }

    private func handleOpenScreen(method: FlutterMethodCall, _ completion: @escaping FlutterResult) {
        guard let sdk else {
            completion(PluginError.notInitialized.toFlutter())
            return
        }
        guard
            let args = method.arguments as? [String: Any],
            let rawRoute = args["route"] as? String
        else {
            completion(PluginError.missingRoute.toFlutter())
            return
        }
        guard let route = ZingSdkInitializerPlugin.Route(rawValue: rawRoute) else {
            completion(PluginError.unknownRoute(rawRoute).toFlutter())
            return
        }
        Task { @MainActor in
            let viewController = makeViewController(for: route, sdk: sdk)
            presentViewController(viewController, completion: completion)
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
            sdk.makeFullSchedule()
        case .fullSchedule:
            sdk.makeFullSchedule()
        case .home:
            sdk.makeProgramModule()
        case .profileSettings:
            sdk.makeProfileSettings()
        case .bodyScan:
            sdk.makeBodyScan()
        case .flexibilityTest:
            sdk.makeFlexibilityTest(useFrontCamera: true)
        case .fitnessTest:
            sdk.makeFitnessTest(useFrontCamera: true)
        }
    }

    @MainActor
    private func presentViewController(_ viewController: UIViewController, completion: @escaping FlutterResult) {
        guard
            let scene = UIApplication.shared.currentScene,
            let rootViewController = scene.keyWindow?.rootViewController
        else {
            completion(PluginError.noRootViewController.toFlutter())
            return
        }

        let presenter = rootViewController.topPresentedViewController.topInNavigationController
        viewController.modalPresentationStyle = .fullScreen
        presenter.present(viewController, animated: true)
        completion(nil)
    }

    private static func coachesAvailability(from raw: String) -> CoachesAvailability? {
        switch raw {
        case "allCoaches": .allCoaches
        case "userGenderBased": .userGenderBased
        default: nil
        }
    }

    private static func genderAvailability(from raw: String) -> GenderAvailability? {
        switch raw {
        case "all": .all
        case "binary": .binary
        default: nil
        }
    }
}

extension ZingSdkInitializerPlugin: ZingSDK.ErrorHandler {
    public func didReceiveError(_ error: AuthError) {
        if case .badToken = error {
            DispatchQueue.main.async { [weak self] in
                self?.authTokenChannel?.invokeMethod("onTokenInvalid", arguments: nil)
            }
        }
    }
}
