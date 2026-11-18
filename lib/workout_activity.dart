/// Kind of a planned or completed workout.
enum SdkWorkoutType {
  regular,
  recovery;

  static SdkWorkoutType fromName(String name) {
    return values.firstWhere(
      (type) => type.name == name,
      orElse: () => throw ArgumentError('Unknown workout type: $name'),
    );
  }
}

/// [PlatformException] codes thrown by the workout activity API.
abstract final class WorkoutActivityErrorCode {
  /// The user is not logged in.
  static const notLoggedIn = 'not_logged_in';

  /// The user has not completed onboarding, so there is no plan yet.
  static const onboardingNotCompleted = 'onboarding_not_completed';

  /// The SDK has not been initialized (iOS).
  static const notInitialized = 'not_initialized';
}

/// A workout of the current plan.
class PlannedWorkout {
  const PlannedWorkout({
    required this.workoutType,
    required this.date,
    required this.estimatedDuration,
  });

  factory PlannedWorkout.fromMap(Map<Object?, Object?> map) {
    return PlannedWorkout(
      workoutType: SdkWorkoutType.fromName(map['workoutType'] as String),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      estimatedDuration: Duration(
        milliseconds: map['estimatedDuration'] as int,
      ),
    );
  }

  final SdkWorkoutType workoutType;

  /// Start of the planned day, in local time.
  final DateTime date;

  final Duration estimatedDuration;

  @override
  bool operator ==(Object other) =>
      other is PlannedWorkout &&
      other.workoutType == workoutType &&
      other.date == date &&
      other.estimatedDuration == estimatedDuration;

  @override
  int get hashCode => Object.hash(workoutType, date, estimatedDuration);

  @override
  String toString() =>
      'PlannedWorkout(workoutType: $workoutType, date: $date, estimatedDuration: $estimatedDuration)';
}

/// A workout the user has finished.
class CompletedWorkout {
  const CompletedWorkout({
    required this.workoutType,
    required this.date,
    required this.actualDuration,
  });

  factory CompletedWorkout.fromMap(Map<Object?, Object?> map) {
    return CompletedWorkout(
      workoutType: SdkWorkoutType.fromName(map['workoutType'] as String),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      actualDuration: Duration(milliseconds: map['actualDuration'] as int),
    );
  }

  final SdkWorkoutType workoutType;

  /// When the workout started, in local time.
  final DateTime date;

  final Duration actualDuration;

  @override
  bool operator ==(Object other) =>
      other is CompletedWorkout &&
      other.workoutType == workoutType &&
      other.date == date &&
      other.actualDuration == actualDuration;

  @override
  int get hashCode => Object.hash(workoutType, date, actualDuration);

  @override
  String toString() =>
      'CompletedWorkout(workoutType: $workoutType, date: $date, actualDuration: $actualDuration)';
}
