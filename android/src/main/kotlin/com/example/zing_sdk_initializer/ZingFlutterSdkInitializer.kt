package com.example.zing_sdk_initializer

import coach.zing.fitness.coach.ZingSdkInitializer

/**
 * Adapts the native [ZingSdkInitializer] port onto a [ZingFlutterEngineManager]. acquire() boots the
 * headless engine if needed and increments the refcount; close() releases the lease.
 */
internal class ZingFlutterSdkInitializer(
    private val host: ZingFlutterEngineManager,
) : ZingSdkInitializer {
    override fun acquire(): AutoCloseable {
        val lease = host.acquire()
        return AutoCloseable { host.release(lease) }
    }
}
