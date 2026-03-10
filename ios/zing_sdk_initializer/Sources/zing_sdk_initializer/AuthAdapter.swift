import Foundation
import Flutter
import ZingCoachSDK

final class AuthAdapter: ZingSDK.AuthProvider {
    private let channel: FlutterMethodChannel

    enum AuthError: Error {
        case failedGetToken
    }

    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    func didRequestAuthToken() async -> Result<String, Error> {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { [channel] in
                channel.invokeMethod("getAuthToken", arguments: nil) { result in
                    guard let token = result as? String else {
                        continuation.resume(returning: .failure(AuthError.failedGetToken))
                        return
                    }
                    continuation.resume(returning: .success(token))
                }
            }
        }
    }
}
