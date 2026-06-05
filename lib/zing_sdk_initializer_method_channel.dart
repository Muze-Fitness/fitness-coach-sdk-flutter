import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'sdk_auth_state.dart';
import 'sdk_authentication.dart';
import 'sdk_configuration.dart';
import 'sdk_theme.dart';
import 'starting_route.dart';
import 'zing_sdk_initializer_platform_interface.dart';

/// An implementation of [ZingSdkInitializerPlatform] that uses method channels.
class MethodChannelZingSdkInitializer extends ZingSdkInitializerPlatform {
  MethodChannelZingSdkInitializer();

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('zing_sdk_initializer');

  /// Event channel for receiving auth state updates from native.
  @visibleForTesting
  final authStateEventChannel =
      const EventChannel('zing_sdk_initializer/auth_state');

  /// Reverse method channel for native-to-Dart token callbacks.
  @visibleForTesting
  final authTokenCallbackChannel =
      const MethodChannel('zing_sdk_initializer/auth_token_callback');

  AuthTokenCallback? _authTokenCallback;

  @override
  Future<void> init({
    required SdkAuthentication authentication,
    SdkConfiguration? configuration,
    SdkTheme? theme,
  }) {
    final args = <String, dynamic>{};
    switch (authentication) {
      case SdkPlatformApiKeyAuth(:final ios, :final android):
        final apiKey =
            defaultTargetPlatform == TargetPlatform.iOS ? ios : android;
        args['type'] = 'apiKey';
        args['apiKey'] = apiKey;
      case SdkExternalTokenAuth(:final callback):
        _authTokenCallback = callback;
        _setupAuthTokenCallbackHandler();
        args['type'] = 'externalToken';
    }

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
  Future<void> login() {
    return methodChannel.invokeMethod<void>('login');
  }

  @override
  Future<void> logout() {
    return methodChannel.invokeMethod<void>('logout');
  }

  @override
  Future<void> openScreen(StartingRoute route) {
    return methodChannel.invokeMethod<void>('openScreen', route.toMap());
  }

  Stream<SdkAuthState>? _authStateStream;

  @override
  Stream<SdkAuthState> get authStateStream {
    return _authStateStream ??=
        authStateEventChannel.receiveBroadcastStream().map((event) {
      return SdkAuthState.fromMap(Map<String, dynamic>.from(event as Map));
    }).asBroadcastStream();
  }

  void _setupAuthTokenCallbackHandler() {
    authTokenCallbackChannel.setMethodCallHandler((call) async {
      final callback = _authTokenCallback;
      if (callback == null) return null;

      switch (call.method) {
        case 'getAuthToken':
          return await callback.getAuthToken();
        case 'onTokenInvalid':
          callback.onTokenInvalid();
          return null;
        default:
          return null;
      }
    });
  }
}

/// Entry point executed by the native side in a headless background isolate.
///
/// Owned by the SDK (the consumer never references it). It looks up the
/// consumer's registered setup function by its callback handle and runs it.
@pragma('vm:entry-point')
void _zingSdkBackgroundDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('zing_sdk_initializer/background');
  channel.setMethodCallHandler((call) async {
    if (call.method == 'runSetup') {
      final handle = CallbackHandle.fromRawHandle(call.arguments as int);
      final setup =
          PluginUtilities.getCallbackFromHandle(handle) as Future<void>
              Function()?;
      await setup?.call();
    }
    return null;
  });
  // Signal native that the isolate is ready to receive `runSetup`.
  channel.invokeMethod('ready');
}
