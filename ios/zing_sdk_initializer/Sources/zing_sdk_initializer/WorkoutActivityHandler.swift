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
    private let sdk: () throws -> ZingSDK
    private var subscriptions: [Int: AnyCancellable] = [:]

    init(channel: FlutterMethodChannel, sdk: @escaping () throws -> ZingSDK) {
        self.channel = channel
        self.sdk = sdk
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case Method.getPlannedWorkouts:
            respond(result) {
                try self.sdk().plannedWorkouts.map(\.flutterMap)
            }
        case Method.getCompletedWorkouts:
            respond(result) {
                try self.sdk().completedWorkouts(in: Self.interval(from: args)).map(\.flutterMap)
            }
        case Method.observePlannedWorkouts:
            observe(args: args, result: result) {
                try self.sdk().plannedWorkoutsPublisher
                    .map { $0.map(\.flutterMap) }
                    .eraseToAnyPublisher()
            }
        case Method.observeCompletedWorkouts:
            observe(args: args, result: result) {
                try self.sdk().completedWorkoutsPublisher(in: Self.interval(from: args))
                    .map { $0.map(\.flutterMap) }
                    .eraseToAnyPublisher()
            }
        case Method.cancel:
            if let id = (args["id"] as? NSNumber)?.intValue {
                subscriptions.removeValue(forKey: id)?.cancel()
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func respond(_ result: FlutterResult, makeValue: () throws -> Any) {
        do {
            result(try makeValue())
        } catch {
            result(error.toFlutter())
        }
    }

    private func observe(
        args: [String: Any],
        result: FlutterResult,
        makePublisher: () throws -> AnyPublisher<[[String: Any]], Never>
    ) {
        guard let id = (args["id"] as? NSNumber)?.intValue else {
            result(WorkoutActivityArgumentError.missingArgument("id").toFlutter())
            return
        }
        let publisher: AnyPublisher<[[String: Any]], Never>
        do {
            publisher = try makePublisher()
        } catch {
            result(error.toFlutter())
            return
        }
        subscriptions.removeValue(forKey: id)?.cancel()
        subscriptions[id] = publisher
            .removeDuplicates { NSArray(array: $0).isEqual(to: $1) }
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

private extension PlannedWorkout {
    var flutterMap: [String: Any] {
        [
            "workoutType": workoutType.flutterName,
            "date": date.timeIntervalSince1970.flutterMillis,
            "estimatedDuration": estimatedDuration.flutterMillis,
        ]
    }
}

private extension CompletedWorkout {
    var flutterMap: [String: Any] {
        [
            "workoutType": workoutType.flutterName,
            "date": date.timeIntervalSince1970.flutterMillis,
            "actualDuration": actualDuration.flutterMillis,
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

private extension TimeInterval {
    var flutterMillis: Int64 {
        Int64((self * 1000).rounded())
    }
}

private extension Date {
    init(flutterMillis: Int64) {
        self.init(timeIntervalSince1970: TimeInterval(flutterMillis) / 1000)
    }
}
