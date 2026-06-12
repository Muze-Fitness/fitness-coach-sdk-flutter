package com.example.zing_sdk_initializer

import kotlinx.coroutines.sync.Mutex

/**
 * Process-wide coordinator for SDK initialization across the foreground (UI) engine and the
 * background headless engine (same process, different isolates).
 *
 * - [mutex] serializes `ZingSdk.init` so `restoreSession` never runs concurrently.
 * - [foregroundStarted] makes the foreground init always win the auth binding: a background init
 *   defers (no-op) once a foreground init has started, so we never end up bound to an ephemeral
 *   background engine that is about to be destroyed.
 */
internal object ZingInitGuard {
    val mutex = Mutex()

    @Volatile
    var foregroundStarted = false
}
