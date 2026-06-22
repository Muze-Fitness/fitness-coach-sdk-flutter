package com.example.zing_sdk_initializer

import android.util.Log
import com.example.zing_sdk_initializer.engine.Engine
import com.example.zing_sdk_initializer.engine.EngineFactory
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Owns the process' single headless engine, refcounted: created lazily on the first [acquire],
 * destroyed when refs reach 0, and never created while a foreground engine is alive (its binding is
 * reused). [reconcile] holds the invariant: refs > 0 ⇒ a live binding exists (foreground or headless).
 */
internal class ZingFlutterEngineManager(
    private val engineFactory: EngineFactory,
    private val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main),
) {
    private val lock = Any()

    private var engine: Engine? = null
    private var refs = 0
    private var booting = false
    private var foregroundAlive = false

    private val _state = MutableStateFlow(
        State(refs = 0, bootState = BootState.Destroyed, foregroundAlive = false)
    )

    val state: StateFlow<State> = _state.asStateFlow()

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

    private fun reconcile() {
        val needHeadless = refs > 0 && !foregroundAlive
        when {
            needHeadless && engine == null && !booting -> {
                booting = true
                scope.launch { boot() }
            }

            !needHeadless && engine != null && !booting ->
                scope.launch { destroyEngine() }
        }
        publishState()
    }

    private fun publishState() {
        val bootState = when {
            booting -> BootState.InProgress
            engine != null -> BootState.Booted
            else -> BootState.Destroyed
        }
        _state.value = State(refs = refs, bootState = bootState, foregroundAlive = foregroundAlive)
    }

    private suspend fun boot() {
        val created = engineFactory.create()
        synchronized(lock) {
            booting = false
            if (created == null) {
                Log.w(TAG, "boot: engine creation failed/aborted")
                publishState()
                return
            }
            // A release()/foreground-takeover during create() can't schedule a destroy (engine was
            // still null). Re-check here: if no longer needed, tear down the freshly created engine
            // instead of running its Dart setup needlessly.
            if (refs == 0 || foregroundAlive) {
                Log.i(TAG, "boot: no longer needed (refs=$refs, foregroundAlive=$foregroundAlive); destroying")
                created.destroy()
            } else {
                engine = created
                created.start()
                Log.i(TAG, "boot: headless engine started, dispatcher entrypoint executing")
            }
            publishState()
        }
    }

    private fun destroyEngine() = synchronized(lock) {
        if (refs > 0 && !foregroundAlive) return // needed again while we hopped to the dispatcher
        Log.i(TAG, "destroyEngine: destroying headless engine")
        engine?.destroy()
        engine = null
        publishState()
    }

    class Lease {
        @Volatile
        var released = false
    }

    enum class BootState { InProgress, Booted, Destroyed }

    data class State(
        val refs: Int,
        val bootState: BootState,
        val foregroundAlive: Boolean,
    )

    companion object {
        /** Process-wide singleton, created by [ZingHostInitializer]. */
        @Volatile
        var instance: ZingFlutterEngineManager? = null

        private const val TAG = "ZingFlutterHost"
    }
}
