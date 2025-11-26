import 'src/zing_sdk_initializer_config.dart';
import 'zing_sdk_initializer_platform_interface.dart';

export 'src/zing_sdk_initializer_config.dart';

/// Public API for initializing the native Zing SDK instances.
class ZingSdkInitializer {
  ZingSdkInitializer._();

  static final ZingSdkInitializer instance = ZingSdkInitializer._();

  bool _isInitialized = false;
  ZingSdkInitializerConfig? _lastConfig;

  /// Initializes the native SDK if needed.
  ///
  Future<void> initialize({
    required ZingSdkInitializerConfig config,
    Future<String?> Function()? onRefreshAuthToken,
  }) async {
    await registerTokenRefreshDelegate(onRefreshAuthToken);

    if (_isInitialized && _lastConfig == config) {
      return;
    }

    await ZingSdkInitializerPlatform.instance.initialize(
      config: config,
    );

    _isInitialized = true;
    _lastConfig = config;
  }

  /// Registers (or removes) the delegate that will be called from native code
  /// when the SDK needs a refreshed client auth token.
  Future<void> registerTokenRefreshDelegate(
    Future<String?> Function()? handler,
  ) async {
    ZingSdkInitializerPlatform.instance
        .setAuthTokenRefreshHandler(handler);
    await ZingSdkInitializerPlatform.instance
        .setTokenRefreshSupport(handler != null);
  }

  /// Updates the current client auth token on the native SDK side.
  Future<void> updateAuthToken(String token) {
    if (token.isEmpty) {
      throw ArgumentError.value(token, 'token', 'Auth token must not be empty');
    }
    return ZingSdkInitializerPlatform.instance.updateAuthToken(token);
  }

  /// Logs out from the native SDK and clears the current auth token state.
  Future<void> logout() {
    return ZingSdkInitializerPlatform.instance.logout();
  }
}
