import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'profile_params.dart';
import 'sdk_auth_state.dart';
import 'sdk_authentication.dart';
import 'sdk_configuration.dart';
import 'sdk_critical_error.dart';
import 'sdk_theme.dart';
import 'starting_route.dart';
import 'workout_activity.dart';
import 'zing_sdk_initializer_platform_interface.dart';

/// An implementation of [ZingSdkInitializerPlatform] that uses method channels.
class MethodChannelZingSdkInitializer extends ZingSdkInitializerPlatform {
  MethodChannelZingSdkInitializer() {
    criticalErrorChannel.setMethodCallHandler(_handleCriticalErrorCall);
    workoutActivityChannel.setMethodCallHandler(_handleWorkoutActivityCall);
  }

  /// Method channel for the workout activity API.
  ///
  /// Dart calls `getPlannedWorkouts`, `getCompletedWorkouts`,
  /// `observePlannedWorkouts` and `observeCompletedWorkouts` (the observe calls
  /// carry a subscription `id`) and `cancelWorkoutActivity` with that `id`.
  /// Native answers each subscription with `onData` (`id`, `data`), `onError`
  /// (`id`, `code`, `message`) and `onDone` (`id`).
  @visibleForTesting
  final workoutActivityChannel =
      const MethodChannel('zing_sdk_initializer/workout_activity');

  final _workoutActivitySubscriptions = <int, StreamController<Object?>>{};
  int _nextWorkoutActivitySubscriptionId = 0;

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('zing_sdk_initializer');

  /// Event channel for receiving auth state updates from native.
  @visibleForTesting
  final authStateEventChannel =
      const EventChannel('zing_sdk_initializer/auth_state');

  /// Method channel for native-to-Dart critical error callbacks.
  @visibleForTesting
  final criticalErrorChannel =
      const MethodChannel('zing_sdk_initializer/critical_error_handler');

  CriticalErrorCallback? _criticalErrorCallback;

  @override
  Future<void> init({
    SdkConfiguration? configuration,
    SdkTheme? theme,
  }) {
    final args = <String, dynamic>{};

    if (configuration != null) {
      args['configuration'] = configuration.toMap();
    }

    if (theme != null) {
      args['theme'] = theme.toMap();
    }

    return methodChannel.invokeMethod<void>('init', args);
  }

  @override
  Future<void> registerBackgroundSetup(Future<void> Function() setup) async {
    // Background sync is Android-only; no-op on other platforms so consumers
    // can call this unconditionally without platform checks.
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final dispatcher =
        PluginUtilities.getCallbackHandle(_zingSdkBackgroundDispatcher);
    final userSetup = PluginUtilities.getCallbackHandle(setup);
    if (dispatcher == null || userSetup == null) {
      throw ArgumentError(
        'registerBackgroundSetup requires a top-level or static function '
        "annotated with @pragma('vm:entry-point').",
      );
    }
    await methodChannel.invokeMethod<void>('registerBackgroundSetup', {
      'dispatcher': dispatcher.toRawHandle(),
      'setup': userSetup.toRawHandle(),
    });
  }

  @override
  Future<void> login(SdkAuthentication authentication) {
    final args = <String, dynamic>{};
    switch (authentication) {
      case SdkPlatformApiKeyAuth(:final ios, :final android, :final partnerUserId):
        final apiKey =
            defaultTargetPlatform == TargetPlatform.iOS ? ios : android;
        args['type'] = 'apiKey';
        args['apiKey'] = apiKey;
        if (partnerUserId != null) {
          args['partnerUserId'] = partnerUserId;
        }
      case SdkExternalTokenAuth(:final jwtToken):
        args['type'] = 'externalToken';
        args['jwtToken'] = jwtToken;
    }

    return methodChannel.invokeMethod<void>('login', args);
  }

  @override
  Future<void> logout() {
    return methodChannel.invokeMethod<void>('logout');
  }

  @override
  Future<void> openScreen(StartingRoute route) {
    return methodChannel.invokeMethod<void>('openScreen', route.toMap());
  }

  @override
  Future<void> setProfileParams(ProfileParams params) {
    return methodChannel.invokeMethod<void>('setProfileParams', params.toMap());
  }

  @override
  Future<void> setPrimaryLocationId(String id) {
    return methodChannel.invokeMethod<void>('setPrimaryLocationID', {'id': id});
  }

  @override
  Future<void> setTheme(SdkTheme theme) {
    return methodChannel.invokeMethod<void>('setTheme', theme.toMap());
  }

  @override
  void setCriticalErrorCallback(CriticalErrorCallback? callback) {
    _criticalErrorCallback = callback;
  }

  Future<void> _handleCriticalErrorCall(MethodCall call) async {
    final callback = _criticalErrorCallback;
    if (callback == null) return;

    if (call.method == 'onCriticalError') {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      callback.onCriticalError(_platformException(args));
    }
  }

  Stream<SdkAuthState>? _authStateStream;

  @override
  Stream<SdkAuthState> get authStateStream {
    return _authStateStream ??=
        authStateEventChannel.receiveBroadcastStream().map((event) {
      return SdkAuthState.fromMap(Map<String, dynamic>.from(event as Map));
    }).asBroadcastStream();
  }

  @override
  Future<List<PlannedWorkout>> getPlannedWorkouts() async {
    final workouts = await workoutActivityChannel
        .invokeListMethod<Object?>('getPlannedWorkouts');
    return _parseWorkouts(workouts, PlannedWorkout.fromMap);
  }

  @override
  Stream<List<PlannedWorkout>> observePlannedWorkouts() {
    return _observeWorkoutActivity(
      'observePlannedWorkouts',
      const {},
      (data) => _parseWorkouts(data, PlannedWorkout.fromMap),
    );
  }

  @override
  Future<List<CompletedWorkout>> getCompletedWorkouts(
    DateTime start,
    DateTime end,
  ) async {
    final workouts = await workoutActivityChannel.invokeListMethod<Object?>(
      'getCompletedWorkouts',
      _intervalArguments(start, end),
    );
    return _parseWorkouts(workouts, CompletedWorkout.fromMap);
  }

  @override
  Stream<List<CompletedWorkout>> observeCompletedWorkouts(
    DateTime start,
    DateTime end,
  ) {
    return _observeWorkoutActivity(
      'observeCompletedWorkouts',
      _intervalArguments(start, end),
      (data) => _parseWorkouts(data, CompletedWorkout.fromMap),
    );
  }

  Map<String, Object?> _intervalArguments(DateTime start, DateTime end) {
    if (end.isBefore(start)) {
      throw ArgumentError('end ($end) must not be before start ($start)');
    }
    return {
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
    };
  }

  List<T> _parseWorkouts<T>(
    Object? workouts,
    T Function(Map<Object?, Object?> map) fromMap,
  ) {
    return [
      for (final workout in (workouts as List<Object?>?) ?? const [])
        fromMap(workout as Map<Object?, Object?>),
    ];
  }

  Stream<T> _observeWorkoutActivity<T>(
    String method,
    Map<String, Object?> arguments,
    T Function(Object? data) parse,
  ) {
    final id = _nextWorkoutActivitySubscriptionId++;
    late final StreamController<Object?> controller;
    controller = StreamController<Object?>(
      onListen: () {
        _workoutActivitySubscriptions[id] = controller;
        workoutActivityChannel
            .invokeMethod<void>(method, {...arguments, 'id': id})
            .catchError((Object error, StackTrace stackTrace) {
          if (_workoutActivitySubscriptions.remove(id) != null) {
            controller.addError(error, stackTrace);
            controller.close();
          }
        });
      },
      onCancel: () async {
        if (_workoutActivitySubscriptions.remove(id) != null) {
          await workoutActivityChannel
              .invokeMethod<void>('cancelWorkoutActivity', {'id': id});
        }
      },
    );
    return controller.stream.map(parse);
  }

  Future<void> _handleWorkoutActivityCall(MethodCall call) async {
    final args = call.arguments as Map;
    final id = args['id'] as int;
    final controller = _workoutActivitySubscriptions[id];
    if (controller == null) return;

    switch (call.method) {
      case 'onData':
        controller.add(args['data']);
      case 'onError':
        _workoutActivitySubscriptions.remove(id);
        controller.addError(_platformException(args));
        await controller.close();
      case 'onDone':
        _workoutActivitySubscriptions.remove(id);
        await controller.close();
    }
  }

  PlatformException _platformException(Map<Object?, Object?> args) {
    return PlatformException(
      code: args['code'] as String,
      message: args['message'] as String?,
    );
  }
}

/// Entry point executed by the native side in a headless background isolate.
@pragma('vm:entry-point')
void _zingSdkBackgroundDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  debugPrint('[ZingBgDispatcher] entered headless isolate');
  const channel = MethodChannel('zing_sdk_initializer/background');
  channel.setMethodCallHandler((call) async {
    if (call.method == 'runSetup') {
      debugPrint('[ZingBgDispatcher] runSetup received');
      final handle = CallbackHandle.fromRawHandle(call.arguments as int);
      final setup =
          PluginUtilities.getCallbackFromHandle(handle) as Future<void>
              Function()?;
      try {
        await setup?.call();
        debugPrint('[ZingBgDispatcher] setup completed');
      } catch (e, st) {
        debugPrint('[ZingBgDispatcher] setup failed: $e\n$st');
        rethrow;
      } finally {
        // Signal native that init finished so the service can proceed with the sync.
        await channel.invokeMethod('done');
      }
    }
    return null;
  });
  // Signal native that the isolate is ready to receive `runSetup`.
  debugPrint('[ZingBgDispatcher] sending ready');
  channel.invokeMethod('ready');
}
