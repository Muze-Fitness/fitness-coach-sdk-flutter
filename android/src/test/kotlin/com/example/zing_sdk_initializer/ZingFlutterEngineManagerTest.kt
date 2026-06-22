package com.example.zing_sdk_initializer

import com.example.zing_sdk_initializer.engine.Engine
import com.example.zing_sdk_initializer.engine.EngineFactory
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class ZingFlutterEngineManagerTest {

    private class FakeEngine : Engine {
        var started = false
        var destroyed = false
        override fun start() { started = true }
        override fun destroy() { destroyed = true }
    }

    /** create() suspends on [gate] so the test can interleave acquire/release while "booting". */
    private class FakeEngineFactory : EngineFactory {
        val gate = CompletableDeferred<Unit>()
        var createCount = 0
        var created: FakeEngine? = null
        override suspend fun create(): Engine? {
            createCount++
            gate.await()
            return FakeEngine().also { created = it }
        }
    }

    @Test
    fun `release during boot tears down the freshly created engine without starting it`() = runTest {
        val factory = FakeEngineFactory()
        val host = ZingFlutterEngineManager(factory, CoroutineScope(StandardTestDispatcher(testScheduler)))

        val lease = host.acquire()
        assertEquals(ZingFlutterEngineManager.BootState.InProgress, host.state.value.bootState)

        advanceUntilIdle()           // boot coroutine runs and suspends inside factory.create()
        host.release(lease)          // refs -> 0 while still booting
        factory.gate.complete(Unit)  // engine finishes creating
        advanceUntilIdle()

        val state = host.state.value
        assertEquals(0, state.refs)
        assertEquals(ZingFlutterEngineManager.BootState.Destroyed, state.bootState)
        assertNotNull(factory.created)
        assertTrue(factory.created!!.destroyed) // freshly created engine was torn down
        assertFalse(factory.created!!.started)  // Dart setup skipped — never started
    }

    @Test
    fun `acquire creates the engine and a later release destroys it`() = runTest {
        val factory = FakeEngineFactory()
        val host = ZingFlutterEngineManager(factory, CoroutineScope(StandardTestDispatcher(testScheduler)))

        val lease = host.acquire()
        advanceUntilIdle()           // boot starts and suspends in factory.create()
        factory.gate.complete(Unit)  // engine finishes creating
        advanceUntilIdle()

        assertEquals(1, host.state.value.refs)
        assertEquals(ZingFlutterEngineManager.BootState.Booted, host.state.value.bootState)
        assertEquals(1, factory.createCount)
        assertNotNull(factory.created)
        assertTrue(factory.created!!.started)    // Dart setup ran
        assertFalse(factory.created!!.destroyed)

        host.release(lease)          // last consumer leaves
        advanceUntilIdle()

        assertEquals(0, host.state.value.refs)
        assertEquals(ZingFlutterEngineManager.BootState.Destroyed, host.state.value.bootState)
        assertTrue(factory.created!!.destroyed)  // engine torn down
    }

    @Test
    fun `two acquires create the engine only once`() = runTest {
        val factory = FakeEngineFactory()
        val host = ZingFlutterEngineManager(factory, CoroutineScope(StandardTestDispatcher(testScheduler)))

        val lease1 = host.acquire()
        advanceUntilIdle()           // boot starts and suspends in factory.create()
        factory.gate.complete(Unit)  // engine finishes creating
        advanceUntilIdle()
        assertEquals(ZingFlutterEngineManager.BootState.Booted, host.state.value.bootState)

        val lease2 = host.acquire()  // second consumer — engine already booted
        advanceUntilIdle()

        assertEquals(2, host.state.value.refs)
        assertEquals(ZingFlutterEngineManager.BootState.Booted, host.state.value.bootState)
        assertEquals(1, factory.createCount) // not created a second time

        // keep leases referenced so the engine is not torn down before assertions
        assertFalse(lease1.released)
        assertFalse(lease2.released)
    }
}
