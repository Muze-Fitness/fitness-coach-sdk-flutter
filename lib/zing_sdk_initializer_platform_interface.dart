import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/zing_sdk_initializer_config.dart';
import 'zing_sdk_initializer_method_channel.dart';

abstract class ZingSdkInitializerPlatform extends PlatformInterface {
  /// Constructs a ZingSdkInitializerPlatform.
  ZingSdkInitializerPlatform() : super(token: _token);

  static final Object _token = Object();

  static ZingSdkInitializerPlatform _instance =
      MethodChannelZingSdkInitializer();

  /// The default instance of [ZingSdkInitializerPlatform] to use.
  ///
  /// Defaults to [MethodChannelZingSdkInitializer].
  static ZingSdkInitializerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ZingSdkInitializerPlatform] when
  /// they register themselves.
  static set instance(ZingSdkInitializerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> initialize({
    required ZingSdkInitializerConfig config,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> updateAuthToken(String token) {
    throw UnimplementedError('updateAuthToken() has not been implemented.');
  }

  Future<void> logout() {
    throw UnimplementedError('logout() has not been implemented.');
  }

  Future<void> setTokenRefreshSupport(bool isEnabled) {
    throw UnimplementedError(
      'setTokenRefreshSupport() has not been implemented.',
    );
  }

  void setAuthTokenRefreshHandler(
    Future<String?> Function()? handler,
  ) {
    throw UnimplementedError(
      'setAuthTokenRefreshHandler() has not been implemented.',
    );
  }
}
