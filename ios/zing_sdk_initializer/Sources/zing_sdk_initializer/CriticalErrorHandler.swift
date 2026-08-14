import Flutter
import ZingCoachSDK

final class CriticalErrorHandler: ZingCoachSDK.CriticalErrorHandler {
    private let channel: FlutterMethodChannel

    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    func sdkDidFail(with error: Error) {
        let code = (error as? FlutterCodableError)?.flutterCode ?? "unknown"
        DispatchQueue.main.async { [channel] in
            channel.invokeMethod(
                "onCriticalError",
                arguments: [
                    "code": code,
                    "message": String(describing: error)
                ]
            )
        }
    }
}
