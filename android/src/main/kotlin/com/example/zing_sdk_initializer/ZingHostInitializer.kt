package com.example.zing_sdk_initializer

import android.content.Context
import androidx.startup.Initializer
import coach.zing.fitness.coach.ZingSdkInitializerRegistry

/**
 * Registers the Flutter implementation of the native [coach.zing.fitness.coach.ZingSdkInitializer]
 * port on every process start — including a cold background start (alarm/boot) where main.dart never
 * runs — before any native SDK component (service/activity) calls keepZingSdkAlive().
 */
class ZingHostInitializer : Initializer<Unit> {
    override fun create(context: Context) {
        ZingFlutterHost.install(context.applicationContext)
        ZingSdkInitializerRegistry.instance = ZingFlutterInitializerImpl()
    }

    override fun dependencies(): List<Class<out Initializer<*>>> = emptyList()
}
