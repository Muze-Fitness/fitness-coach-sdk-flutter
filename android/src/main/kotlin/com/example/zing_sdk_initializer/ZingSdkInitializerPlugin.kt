package com.example.zing_sdk_initializer

import android.content.Context
import android.util.Log
import coach.zing.fitness.coach.StartingRoute
import coach.zing.fitness.coach.ZingSdk
import coach.zing.fitness.coach.ZingSdkActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class ZingSdkInitializerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL_NAME = "zing_sdk_initializer"
        private const val PLATFORM_VIEW_TYPE_WORKOUT_PLAN_CARD = "workout-plan-card-view"
        private const val TAG = "ZingSdkInitializer"
        private const val METHOD_INITIALIZE = "initialize"
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
        }
    }

    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        applicationContext = binding.applicationContext
        binding
            .platformViewRegistry
            .registerViewFactory(
                PLATFORM_VIEW_TYPE_WORKOUT_PLAN_CARD,
                WorkoutPlanCardViewFactory()
            )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_INITIALIZE -> handleInitialize(result)
            METHOD_LOGOUT -> handleLogout(result)
            METHOD_OPEN_SCREEN -> handleOpenScreen(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(result: MethodChannel.Result) {
        runCatching {
            ZingSdk.init()
            Log.i(TAG, "Zing SDK initialized")
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

        runCatching {
            ZingSdkActivity.launch(applicationContext, startingRoute)
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
