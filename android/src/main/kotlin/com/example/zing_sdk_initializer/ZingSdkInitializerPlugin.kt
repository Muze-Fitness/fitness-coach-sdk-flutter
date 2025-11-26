package com.example.zing_sdk_initializer

import android.util.Log
import coach.zing.fitness.coach.AuthorizationType
import coach.zing.fitness.coach.ZingSdk
import coach.zing.fitness.coach.ZingSdkConfig
import coach.zing.fitness.coach.auth.AuthTokenRefreshDelegate
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.Locale
import kotlin.coroutines.resume

class ZingSdkInitializerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL_NAME = "zing_sdk_initializer"
        private const val PLATFORM_VIEW_TYPE_WORKOUT_PLAN_CARD = "workout-plan-card-view"
        private const val TAG = "ZingSdkInitializer"
        private const val METHOD_INITIALIZE = "initialize"
        private const val METHOD_UPDATE_AUTH_TOKEN = "updateAuthToken"
        private const val METHOD_SET_TOKEN_REFRESH_SUPPORT = "setTokenRefreshSupport"
        private const val METHOD_LOGOUT = "logout"
        private const val METHOD_REFRESH_AUTH_TOKEN = "refreshAuthToken"
        private const val ARG_TOKEN = "token"
        private const val ARG_ENABLED = "enabled"
        private const val AUTH_TYPE_GUEST = "guest"
        private const val AUTH_TYPE_CLIENT = "client"
    }

    private lateinit var channel: MethodChannel
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val tokenRefreshDelegate = AuthTokenRefreshDelegate {
        requestAuthTokenFromFlutter()
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        binding
            .platformViewRegistry
            .registerViewFactory(
                PLATFORM_VIEW_TYPE_WORKOUT_PLAN_CARD,
                WorkoutPlanCardViewFactory(binding.binaryMessenger)
            )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        updateTokenRefreshDelegate(false)
        scope.cancel()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_INITIALIZE -> handleInitialize(call, result)
            METHOD_UPDATE_AUTH_TOKEN -> handleUpdateAuthToken(call, result)
            METHOD_SET_TOKEN_REFRESH_SUPPORT -> handleSetTokenRefreshSupport(call, result)
            METHOD_LOGOUT -> handleLogout(result)
            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(call: MethodCall, result: MethodChannel.Result) {
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any?> ?: run {
            result.error("invalid_args", "Expected argument map", null)
            return
        }

        val authToken = (args["authToken"] as? String).takeUnless { it.isNullOrBlank() }
        val rawAuthorizationType = (args["authorizationType"] as? String)?.trim()
        val authorizationType = rawAuthorizationType
            ?.let { parseAuthorizationType(it) }
            ?: AuthorizationType.Guest
        if (rawAuthorizationType != null &&
            authorizationType == AuthorizationType.Guest &&
            !rawAuthorizationType.equals(AUTH_TYPE_GUEST, ignoreCase = true)
        ) {
            Log.w(TAG, "Unknown authorizationType=$rawAuthorizationType, defaulting to guest mode")
        }

        val supportsAuthTokenRefresh = args["supportsAuthTokenRefresh"] as? Boolean ?: false
        updateTokenRefreshDelegate(supportsAuthTokenRefresh)

        runCatching {
            val config = ZingSdkConfig(
                authorizationType = authorizationType
            )
            ZingSdk.init(config)
            Log.i(TAG, "Zing SDK initialized")

            authToken?.let {
                ZingSdk.updateAuthToken(it)
                Log.i(TAG, "Zing SDK auth token updated")
            }

            result.success(mapOf("status" to "initialized"))
        }.onFailure { throwable ->
            Log.e(TAG, "Failed to initialize Zing SDK", throwable)
            result.error(
                "native_init_failed",
                throwable.message,
                Log.getStackTraceString(throwable)
            )
        }
    }

    private fun handleUpdateAuthToken(call: MethodCall, result: MethodChannel.Result) {
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any?>
        val token = args?.get(ARG_TOKEN) as? String
        if (token.isNullOrBlank()) {
            result.error("invalid_args", "token must not be blank", null)
            return
        }

        runCatching {
            ZingSdk.updateAuthToken(token)
            result.success(null)
        }.onFailure { throwable ->
            Log.e(TAG, "Failed to update auth token", throwable)
            result.error(
                "update_auth_token_failed",
                throwable.message,
                Log.getStackTraceString(throwable)
            )
        }
    }

    private fun handleSetTokenRefreshSupport(call: MethodCall, result: MethodChannel.Result) {
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any?>
        val enabled = args?.get(ARG_ENABLED) as? Boolean
        if (enabled == null) {
            result.error("invalid_args", "enabled flag is required", null)
            return
        }
        updateTokenRefreshDelegate(enabled)
        result.success(null)
    }

    private fun handleLogout(result: MethodChannel.Result) {
        scope.launch {
            runCatching {
                ZingSdk.logout()
                result.success(null)
            }.onFailure { throwable ->
                Log.e(TAG, "Failed to logout Zing SDK", throwable)
                result.error(
                    "logout_failed",
                    throwable.message,
                    Log.getStackTraceString(throwable)
                )
            }
        }
    }

    private fun updateTokenRefreshDelegate(enable: Boolean) {
        if (enable) {
            ZingSdk.registerTokenRefreshDelegate(tokenRefreshDelegate)
        } else {
            ZingSdk.registerTokenRefreshDelegate(null)
        }
    }

    private suspend fun requestAuthTokenFromFlutter(): String? {
        return suspendCancellableCoroutine { continuation ->
            if (!::channel.isInitialized) {
                continuation.resume(null)
                return@suspendCancellableCoroutine
            }

            channel.invokeMethod(
                METHOD_REFRESH_AUTH_TOKEN,
                null,
                object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        if (continuation.isActive) {
                            continuation.resume(result as? String)
                        }
                    }

                    override fun error(
                        errorCode: String,
                        errorMessage: String?,
                        errorDetails: Any?
                    ) {
                        Log.e(TAG, "refreshAuthToken failed: $errorCode $errorMessage")
                        if (continuation.isActive) {
                            continuation.resume(null)
                        }
                    }

                    override fun notImplemented() {
                        Log.w(TAG, "refreshAuthToken not implemented on Dart side")
                        if (continuation.isActive) {
                            continuation.resume(null)
                        }
                    }
                }
            )
        }
    }
    private fun parseAuthorizationType(raw: String): AuthorizationType? {
        return when (raw.trim().lowercase(Locale.US)) {
            AUTH_TYPE_GUEST -> AuthorizationType.Guest
            AUTH_TYPE_CLIENT -> AuthorizationType.Client
            else -> null
        }
    }
}
