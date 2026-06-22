package com.example.zing_sdk_initializer

import coach.zing.fitness.coach.ZingSdkInitializer

/**
 * Adapts the native [ZingSdkInitializer] port onto [ZingFlutterHost]. acquire() boots the headless
 * engine if needed and increments the refcount; close() releases the lease.
 */
internal class ZingFlutterInitializerImpl : ZingSdkInitializer {
    override fun acquire(): AutoCloseable {
        val lease = ZingFlutterHost.acquire()
        return AutoCloseable { ZingFlutterHost.release(lease) }
    }
}
