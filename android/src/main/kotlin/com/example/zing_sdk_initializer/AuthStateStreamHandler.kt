package com.example.zing_sdk_initializer

import coach.zing.fitness.coach.SdkAuthState
import coach.zing.fitness.coach.ZingSdk
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

class AuthStateStreamHandler(
    private val scope: CoroutineScope
) : EventChannel.StreamHandler {

    private var job: Job? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        job = scope.launch {
            ZingSdk.authState.collect { state ->
                val map = when (state) {
                    is SdkAuthState.LoggedOut -> mapOf("state" to "loggedOut")
                    is SdkAuthState.InProgress -> mapOf("state" to "inProgress")
                    is SdkAuthState.Error -> mapOf("state" to "error")
                    is SdkAuthState.Authenticated -> mapOf(
                        "state" to "authenticated",
                        "partnerUserId" to state.partnerUserId
                    )
                }
                events.success(map)
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        job?.cancel()
        job = null
    }
}
