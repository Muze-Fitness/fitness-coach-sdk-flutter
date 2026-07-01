import 'sdk_auth_state.dart';
import 'sdk_authentication.dart';
import 'sdk_configuration.dart';
import 'sdk_theme.dart';
import 'starting_route.dart';
import 'zing_sdk_initializer_platform_interface.dart';

export 'sdk_auth_state.dart';
export 'sdk_authentication.dart';
export 'sdk_configuration.dart';
export 'sdk_theme.dart';
export 'starting_route.dart';

/// Public API for initializing and interacting with the native Zing SDK.
class ZingSdk {
  ZingSdk._();

  static final ZingSdk instance = ZingSdk._();

  /// Initializes the native SDK with the given authentication and optional
  /// [configuration] and [theme].
  Future<void> init({
    required SdkAuthentication authentication,
    SdkConfiguration? configuration,
    SdkTheme? theme,
  }) {
    return ZingSdkInitializerPlatform.instance.init(
      authentication: authentication,
      configuration: configuration,
      theme: theme,
    );
  }

  /// Registers the entry point that re-initializes the SDK in a headless
  /// background isolate (used for Health Connect background sync when the app
  /// is launched in the background without an Activity).
  ///
  /// [setup] MUST be a top-level or static function annotated with
  /// `@pragma('vm:entry-point')`. It should call [init] (the same way you do on
  /// app startup). Call this once during normal app startup, e.g. in `main()`.
  Future<void> registerBackgroundSetup(Future<void> Function() setup) {
    return ZingSdkInitializerPlatform.instance.registerBackgroundSetup(setup);
  }

  /// Triggers the login flow in the native SDK.
  Future<void> login() {
    return ZingSdkInitializerPlatform.instance.login();
  }

  /// Logs out from the native SDK.
  Future<void> logout() {
    return ZingSdkInitializerPlatform.instance.logout();
  }

  /// Opens one of the predefined SDK screens.
  Future<void> openScreen(StartingRoute route) {
    return ZingSdkInitializerPlatform.instance.openScreen(route);
  }

  /// Stream of authentication state changes from the native SDK.
  Stream<SdkAuthState> get authState {
    return ZingSdkInitializerPlatform.instance.authStateStream;
  }
}
