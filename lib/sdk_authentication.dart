/// Determines how the SDK authenticates with the Zing backend.
sealed class SdkAuthentication {
  const SdkAuthentication();

  /// Authenticate using platform-specific API keys.
  ///
  /// Pass [partnerUserId] to link the session to your own user id. If
  /// omitted, the SDK generates an id for a new user.
  const factory SdkAuthentication.apiKey({
    required String ios,
    required String android,
    String? partnerUserId,
  }) = SdkPlatformApiKeyAuth;

  /// Authenticate using a JWT minted by your own backend.
  const factory SdkAuthentication.externalToken(String jwtToken) =
      SdkExternalTokenAuth;
}

/// Platform-specific API-key authentication.
class SdkPlatformApiKeyAuth extends SdkAuthentication {
  const SdkPlatformApiKeyAuth({
    required this.ios,
    required this.android,
    this.partnerUserId,
  });

  final String ios;
  final String android;
  final String? partnerUserId;
}

/// External-token authentication using a JWT minted by your own backend.
class SdkExternalTokenAuth extends SdkAuthentication {
  const SdkExternalTokenAuth(this.jwtToken);

  final String jwtToken;
}
