package com.example.zing_sdk_initializer

import android.content.Context
import android.view.View
import android.view.ViewGroup.LayoutParams
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.compose.ui.unit.dp
import coach.zing.core.compose.theme.ZingTheme
import coach.zing.fitness.coach.StartingRoute
import coach.zing.fitness.coach.ZingSdkActivity
import coach.zing.fitness.coach.plan.WorkoutPlanCard
import coach.zing.fitness.coach.plan.WorkoutPlanSettingsOverlay
import io.flutter.plugin.platform.PlatformView

internal class WorkoutPlanCardView(
    context: Context
) : PlatformView {

    private val composeView = ComposeView(context).apply {
        layoutParams = LayoutParams(
            LayoutParams.MATCH_PARENT,
            LayoutParams.MATCH_PARENT
        )
        setViewCompositionStrategy(
            ViewCompositionStrategy.DisposeOnDetachedFromWindow
        )
        setContent {
            ZingTheme {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.TopCenter
                ) {
                    var isWorkoutPlanSettingsVisible by remember {
                        mutableStateOf(false)
                    }
                    WorkoutPlanCard(
                        modifier = Modifier.fillMaxWidth(),
                        onCustomWorkoutClicked = {
                            ZingSdkActivity.launch(
                                context,
                                StartingRoute.CustomWorkout
                            )
                        },
                        onSettingsClicked = {
                            isWorkoutPlanSettingsVisible = true
                        },
                        onOpenChatClicked = {
                            ZingSdkActivity.launch(
                                context,
                                StartingRoute.AiAssistant
                            )
                        }
                    )

                    if (isWorkoutPlanSettingsVisible) {
                        WorkoutPlanSettingsOverlay(
                            onPlanDetailsClicked = {
                                ZingSdkActivity.launch(
                                    context,
                                    StartingRoute.WorkoutPlanDetails
                                )
                            },
                            onFullScheduleClicked = {
                                ZingSdkActivity.launch(
                                    context,
                                    StartingRoute.FullSchedule
                                )
                            },
                            onPlanSettingsClicked = {
                                ZingSdkActivity.launch(
                                    context,
                                    StartingRoute.ProfileSettings
                                )
                            },
                            onDismiss = {
                                isWorkoutPlanSettingsVisible = false
                            }
                        )
                    }
                }
            }
        }
    }

    override fun getView(): View = composeView

    override fun dispose() = Unit
}

