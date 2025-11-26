package com.example.zing_sdk_initializer

import android.content.Context
import android.view.View
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import coach.zing.core.compose.theme.ZingTheme
import coach.zing.fitness.coach.StartingRoute
import coach.zing.fitness.coach.ZingSdkActivity
import coach.zing.fitness.coach.plan.WorkoutPlanCard
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

internal class WorkoutPlanCardView(
    context: Context,
    viewId: Int,
    messenger: BinaryMessenger
) : PlatformView, MethodChannel.MethodCallHandler {

    private val methodChannel = MethodChannel(
        messenger,
        "workout_plan_card_view_$viewId"
    )

    private val composeView = ComposeView(context).apply {
        setViewCompositionStrategy(
            ViewCompositionStrategy.DisposeOnDetachedFromWindow
        )
        setContent {
            ZingTheme {
                WorkoutPlanCard(
                    modifier = Modifier.fillMaxWidth(),
                    onCustomWorkoutClicked = {
                        ZingSdkActivity.launch(
                            context,
                            StartingRoute.CustomWorkout
                        )
                    },
                    onSettingsClicked = {
                    }
                )
            }
        }
    }

    init {
        methodChannel.setMethodCallHandler(this)
    }

    private var lastMeasuredWidth: Int = -1
    private var lastReportedHeight: Int = -1

    override fun getView(): View = composeView

    override fun dispose() {
        methodChannel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_SET_WIDTH -> {
                val widthPx = call.argument<Number>(ARG_WIDTH)?.toInt() ?: 0
                if (widthPx > 0) {
                    measureWithWidth(widthPx)
                }
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun measureWithWidth(widthPx: Int) {
        lastMeasuredWidth = widthPx

        val widthSpec = View.MeasureSpec.makeMeasureSpec(widthPx, View.MeasureSpec.EXACTLY)
        val heightSpec = View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)

        composeView.measure(widthSpec, heightSpec)
        val measuredHeight = composeView.measuredHeight

        if (measuredHeight <= 0) {
            return
        }

        composeView.layout(0, 0, widthPx, measuredHeight)

        if (measuredHeight == lastReportedHeight) {
            return
        }
        lastReportedHeight = measuredHeight

        methodChannel.invokeMethod(
            METHOD_SIZE_CHANGED,
            mapOf(
                ARG_WIDTH to widthPx,
                ARG_HEIGHT to measuredHeight
            )
        )
    }

    private companion object {
        private const val METHOD_SET_WIDTH = "setWidth"
        private const val METHOD_SIZE_CHANGED = "sizeChanged"
        private const val ARG_WIDTH = "width"
        private const val ARG_HEIGHT = "height"
    }
}

