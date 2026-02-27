import 'dart:async';

/// Callback interface for external token authentication.
///
/// Implementations provide the SDK with a way to obtain and refresh
/// authentication tokens managed by the host application.
abstract interface class AuthTokenCallback {
  /// Returns a valid authentication token for the current user.
  Future<String> getAuthToken();

  /// Called when the SDK detects that the current token is no longer valid.
  void onTokenInvalid();
}

/// Determines how the SDK authenticates with the Zing backend.
sealed class SdkAuthentication {
  const SdkAuthentication();

  /// Authenticate using a static API key.
  const factory SdkAuthentication.apiKey(String apiKey) = SdkApiKeyAuth;

  /// Authenticate using an external token provider.
  const factory SdkAuthentication.externalToken(AuthTokenCallback callback) =
      SdkExternalTokenAuth;
}

/// API-key based authentication.
class SdkApiKeyAuth extends SdkAuthentication {
  const SdkApiKeyAuth(this.apiKey);

  final String apiKey;
}

/// External token authentication delegating to [AuthTokenCallback].
class SdkExternalTokenAuth extends SdkAuthentication {
  const SdkExternalTokenAuth(this.callback);

  final AuthTokenCallback callback;
}
