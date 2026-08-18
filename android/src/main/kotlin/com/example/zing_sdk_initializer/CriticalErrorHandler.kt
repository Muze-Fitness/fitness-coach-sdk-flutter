package com.example.zing_sdk_initializer

import coach.zing.fitness.coach.auth.AuthError
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/** Forwards native SDK critical errors to Dart over [channel]. */
class CriticalErrorHandler(
    private val channel: MethodChannel,
    private val scope: CoroutineScope,
) : coach.zing.fitness.coach.CriticalErrorHandler {

    override fun onSessionExpired(error: AuthError) {
        scope.launch {
            channel.invokeMethod(
                "onCriticalError",
                mapOf(
                    "code" to "auth_error",
                    "message" to error.toString(),
                ),
            )
        }
    }
}
