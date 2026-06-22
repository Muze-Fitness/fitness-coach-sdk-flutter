package com.example.zing_sdk_initializer.engine

import android.content.Context
import android.util.Log
import com.example.zing_sdk_initializer.ZingSdkInitializerPlugin
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation

/** Real headless [Engine] backed by a [FlutterEngine]. */
internal class RealFlutterEngine(
    private val flutterEngine: FlutterEngine,
    private val channel: MethodChannel,
    private val dartCallback: DartExecutor.DartCallback,
) : Engine {

    override fun start() {
        flutterEngine.dartExecutor.executeDartCallback(dartCallback)
    }

    override fun destroy() {
        channel.setMethodCallHandler(null)
        flutterEngine.destroy()
    }
}

internal class RealFlutterEngineFactory(
    private val appContext: Context,
) : EngineFactory {

    override suspend fun create(): Engine? {
        val prefs = appContext.getSharedPreferences(ZingBackgroundPrefs.NAME, Context.MODE_PRIVATE)
        val dispatcherHandle = prefs.getLong(ZingBackgroundPrefs.KEY_DISPATCHER, -1L)
        val setupHandle = prefs.getLong(ZingBackgroundPrefs.KEY_SETUP, -1L)
        if (dispatcherHandle == -1L || setupHandle == -1L) {
            // registerBackgroundSetup was never called — init won't happen, awaitSdkAuthentication
            // will hit the withTimeout on the SDK side.
            Log.w(TAG, "create: no background handles (registerBackgroundSetup not called?)")
            return null
        }

        // On a cold (background/restored) start libflutter.so is not loaded yet and FlutterJNI is
        // not registered, so lookupCallbackInformation would crash. Initialize the loader first.
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(appContext)
        loader.ensureInitializationComplete(appContext, null)

        val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(dispatcherHandle)
        if (callbackInfo == null) {
            Log.w(TAG, "create: callback info not found for dispatcher=$dispatcherHandle")
            return null
        }

        Log.i(TAG, "create: building headless FlutterEngine (dispatcher=$dispatcherHandle, setup=$setupHandle)")
        val flutterEngine = FlutterEngine(appContext)
        (flutterEngine.plugins.get(ZingSdkInitializerPlugin::class.java) as? ZingSdkInitializerPlugin)
            ?.isBackground = true

        // setup → ZingSdk.init → republishes _sdkAuth (rebinds it to this engine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKGROUND_CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "ready" -> {
                    channel.invokeMethod("runSetup", setupHandle)
                    result.success(null)
                }

                "done" -> result.success(null)
                else -> result.notImplemented()
            }
        }

        val dartCallback = DartExecutor.DartCallback(
            appContext.assets,
            loader.findAppBundlePath(),
            callbackInfo,
        )
        return RealFlutterEngine(flutterEngine, channel, dartCallback)
    }

    private companion object {
        const val BACKGROUND_CHANNEL = "zing_sdk_initializer/background"
        const val TAG = "RealFlutterEngine"
    }
}
