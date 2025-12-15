import 'zing_sdk_initializer_platform_interface.dart';

export 'workout_plan_card_view.dart';

/// Destinations that can be launched directly inside the native Zing SDK.
enum ZingSdkScreen {
  customWorkout('custom_workout'),
  aiAssistant('ai_assistant'),
  workoutPlanDetails('workout_plan_details'),
  fullSchedule('full_schedule'),
  profileSettings('profile_settings'),
  healthConnectPermissions('health_connect_permissions');

  const ZingSdkScreen(this.routeId);

  /// Identifier understood by the native layer.
  final String routeId;
}

/// Public API for initializing and interacting with the native Zing SDK.
class ZingSdkInitializer {
  ZingSdkInitializer._();

  static final ZingSdkInitializer instance = ZingSdkInitializer._();

  bool _isInitialized = false;

  /// Initializes the native SDK if it has not been configured yet.
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await ZingSdkInitializerPlatform.instance.initialize();
    _isInitialized = true;
  }

  /// Logs out from the native SDK and allows initializing it again.
  Future<void> logout() async {
    await ZingSdkInitializerPlatform.instance.logout();
    _isInitialized = false;
  }

  /// Opens one of the predefined SDK screens such as AI chat or schedule.
  ///
  /// Throws [StateError] if the SDK has not been initialized yet.
  Future<void> openScreen(ZingSdkScreen screen) {
    if (!_isInitialized) {
      throw StateError(
        'Zing SDK is not initialized. Call initialize() before opening screens.',
      );
    }

    return ZingSdkInitializerPlatform.instance.openScreen(screen.routeId);
  }
}
