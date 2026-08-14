/// Represents the current authentication state of the Zing SDK.
sealed class SdkAuthState {
  const SdkAuthState();

  factory SdkAuthState.fromMap(Map<String, dynamic> map) {
    return switch (map['state'] as String) {
      'loggedOut' => const SdkAuthStateLoggedOut(),
      'inProgress' => const SdkAuthStateInProgress(),
      'authenticated' =>
        SdkAuthStateAuthenticated(map['userId'] as String),
      _ => throw ArgumentError('Unknown auth state: ${map['state']}'),
    };
  }
}

/// The user is not authenticated.
class SdkAuthStateLoggedOut extends SdkAuthState {
  const SdkAuthStateLoggedOut();

  @override
  bool operator ==(Object other) => other is SdkAuthStateLoggedOut;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SdkAuthState.loggedOut';
}

/// Authentication is in progress.
class SdkAuthStateInProgress extends SdkAuthState {
  const SdkAuthStateInProgress();

  @override
  bool operator ==(Object other) => other is SdkAuthStateInProgress;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SdkAuthState.inProgress';
}

/// The user is authenticated.
///
/// [userId] is the authenticated user's id — for [SdkAuthentication.apiKey]
/// this is `partnerUserId` (or the SDK-generated id, if omitted); for
/// [SdkAuthentication.externalToken] this is the `sub` claim of the JWT.
class SdkAuthStateAuthenticated extends SdkAuthState {
  const SdkAuthStateAuthenticated(this.userId);

  final String userId;

  @override
  bool operator ==(Object other) =>
      other is SdkAuthStateAuthenticated && other.userId == userId;

  @override
  int get hashCode => Object.hash(runtimeType, userId);

  @override
  String toString() => 'SdkAuthState.authenticated(userId: $userId)';
}
