import 'package:flutter/services.dart';

/// Receives critical SDK errors pushed from the native side.
///
/// The error arrives as a [PlatformException] whose `code` identifies the
/// failure and whose `message` describes the underlying native error.
///
/// Codes:
/// - `auth_error` — the session could not be refreshed and is unrecoverable.
/// - `unknown` — unknown critical error.
abstract interface class CriticalErrorCallback {
  void onCriticalError(PlatformException error);
}
