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
import 'zing_sdk_initializer_platform_interface.dart';

/// An implementation of [ZingSdkInitializerPlatform] that uses method channels.
class MethodChannelZingSdkInitializer extends ZingSdkInitializerPlatform {
  MethodChannelZingSdkInitializer() {
    criticalErrorChannel.setMethodCallHandler(_handleCriticalErrorCall);
  }

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
  void setCriticalErrorCallback(CriticalErrorCallback? callback) {
    _criticalErrorCallback = callback;
  }

  Future<void> _handleCriticalErrorCall(MethodCall call) async {
    final callback = _criticalErrorCallback;
    if (callback == null) return;

    if (call.method == 'onCriticalError') {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      callback.onCriticalError(PlatformException(
        code: args['code'] as String,
        message: args['message'] as String?,
      ));
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
