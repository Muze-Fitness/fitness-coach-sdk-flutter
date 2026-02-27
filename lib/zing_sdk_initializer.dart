import 'sdk_auth_state.dart';
import 'sdk_authentication.dart';
import 'starting_route.dart';
import 'zing_sdk_initializer_platform_interface.dart';

export 'sdk_auth_state.dart';
export 'sdk_authentication.dart';
export 'starting_route.dart';
export 'workout_plan_card_view.dart';

/// Public API for initializing and interacting with the native Zing SDK.
class ZingSdk {
  ZingSdk._();

  static final ZingSdk instance = ZingSdk._();

  /// Initializes the native SDK with the given authentication configuration.
  Future<void> init(SdkAuthentication auth) {
    return ZingSdkInitializerPlatform.instance.init(auth);
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
