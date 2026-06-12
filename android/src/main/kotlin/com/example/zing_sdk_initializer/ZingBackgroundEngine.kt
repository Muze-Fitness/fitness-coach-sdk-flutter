package com.example.zing_sdk_initializer

import android.content.Context
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.resume

/**
 * Owns a headless [FlutterEngine] that runs the consumer's registered background setup in a fresh
 * isolate (so `ZingSdk.init` can run when the process is started in the background with no Activity).
 *
 * Holds only the [FlutterEngine]/[MethodChannel] — never a reference to the Service — so the Service
 * can always be garbage-collected after it stops, regardless of lambda capture.
 */
internal class ZingBackgroundEngine {

    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null

    /**
     * Boots the headless engine, runs the registered setup, and suspends until the setup finished
     * (the Dart dispatcher sends `done` after `setup()` returns) or a timeout elapses. By the time
     * this returns, `ZingSdk` has been re-initialized on this live engine.
     */
    suspend fun initAndAwait(context: Context) {
        withContext(Dispatchers.Main) {
            withTimeoutOrNull(SETUP_TIMEOUT_MS) {
                suspendCancellableCoroutine<Unit> { cont -> start(context, cont) }
            }
        }
    }

    private fun start(context: Context, cont: CancellableContinuation<Unit>) {
        val resume = { if (cont.isActive) cont.resume(Unit) }

        if (engine != null) {
            resume()
            return
        }

        val prefs = context.getSharedPreferences(ZingBackgroundPrefs.NAME, Context.MODE_PRIVATE)
        val dispatcherHandle = prefs.getLong(ZingBackgroundPrefs.KEY_DISPATCHER, -1L)
        val setupHandle = prefs.getLong(ZingBackgroundPrefs.KEY_SETUP, -1L)
        if (dispatcherHandle == -1L || setupHandle == -1L) {
            Log.w(TAG, "No background setup registered; skipping headless init.")
            resume()
            return
        }

        val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(dispatcherHandle)
        if (callbackInfo == null) {
            Log.w(TAG, "Background dispatcher handle is no longer valid; skipping headless init.")
            resume()
            return
        }

        val loader = FlutterInjector.instance().flutterLoader().apply {
            startInitialization(context)
            ensureInitializationComplete(context, null)
        }

        val flutterEngine = FlutterEngine(context)
        engine = flutterEngine

        // Mark this engine's plugin instance as background so its handleInit defers to a foreground
        // init (see ZingInitGuard) and never overwrites the live foreground binding.
        (flutterEngine.plugins.get(ZingSdkInitializerPlugin::class.java) as? ZingSdkInitializerPlugin)
            ?.isBackground = true

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKGROUND_CHANNEL)
        channel = methodChannel
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "ready" -> {
                    methodChannel.invokeMethod("runSetup", setupHandle)
                    result.success(null)
                }
                "done" -> {
                    result.success(null)
                    resume()
                }
                else -> result.notImplemented()
            }
        }

        flutterEngine.dartExecutor.executeDartCallback(
            DartExecutor.DartCallback(context.assets, loader.findAppBundlePath(), callbackInfo)
        )
    }

    /** Tears down the engine. Must run on the main thread. */
    fun destroy() {
        channel?.setMethodCallHandler(null)
        channel = null
        engine?.destroy()
        engine = null
    }

    companion object {
        private const val TAG = "ZingBackgroundEngine"
        private const val BACKGROUND_CHANNEL = "zing_sdk_initializer/background"
        private const val SETUP_TIMEOUT_MS = 45_000L
    }
}
