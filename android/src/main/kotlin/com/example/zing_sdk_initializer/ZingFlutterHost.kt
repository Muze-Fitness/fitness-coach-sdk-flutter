package com.example.zing_sdk_initializer

import android.content.Context
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * Owns the process' single headless engine, refcounted: booted lazily on the first [acquire],
 * destroyed when refs reach 0, and never booted while a foreground engine is alive (its binding is
 * reused). [reconcile] holds the invariant: refs > 0 ⇒ a live binding exists (foreground or headless).
 */
internal object ZingFlutterHost {

    class Lease {
        @Volatile
        var released = false
    }

    private val lock = Any()
    private val mainScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private var appContext: Context? = null
    private var engine: FlutterEngine? = null
    private var refs = 0
    private var booting = false

    @Volatile
    var foregroundAlive = false

    fun install(context: Context) {
        appContext = context.applicationContext
    }

    /** A Lease does not freeze the headless decision — it is dynamic (see [reconcile]). */
    fun acquire(): Lease = synchronized(lock) {
        refs++
        Log.d(TAG, "acquire: refs=$refs, foregroundAlive=$foregroundAlive, engine=${engine != null}")
        reconcile()
        Lease()
    }

    fun release(lease: Lease) = synchronized(lock) {
        if (lease.released) return
        lease.released = true
        if (refs > 0) refs--
        Log.d(TAG, "release: refs=$refs, foregroundAlive=$foregroundAlive, engine=${engine != null}")
        reconcile()
    }

    fun onForegroundAttached() = synchronized(lock) {
        foregroundAlive = true
        Log.d(TAG, "onForegroundAttached: refs=$refs")
        reconcile() // headless no longer needed; the foreground init re-establishes the binding
    }

    fun onForegroundDetached() = synchronized(lock) {
        foregroundAlive = false
        Log.d(TAG, "onForegroundDetached: refs=$refs")
        // The foreground engine (binding owner) died. If anything still uses the SDK (refs > 0),
        // reconcile() boots a headless engine whose setup re-runs ZingSdk.init and rebinds sdkAuth.
        reconcile()
    }

    /** Must be called while holding [lock]. */
    private fun reconcile() {
        val needHeadless = refs > 0 && !foregroundAlive
        when {
            needHeadless && engine == null && !booting -> {
                booting = true
                mainScope.launch { boot() }
            }

            !needHeadless && engine != null && !booting ->
                mainScope.launch { destroyEngine() }
        }
    }

    // --- internals (Main thread) ---

    private fun boot() {
        val context = appContext ?: run {
            synchronized(lock) { booting = false }
            return
        }
        val prefs = context.getSharedPreferences(ZingBackgroundPrefs.NAME, Context.MODE_PRIVATE)
        val dispatcherHandle = prefs.getLong(ZingBackgroundPrefs.KEY_DISPATCHER, -1L)
        val setupHandle = prefs.getLong(ZingBackgroundPrefs.KEY_SETUP, -1L)
        if (dispatcherHandle == -1L || setupHandle == -1L) {
            // registerBackgroundSetup was never called — init won't happen, awaitSdkAuthentication
            // will hit the withTimeout on the SDK side.
            Log.w(TAG, "boot: no background handles (registerBackgroundSetup not called?); aborting")
            synchronized(lock) { booting = false }
            return
        }

        // On a cold (background/restored) start libflutter.so is not loaded yet and FlutterJNI is
        // not registered, so lookupCallbackInformation would crash. Initialize the loader first.
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(context)
        loader.ensureInitializationComplete(context, null)

        val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(dispatcherHandle)
        if (callbackInfo == null) {
            Log.w(TAG, "boot: callback info not found for dispatcher=$dispatcherHandle; aborting")
            synchronized(lock) { booting = false }
            return
        }

        Log.i(TAG, "boot: creating headless FlutterEngine (dispatcher=$dispatcherHandle, setup=$setupHandle)")
        val flutterEngine = FlutterEngine(context)
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

        flutterEngine.dartExecutor.executeDartCallback(
            DartExecutor.DartCallback(context.assets, loader.findAppBundlePath(), callbackInfo)
        )
        Log.i(TAG, "boot: headless engine started, dispatcher entrypoint executing")

        synchronized(lock) {
            engine = flutterEngine
            booting = false
            reconcile() // foreground may have returned / refs may have hit 0 while booting
        }
    }

    private fun destroyEngine() = synchronized(lock) {
        if (refs > 0 && !foregroundAlive) return // needed again while we hopped to the Main thread
        Log.i(TAG, "destroyEngine: destroying headless FlutterEngine")
        engine?.destroy()
        engine = null
    }

    private const val BACKGROUND_CHANNEL = "zing_sdk_initializer/background"
    private const val TAG = "ZingFlutterHost"
}
