import Flutter
import Combine
import ZingCoachSDK

final class AuthStateStreamHandler: NSObject, FlutterStreamHandler {
    private let sdk: ZingSDK
    private var cancellable: AnyCancellable?

    init(sdk: ZingSDK) {
        self.sdk = sdk
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        cancellable?.cancel()
        cancellable = sdk.loginStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { state in
                events(state.toFlutter())
            }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        cancellable?.cancel()
        cancellable = nil
        return nil
    }
}

private extension ZingSDK.LoginState {
    func toFlutter() -> [String: String] {
        switch self {
        case .loggedOut:
            return ["state": "loggedOut"]
        case .inProgress:
            return ["state": "inProgress"]
        case .loggedIn:
            return ["state": "authenticated"]
        }
    }
}
