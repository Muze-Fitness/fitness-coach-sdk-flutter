package com.example.zing_sdk_initializer

import coach.zing.fitness.coach.ZingSdk
import coach.zing.fitness.coach.activity.CompletedWorkout
import coach.zing.fitness.coach.activity.PlannedWorkout
import coach.zing.fitness.coach.activity.SdkWorkoutType
import coach.zing.fitness.coach.activity.WorkoutActivityException
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.job
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId

class WorkoutActivityHandler(
    private val scope: CoroutineScope,
    private val channel: MethodChannel,
) : MethodChannel.MethodCallHandler {

    private val subscriptions = mutableMapOf<Int, Job>()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_GET_PLANNED -> get(result) {
                ZingSdk.getPlannedWorkouts().map { it.toMap() }
            }
            METHOD_GET_COMPLETED -> get(result) {
                ZingSdk.getCompletedWorkouts(call.dateTime(ARG_START), call.dateTime(ARG_END)).map { it.toMap() }
            }
            METHOD_OBSERVE_PLANNED -> observe(call, result) {
                ZingSdk.observePlannedWorkouts().map { workouts -> workouts.map { it.toMap() } }
            }
            METHOD_OBSERVE_COMPLETED -> observe(call, result) {
                ZingSdk.observeCompletedWorkouts(call.dateTime(ARG_START), call.dateTime(ARG_END))
                    .map { workouts -> workouts.map { it.toMap() } }
            }
            METHOD_CANCEL -> {
                call.argument<Int>(ARG_ID)?.let { subscriptions.remove(it)?.cancel() }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun get(result: MethodChannel.Result, block: suspend () -> Any) {
        scope.launch {
            runCatching { block() }
                .onSuccess { result.success(it) }
                .onFailure { result.error(it.flutterCode(), it.message, null) }
        }
    }

    private fun observe(call: MethodCall, result: MethodChannel.Result, flow: () -> Flow<Any>) {
        val id = call.argument<Int>(ARG_ID)
            ?: return result.error(CODE_FAILED, "id is required", null)
        val workouts = runCatching(flow).getOrElse {
            return result.error(it.flutterCode(), it.message, null)
        }
        subscriptions.remove(id)?.cancel()
        val job = scope.launch(start = CoroutineStart.LAZY) {
            try {
                workouts.collect { channel.invokeMethod(EVENT_DATA, mapOf(ARG_ID to id, ARG_DATA to it)) }
                channel.invokeMethod(EVENT_DONE, mapOf(ARG_ID to id))
            } catch (e: CancellationException) {
                throw e
            } catch (e: Throwable) {
                channel.invokeMethod(
                    EVENT_ERROR,
                    mapOf(ARG_ID to id, ARG_CODE to e.flutterCode(), ARG_MESSAGE to e.message),
                )
            } finally {
                if (subscriptions[id] === coroutineContext.job) subscriptions.remove(id)
            }
        }
        subscriptions[id] = job
        result.success(null)
        job.start()
    }

    private fun MethodCall.dateTime(key: String): LocalDateTime {
        val millis = argument<Number>(key)?.toLong() ?: throw IllegalArgumentException("$key is required")
        return LocalDateTime.ofInstant(Instant.ofEpochMilli(millis), ZoneId.systemDefault())
    }

    private fun PlannedWorkout.toMap(): Map<String, Any> = mapOf(
        "workoutType" to workoutType.flutterName(),
        "date" to date.atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli(),
        "estimatedDuration" to estimatedDuration.toMillis(),
    )

    private fun CompletedWorkout.toMap(): Map<String, Any> = mapOf(
        "workoutType" to workoutType.flutterName(),
        "date" to date.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli(),
        "actualDuration" to actualDuration.toMillis(),
    )

    private fun SdkWorkoutType.flutterName(): String = when (this) {
        SdkWorkoutType.REGULAR -> "regular"
        SdkWorkoutType.RECOVERY -> "recovery"
    }

    private fun Throwable.flutterCode(): String = when (this) {
        is WorkoutActivityException.NotLoggedIn -> "not_logged_in"
        is WorkoutActivityException.OnboardingNotCompleted -> "onboarding_not_completed"
        else -> CODE_FAILED
    }

    private companion object {
        const val METHOD_GET_PLANNED = "getPlannedWorkouts"
        const val METHOD_OBSERVE_PLANNED = "observePlannedWorkouts"
        const val METHOD_GET_COMPLETED = "getCompletedWorkouts"
        const val METHOD_OBSERVE_COMPLETED = "observeCompletedWorkouts"
        const val METHOD_CANCEL = "cancelWorkoutActivity"
        const val EVENT_DATA = "onData"
        const val EVENT_ERROR = "onError"
        const val EVENT_DONE = "onDone"
        const val ARG_ID = "id"
        const val ARG_START = "start"
        const val ARG_END = "end"
        const val ARG_DATA = "data"
        const val ARG_CODE = "code"
        const val ARG_MESSAGE = "message"
        const val CODE_FAILED = "workout_activity_failed"
    }
}
