package com.example.zing_sdk_initializer.engine

/**
 * A booted headless Flutter engine, owned by [com.example.zing_sdk_initializer.ZingFlutterEngineManager].
 */
internal interface Engine {
    fun start()

    fun destroy()
}

/** Creates a headless [Engine] */
internal interface EngineFactory {
    suspend fun create(): Engine?
}
