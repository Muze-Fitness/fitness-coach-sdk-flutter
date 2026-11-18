import Flutter
import Combine
import Foundation
import ZingCoachSDK

final class WorkoutActivityHandler {
    private enum Method {
        static let getPlannedWorkouts = "getPlannedWorkouts"
        static let observePlannedWorkouts = "observePlannedWorkouts"
        static let getCompletedWorkouts = "getCompletedWorkouts"
        static let observeCompletedWorkouts = "observeCompletedWorkouts"
        static let cancel = "cancelWorkoutActivity"
    }

    private enum Event {
        static let data = "onData"
        static let done = "onDone"
    }

    private let channel: FlutterMethodChannel
    private var subscriptions: [Int: AnyCancellable] = [:]

    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    func handle(_ call: FlutterMethodCall, sdk: ZingSDK?, result: @escaping FlutterResult) -> Bool {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case Method.getPlannedWorkouts:
            respond(sdk: sdk, result: result) { sdk in
                try sdk.plannedWorkouts.map(\.flutterMap)
            }
        case Method.getCompletedWorkouts:
            respond(sdk: sdk, result: result) { sdk in
                try sdk.completedWorkouts(in: Self.interval(from: args)).map(\.flutterMap)
            }
        case Method.observePlannedWorkouts:
            observe(args: args, sdk: sdk, result: result) { sdk in
                try sdk.plannedWorkoutsPublisher
                    .map { $0.map(\.flutterMap) as Any }
                    .eraseToAnyPublisher()
            }
        case Method.observeCompletedWorkouts:
            observe(args: args, sdk: sdk, result: result) { sdk in
                try sdk.completedWorkoutsPublisher(in: Self.interval(from: args))
                    .map { $0.map(\.flutterMap) as Any }
                    .eraseToAnyPublisher()
            }
        case Method.cancel:
            if let id = (args["id"] as? NSNumber)?.intValue {
                subscriptions.removeValue(forKey: id)?.cancel()
            }
            result(nil)
        default:
            return false
        }
        return true
    }

    private func respond(sdk: ZingSDK?, result: FlutterResult, makeValue: (ZingSDK) throws -> Any) {
        guard let sdk else {
            result(ZingSdkInitializerPlugin.PluginError.notInitialized.toFlutter())
            return
        }
        do {
            result(try makeValue(sdk))
        } catch {
            result(error.toFlutter())
        }
    }

    private func observe(
        args: [String: Any],
        sdk: ZingSDK?,
        result: FlutterResult,
        makePublisher: (ZingSDK) throws -> AnyPublisher<Any, Never>
    ) {
        guard let sdk else {
            result(ZingSdkInitializerPlugin.PluginError.notInitialized.toFlutter())
            return
        }
        guard let id = (args["id"] as? NSNumber)?.intValue else {
            result(WorkoutActivityArgumentError.missingArgument("id").toFlutter())
            return
        }
        let publisher: AnyPublisher<Any, Never>
        do {
            publisher = try makePublisher(sdk)
        } catch {
            result(error.toFlutter())
            return
        }
        subscriptions.removeValue(forKey: id)?.cancel()
        subscriptions[id] = publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.subscriptions.removeValue(forKey: id)
                    self?.channel.invokeMethod(Event.done, arguments: ["id": id])
                },
                receiveValue: { [weak self] data in
                    self?.channel.invokeMethod(Event.data, arguments: ["id": id, "data": data])
                }
            )
        result(nil)
    }

    private static func interval(from args: [String: Any]) throws -> DateInterval {
        guard let start = (args["start"] as? NSNumber)?.int64Value else {
            throw WorkoutActivityArgumentError.missingArgument("start")
        }
        guard let end = (args["end"] as? NSNumber)?.int64Value else {
            throw WorkoutActivityArgumentError.missingArgument("end")
        }
        guard end >= start else {
            throw WorkoutActivityArgumentError.invalidInterval
        }
        return DateInterval(start: Date(flutterMillis: start), end: Date(flutterMillis: end))
    }
}

enum WorkoutActivityArgumentError: Error {
    case missingArgument(String)
    case invalidInterval
}

extension WorkoutActivityArgumentError: FlutterCodableError {
    var flutterCode: String {
        "workout_activity_failed"
    }
}

extension ZingSDK.WorkoutActivityError: FlutterCodableError {
    var flutterCode: String {
        switch self {
        case .notLoggedIn: "not_logged_in"
        case .onboardingNotCompleted: "onboarding_not_completed"
        }
    }
}

private extension PlannedWorkout {
    var flutterMap: [String: Any] {
        [
            "workoutType": workoutType.flutterName,
            "date": date.flutterMillis,
            "estimatedDuration": Int64((estimatedDuration * 1000).rounded()),
        ]
    }
}

private extension CompletedWorkout {
    var flutterMap: [String: Any] {
        [
            "workoutType": workoutType.flutterName,
            "date": date.flutterMillis,
            "actualDuration": Int64((actualDuration * 1000).rounded()),
        ]
    }
}

private extension PlannedWorkout.WorkoutType {
    var flutterName: String {
        switch self {
        case .regular: "regular"
        case .recovery: "recovery"
        }
    }
}

private extension Date {
    init(flutterMillis: Int64) {
        self.init(timeIntervalSince1970: TimeInterval(flutterMillis) / 1000)
    }

    var flutterMillis: Int64 {
        Int64((timeIntervalSince1970 * 1000).rounded())
    }
}
