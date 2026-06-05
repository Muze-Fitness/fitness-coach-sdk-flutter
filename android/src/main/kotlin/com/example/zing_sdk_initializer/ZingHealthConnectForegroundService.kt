package com.example.zing_sdk_initializer

import android.content.Context
import android.util.Log
import coach.zing.fitness.coach.service.ZingSdkHCForegroundService
import dagger.hilt.android.AndroidEntryPoint
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Flutter Health Connect background sync service.
 *
 * Extends the SDK's [ZingSdkHCForegroundService] and overrides [onPrepareSdk] to boot a headless
 * [FlutterEngine] that runs the consumer's registered background setup function (which calls
 * `ZingSdk.instance.init(...)`). The base service then waits for the SDK to become logged in and
 * performs the sync. The engine is kept alive until the service stops so that the auth token
 * callback channel stays available during the sync.
 */
@AndroidEntryPoint
class ZingHealthConnectForegroundService : ZingSdkHCForegroundService() {

    private var backgroundEngine: FlutterEngine? = null

    override suspend fun onPrepareSdk() {
        // Engine creation / Dart execution must happen on the main thread.
        withContext(Dispatchers.Main) {
            startHeadlessSetup()
        }
    }

    private fun startHeadlessSetup() {
        if (backgroundEngine != null) return // single-flight within this service instance

        val prefs = getSharedPreferences(ZingBackgroundPrefs.NAME, Context.MODE_PRIVATE)
        val dispatcherHandle = prefs.getLong(ZingBackgroundPrefs.KEY_DISPATCHER, -1L)
        val setupHandle = prefs.getLong(ZingBackgroundPrefs.KEY_SETUP, -1L)
        if (dispatcherHandle == -1L || setupHandle == -1L) {
            Log.w(TAG, "No background setup registered; skipping headless init.")
            return
        }

        val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(dispatcherHandle)
        if (callbackInfo == null) {
            // Handle invalidated (e.g. app updated) — re-registration happens on next foreground launch.
            Log.w(TAG, "Background dispatcher handle is no longer valid; skipping headless init.")
            return
        }

        val loader = FlutterInjector.instance().flutterLoader().apply {
            startInitialization(applicationContext)
            ensureInitializationComplete(applicationContext, null)
        }

        val engine = FlutterEngine(applicationContext)
        backgroundEngine = engine

        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, BACKGROUND_CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "ready" -> {
                    channel.invokeMethod("runSetup", setupHandle)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        engine.dartExecutor.executeDartCallback(
            DartExecutor.DartCallback(assets, loader.findAppBundlePath(), callbackInfo)
        )
    }

    override fun onDestroy() {
        backgroundEngine?.destroy()
        backgroundEngine = null
        super.onDestroy()
    }

    companion object {
        private const val TAG = "ZingHcBgService"
        private const val BACKGROUND_CHANNEL = "zing_sdk_initializer/background"
    }
}
