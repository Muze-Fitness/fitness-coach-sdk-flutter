import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sdk_auth_state.dart';
import 'sdk_authentication.dart';
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
  Future<void> init(SdkAuthentication auth) {
    final Map<String, dynamic> args;
    switch (auth) {
      case SdkApiKeyAuth(:final apiKey):
        args = {'type': 'apiKey', 'apiKey': apiKey};
      case SdkExternalTokenAuth(:final callback):
        _authTokenCallback = callback;
        _setupAuthTokenCallbackHandler();
        args = {'type': 'externalToken'};
    }
    return methodChannel.invokeMethod<void>('init', args);
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
