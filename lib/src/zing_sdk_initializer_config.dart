import 'package:flutter/foundation.dart';

/// Configuration data passed to the native Zing SDK initializer.
enum ZingAuthorizationType { guest, client }

@immutable
class ZingSdkInitializerConfig {
  const ZingSdkInitializerConfig({
    this.authToken,
    this.authorizationType = ZingAuthorizationType.guest,
  });

  /// Optional client auth token. When omitted, the SDK stays in guest mode until
  /// it receives a token via [ZingSdkInitializer.updateAuthToken].
  final String? authToken;

  /// Authorization mode for the native SDK.
  final ZingAuthorizationType authorizationType;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'authToken': authToken,
        'authorizationType': authorizationType.name,
      };

  @override
  bool operator ==(Object other) {
    return other is ZingSdkInitializerConfig &&
        other.authToken == authToken &&
        other.authorizationType == authorizationType;
  }

  @override
  int get hashCode => Object.hash(
        authToken,
        authorizationType,
      );
}
