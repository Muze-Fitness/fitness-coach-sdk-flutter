package com.example.zing_sdk_initializer

import android.content.Context
import android.util.Log
import coach.zing.fitness.coach.SdkAuthentication
import coach.zing.fitness.coach.StartingRoute
import coach.zing.fitness.coach.ZingSdk
import coach.zing.fitness.coach.ZingSdkActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class ZingSdkInitializerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    companion object {
        private const val CHANNEL_NAME = "zing_sdk_initializer"
        private const val AUTH_STATE_CHANNEL_NAME = "zing_sdk_initializer/auth_state"
        private const val AUTH_TOKEN_CALLBACK_CHANNEL_NAME =
            "zing_sdk_initializer/auth_token_callback"
        private const val PLATFORM_VIEW_TYPE_WORKOUT_PLAN_CARD = "workout-plan-card-view"
        private const val TAG = "ZingSdkInitializer"
        private const val METHOD_INIT = "init"
        private const val METHOD_LOGIN = "login"
        private const val METHOD_LOGOUT = "logout"
        private const val METHOD_OPEN_SCREEN = "openScreen"
        private const val ARG_ROUTE = "route"

        private object RouteKeys {
            const val CUSTOM_WORKOUT = "custom_workout"
            const val AI_ASSISTANT = "ai_assistant"
            const val WORKOUT_PLAN_DETAILS = "workout_plan_details"
            const val FULL_SCHEDULE = "full_schedule"
            const val PROFILE_SETTINGS = "profile_settings"
            const val HEALTH_CONNECT_PERMISSIONS = "health_connect_permissions"
            const val WORKOUT_PREVIEW = "workout_preview"
            const val WORKOUT_RESULT = "workout_result"
        }
    }

    private lateinit var channel: MethodChannel
    private lateinit var authStateEventChannel: EventChannel
    private lateinit var authTokenCallbackChannel: MethodChannel
    private var activityContext: Context? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)

        authStateEventChannel = EventChannel(binding.binaryMessenger, AUTH_STATE_CHANNEL_NAME)
        authStateEventChannel.setStreamHandler(AuthStateStreamHandler(scope))

        authTokenCallbackChannel =
            MethodChannel(binding.binaryMessenger, AUTH_TOKEN_CALLBACK_CHANNEL_NAME)

        binding
            .platformViewRegistry
            .registerViewFactory(
                PLATFORM_VIEW_TYPE_WORKOUT_PLAN_CARD,
                WorkoutPlanCardViewFactory()
            )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        authStateEventChannel.setStreamHandler(null)
        scope.cancel()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_INIT -> handleInit(call, result)
            METHOD_LOGIN -> handleLogin(result)
            METHOD_LOGOUT -> handleLogout(result)
            METHOD_OPEN_SCREEN -> handleOpenScreen(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleInit(call: MethodCall, result: MethodChannel.Result) {
        runCatching {
            val type = call.argument<String>("type")
            val auth = when (type) {
                "apiKey" -> {
                    val apiKey = call.argument<String>("apiKey")
                        ?: throw IllegalArgumentException("apiKey is required")
                    SdkAuthentication.ApiKey(apiKey = apiKey)
                }

                "externalToken" -> {
                    SdkAuthentication.ExternalToken(
                        authTokenCallback = FlutterAuthTokenCallback(authTokenCallbackChannel)
                    )
                }

                else -> throw IllegalArgumentException("Unknown auth type: $type")
            }
            ZingSdk.init(auth)
            Log.i(TAG, "Zing SDK initialized with auth type: $type")
            result.success(null)
        }.onFailure { throwable ->
            Log.e(TAG, "Failed to initialize Zing SDK", throwable)
            result.error(
                "native_init_failed",
                throwable.message,
                Log.getStackTraceString(throwable)
            )
        }
    }

    private fun handleLogin(result: MethodChannel.Result) {
        scope.launch {
            runCatching {
                ZingSdk.login()
                Log.i(TAG, "Zing SDK login")
                result.success(null)
            }.onFailure { throwable ->
                Log.e(TAG, "Failed to login Zing SDK", throwable)
                result.error(
                    "login_failed",
                    throwable.message,
                    Log.getStackTraceString(throwable)
                )
            }
        }
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

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityContext = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityContext = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityContext = binding.activity
    }

    override fun onDetachedFromActivity() {
        activityContext = null
    }

    private fun handleOpenScreen(call: MethodCall, result: MethodChannel.Result) {
        val routeKey = call.argument<String>(ARG_ROUTE)
        if (routeKey.isNullOrBlank()) {
            result.error("missing_route", "Route argument is required", null)
            return
        }

        val startingRoute = when (routeKey) {
            RouteKeys.CUSTOM_WORKOUT -> StartingRoute.CustomWorkout
            RouteKeys.AI_ASSISTANT -> StartingRoute.AiAssistant
            RouteKeys.WORKOUT_PLAN_DETAILS -> StartingRoute.WorkoutPlanDetails
            RouteKeys.FULL_SCHEDULE -> StartingRoute.FullSchedule
            RouteKeys.PROFILE_SETTINGS -> StartingRoute.ProfileSettings
            RouteKeys.HEALTH_CONNECT_PERMISSIONS -> StartingRoute.HealthConnectPermissions
            RouteKeys.WORKOUT_PREVIEW -> {
                val workoutId = call.argument<String>("workoutId")
                    ?: run {
                        result.error("missing_arg", "workoutId is required", null)
                        return
                    }
                StartingRoute.WorkoutPreview(workoutId)
            }

            RouteKeys.WORKOUT_RESULT -> {
                val workoutResultId = call.argument<String>("workoutResultId")
                    ?: run {
                        result.error("missing_arg", "workoutResultId is required", null)
                        return
                    }
                StartingRoute.WorkoutResult(workoutResultId)
            }

            else -> null
        }

        if (startingRoute == null) {
            result.error(
                "unknown_route",
                "Route $routeKey is not supported",
                null
            )
            return
        }

        val context = activityContext
        if (context == null) {
            result.error("no_activity", "No activity context available", null)
            return
        }

        runCatching {
            ZingSdkActivity.launch(context, startingRoute)
            result.success(null)
        }.onFailure { throwable ->
            Log.e(TAG, "Failed to launch route $routeKey", throwable)
            result.error(
                "launch_failed",
                throwable.message,
                Log.getStackTraceString(throwable)
            )
        }
    }
}
