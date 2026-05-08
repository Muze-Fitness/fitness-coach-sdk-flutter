package com.example.zing_sdk_initializer

import android.content.Context
import android.graphics.Typeface
import android.util.Log
import androidx.core.content.res.ResourcesCompat
import coach.zing.fitness.coach.CoachesAvailability
import coach.zing.fitness.coach.Configuration
import coach.zing.fitness.coach.GenderAvailability
import coach.zing.fitness.coach.SdkAuthentication
import coach.zing.fitness.coach.StartingRoute
import coach.zing.fitness.coach.ZingSdk
import coach.zing.fitness.coach.ZingSdkActivity
import coach.zing.fitness.coach.ZingSdkTheme
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
        private const val TAG = "ZingSdkInitializer"
        private const val METHOD_INIT = "init"
        private const val METHOD_LOGIN = "login"
        private const val METHOD_LOGOUT = "logout"
        private const val METHOD_OPEN_SCREEN = "openScreen"
        private const val ARG_ROUTE = "route"

        private object RouteKeys {
            const val HOME = "home"
            const val CUSTOM_WORKOUT = "custom_workout"
            const val AI_ASSISTANT = "ai_assistant"
            const val WORKOUT_PLAN_DETAILS = "workout_plan_details"
            const val FULL_SCHEDULE = "full_schedule"
            const val PROFILE_SETTINGS = "profile_settings"
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
        scope.launch {
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

                val themeMap = call.argument<Map<String, Any>>("theme")
                val theme = buildTheme(themeMap)

                val configMap = call.argument<Map<String, Any>>("configuration")
                val configuration = configMap?.let { buildConfiguration(it) }

                ZingSdk.init(auth, theme, configuration)
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
            RouteKeys.HOME -> StartingRoute.Home
            RouteKeys.CUSTOM_WORKOUT -> StartingRoute.CustomWorkout
            RouteKeys.AI_ASSISTANT -> StartingRoute.AiAssistant
            RouteKeys.WORKOUT_PLAN_DETAILS -> StartingRoute.WorkoutPlanDetails
            RouteKeys.FULL_SCHEDULE -> StartingRoute.FullSchedule
            RouteKeys.PROFILE_SETTINGS -> StartingRoute.ProfileSettings
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

    private fun buildTheme(themeMap: Map<String, Any>?): ZingSdkTheme? {
        val colors = themeMap?.let { buildColors(it) }
        val typography = themeMap?.let { buildTypography(it) }
        val assets = buildAssets()
        val cornerRadius = themeMap?.let { buildCornerRadius(it) }
        if (colors == null && typography == null && assets == null && cornerRadius == null) return null
        return ZingSdkTheme(
            colors = colors,
            typography = typography,
            assets = assets,
            cornerRadius = cornerRadius,
        )
    }

    @Suppress("UNCHECKED_CAST")
    private fun buildColors(themeMap: Map<String, Any>): ZingSdkTheme.Colors? {
        val colorsMap = themeMap["colors"] as? Map<String, Any> ?: return null
        fun color(key: String): Long? = (colorsMap[key] as? Number)?.toLong()
        return ZingSdkTheme.Colors(
            brandPrimary = color("brand/primary"),
            brandSecondary = color("brand/secondary"),
            textHeadingDarkPrimary = color("text/heading/dark-primary"),
            textHeadingLightPrimary = color("text/heading/light-primary"),
            textBodyDarkPrimary = color("text/body/dark-primary"),
            textBodyDarkSecondary = color("text/body/dark-secondary"),
            buttonPrimary = color("button/primary"),
            buttonSecondary = color("button/secondary"),
            bgPrimary = color("bg/primary"),
            bgSecondary = color("bg/secondary"),
        )
    }

    @Suppress("UNCHECKED_CAST")
    private fun buildTypography(themeMap: Map<String, Any>): ZingSdkTheme.Typography? {
        val typographyMap = themeMap["typography"] as? Map<String, Any> ?: return null
        val context = activityContext ?: return null
        val system = (typographyMap["system"] as? String)?.let { loadFont(context, it) }
        val brand = (typographyMap["brand"] as? String)?.let { loadFont(context, it) }
        if (system == null && brand == null) return null
        return ZingSdkTheme.Typography(system = system, brand = brand)
    }

    private fun loadFont(context: Context, fontName: String): Typeface? {
        val resId = context.resources.getIdentifier(fontName, "font", context.packageName)
        if (resId == 0) {
            Log.w(TAG, "Font not found in host res/font: $fontName")
            return null
        }
        return ResourcesCompat.getFont(context, resId)
    }

    private fun buildAssets(): ZingSdkTheme.Assets? {
        val context = activityContext ?: return null

        fun drawable(name: String): Int? {
            val id = context.resources.getIdentifier(name, "drawable", context.packageName)
            return if (id != 0) id else null
        }

        val planBackground = drawable("zing_plan_background")
        val welcomePicture = drawable("zing_welcome_picture")
        val coachAsset = ZingSdkTheme.Assets.CoachAsset(
            john = drawable("zing_coach_john"),
            jennifer = drawable("zing_coach_jennifer"),
            sarah = drawable("zing_coach_sarah"),
            chris = drawable("zing_coach_chris"),
        )
        val hasCoach = coachAsset.john != null || coachAsset.jennifer != null ||
                coachAsset.sarah != null || coachAsset.chris != null

        if (planBackground == null && welcomePicture == null && !hasCoach) return null
        return ZingSdkTheme.Assets(
            planBackground = planBackground,
            welcomePicture = welcomePicture,
            coachImages = if (hasCoach) coachAsset else null,
        )
    }

    @Suppress("UNCHECKED_CAST")
    private fun buildCornerRadius(themeMap: Map<String, Any>): ZingSdkTheme.CornerRadius? {
        val cornerMap = themeMap["cornersRounding"] as? Map<String, Any> ?: return null
        val buttonMap = cornerMap["button/border"] as? Map<String, Any> ?: return null
        val sdkRadius = when (buttonMap["type"] as? String) {
            "pill" -> ZingSdkTheme.CornerRadius.SdkRadius.Pill
            "value" -> {
                val value = (buttonMap["value"] as? Number)?.toInt() ?: 0
                ZingSdkTheme.CornerRadius.SdkRadius.Value(value)
            }
            else -> return null
        }
        return ZingSdkTheme.CornerRadius(button = sdkRadius)
    }

    private fun buildConfiguration(configMap: Map<String, Any>): Configuration {
        val coachesAvailability = when (configMap["coachesAvailability"] as? String) {
            "allCoaches" -> CoachesAvailability.ALL_COACHES
            "userGenderBased" -> CoachesAvailability.USER_GENDER_BASED
            else -> null
        }
        val genderAvailability = when (configMap["genderAvailability"] as? String) {
            "all" -> GenderAvailability.ALL
            "binary" -> GenderAvailability.BINARY
            else -> null
        }
        return Configuration(
            coachesAvailability = coachesAvailability,
            genderAvailability = genderAvailability,
        )
    }
}
