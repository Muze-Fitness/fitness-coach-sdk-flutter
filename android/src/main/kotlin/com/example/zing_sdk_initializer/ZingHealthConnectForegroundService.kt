package com.example.zing_sdk_initializer

import coach.zing.fitness.coach.service.ZingSdkHCForegroundService
import dagger.hilt.android.AndroidEntryPoint

/**
 * Flutter Health Connect background sync service.
 *
 * Extends the SDK's [ZingSdkHCForegroundService] and overrides [onPrepareSdk] to boot a headless
 * Flutter engine (via [ZingBackgroundEngine]) that runs the consumer's registered setup, which
 * calls `ZingSdk.instance.init(...)`. The base service then waits for the SDK to become logged in
 * and performs the sync.
 */
@AndroidEntryPoint
class ZingHealthConnectForegroundService : ZingSdkHCForegroundService() {

    private val backgroundEngine = ZingBackgroundEngine()

    override suspend fun onPrepareSdk() {
        // A live foreground (UI) engine already owns the auth binding — reuse it, don't boot a
        // headless engine. Otherwise (cold start, or UI engine destroyed while the process lives)
        // boot a headless engine and block until it has re-initialized the SDK.
        if (ZingInitGuard.foregroundStarted) return
        backgroundEngine.initAndAwait(applicationContext)
    }

    override fun onDestroy() {
        backgroundEngine.destroy()
        super.onDestroy()
    }
}
