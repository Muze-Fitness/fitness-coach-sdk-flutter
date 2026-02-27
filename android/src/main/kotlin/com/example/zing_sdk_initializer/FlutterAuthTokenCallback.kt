package com.example.zing_sdk_initializer

import coach.zing.fitness.coach.AuthTokenCallback
import io.flutter.plugin.common.MethodChannel
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

class FlutterAuthTokenCallback(
    private val channel: MethodChannel
) : AuthTokenCallback {

    override suspend fun getAuthToken(): String = suspendCoroutine { continuation ->
        channel.invokeMethod("getAuthToken", null, object : MethodChannel.Result {
            override fun success(result: Any?) {
                continuation.resume(result as String)
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                continuation.resumeWithException(
                    RuntimeException("getAuthToken failed: $errorCode – $errorMessage")
                )
            }

            override fun notImplemented() {
                continuation.resumeWithException(
                    RuntimeException("getAuthToken not implemented on Dart side")
                )
            }
        })
    }

    override fun onTokenInvalid() {
        channel.invokeMethod("onTokenInvalid", null)
    }
}
