import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/zing_sdk_initializer_config.dart';
import 'zing_sdk_initializer_platform_interface.dart';

/// An implementation of [ZingSdkInitializerPlatform] that uses method channels.
class MethodChannelZingSdkInitializer extends ZingSdkInitializerPlatform {
  MethodChannelZingSdkInitializer() {
    methodChannel.setMethodCallHandler(_handleNativeCall);
  }

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('zing_sdk_initializer');

  Future<String?> Function()? _refreshTokenHandler;
  bool get _supportsAuthTokenRefresh => _refreshTokenHandler != null;

  @override
  Future<void> initialize({
    required ZingSdkInitializerConfig config,
  }) {
    return methodChannel.invokeMethod<void>('initialize', <String, dynamic>{
      ...config.toMap(),
      'supportsAuthTokenRefresh': _supportsAuthTokenRefresh,
    });
  }

  @override
  void setAuthTokenRefreshHandler(
    Future<String?> Function()? handler,
  ) {
    _refreshTokenHandler = handler;
  }

  @override
  Future<void> updateAuthToken(String token) {
    return methodChannel.invokeMethod<void>(
      'updateAuthToken',
      <String, dynamic>{'token': token},
    );
  }

  @override
  Future<void> logout() {
    return methodChannel.invokeMethod<void>('logout');
  }

  @override
  Future<void> setTokenRefreshSupport(bool isEnabled) {
    return methodChannel.invokeMethod<void>(
      'setTokenRefreshSupport',
      <String, dynamic>{'enabled': isEnabled},
    );
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'refreshAuthToken':
        final handler = _refreshTokenHandler;
        if (handler == null) {
          return null;
        }
        return handler();
      default:
        throw MissingPluginException(
          'ZingSdkInitializer: ${call.method} is not implemented on Dart side.',
        );
    }
  }
}
