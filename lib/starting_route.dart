/// A destination screen that can be launched inside the native Zing SDK.
sealed class StartingRoute {
  const StartingRoute();

  /// Identifier understood by the native layer.
  String get routeId;

  /// Optional arguments for parameterized routes.
  Map<String, String>? get routeArgs => null;

  /// Serializes to the map sent over the method channel.
  Map<String, String> toMap() {
    return {
      'route': routeId,
      if (routeArgs != null) ...routeArgs!,
    };
  }
}

class CustomWorkoutRoute extends StartingRoute {
  const CustomWorkoutRoute();

  @override
  String get routeId => 'custom_workout';
}

class AiAssistantRoute extends StartingRoute {
  const AiAssistantRoute();

  @override
  String get routeId => 'ai_assistant';
}

class WorkoutPlanDetailsRoute extends StartingRoute {
  const WorkoutPlanDetailsRoute();

  @override
  String get routeId => 'workout_plan_details';
}

class FullScheduleRoute extends StartingRoute {
  const FullScheduleRoute();

  @override
  String get routeId => 'full_schedule';
}

class ProfileSettingsRoute extends StartingRoute {
  const ProfileSettingsRoute();

  @override
  String get routeId => 'profile_settings';
}

