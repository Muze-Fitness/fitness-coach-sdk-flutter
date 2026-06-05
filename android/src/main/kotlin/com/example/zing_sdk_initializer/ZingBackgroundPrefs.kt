package com.example.zing_sdk_initializer

/**
 * Shared storage of the Dart callback handles used to run the consumer's background
 * setup function in a headless isolate. Written by the plugin (foreground, from
 * `registerBackgroundSetup`) and read by [ZingHealthConnectForegroundService] (background).
 */
internal object ZingBackgroundPrefs {
    const val NAME = "zing_sdk_background_prefs"
    const val KEY_DISPATCHER = "dispatcher_handle"
    const val KEY_SETUP = "setup_handle"
}
