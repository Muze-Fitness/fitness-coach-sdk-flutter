# Zing SDK Initializer

Flutter plugin that wires the native Zing SDK configuration on Android and iOS
through a single Dart-facing API. The plugin takes care of passing auth tokens,
refresh delegates, and logout events to the platform layers.

## Flutter API

```dart
await ZingSdkInitializer.instance.initialize(
  config: const ZingSdkInitializerConfig(
    authToken: maybeAuthToken,
    authorizationType: ZingAuthorizationType.client,
  ),
  onRefreshAuthToken: () async => await fetchFreshToken(),
);

await ZingSdkInitializer.instance.updateAuthToken('token-from-backend');

await ZingSdkInitializer.instance.registerTokenRefreshDelegate(() async {
  // Flutter layer refresh logic (optional)
  return fetchFreshToken();
});

await ZingSdkInitializer.instance.logout();
```

- `ZingSdkInitializerConfig` contains the optional `authToken` and the
  `authorizationType` (defaults to `guest`).
- Passing `onRefreshAuthToken` automatically informs the native SDK that Flutter
  can refresh tokens. The same can be toggled manually via
  `registerTokenRefreshDelegate`.
- `logout()` clears the native SDK state and triggers the platform logout
  delegate.

## Android SDK contract

```kotlin
ZingSdk.init(
    config = ZingSdkConfig(
        authorizationType = AuthorizationType.Client
    ),
    eventListener = { event ->
        // Receive ZingSdkEvent.Initialized or ZingSdkEvent.ConfigUpdated
    },
    exceptionTracker = object : ExceptionTracker {
        override fun track(throwable: Throwable) {
            // Report fatal errors to crash analytics
        }

        override fun log(message: String) {
            // Custom SDK logs
        }
    },
    tokenRefreshDelegate = {
        // Called whenever SDK needs a fresh client token
        "NewGuestToken 1234567890abcdef"
    }
)

ZingSdk.updateAuthToken("token")

ZingSdk.registerTokenRefreshDelegate {
    "New Token"
}

runBlocking {
    val refreshed = ZingSdk.requestFreshAuthToken()
    if (refreshed != null) {
        Log.i("ZingSdk", "Token refreshed: $refreshed")
    }
}
```

Important details:

- Tokens should be provided only through `ZingSdk.updateAuthToken()` or via refresh delegates.

## iOS status

The Flutter plugin ships with stubbed iOS handlers that currently return
`ios_sdk_unavailable` errors. Once the native Zing SDK for iOS is integrated,
replace the TODOs in `ios/Classes/ZingSdkInitializerPlugin.swift` with the real implementation.

## Example app

An example Flutter application is available under `example/`. It showcases:

- Initialization with an optional auth token.
- Registering a token refresh delegate and propagating refresh calls from native to Dart.
- Displaying the Compose-based `WorkoutPlanCard` platform view on Android.
- Triggering `logout()` from Flutter and observing native logs.

To run the demo:

```bash
cd example
flutter pub get
flutter run
```