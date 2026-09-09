package com.example.zing_sdk_initializer

import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import coach.zing.fitness.coach.SdkAuthState
import coach.zing.fitness.coach.ZingSdk
import coach.zing.fitness.coach.embedded.home.HomeScreenConfig
import coach.zing.fitness.coach.embedded.home.ZingSdkHomeView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

private const val METHOD_SET_CONFIG = "setConfig"
private const val ARG_BACK_BUTTON_IS_VISIBLE = "backButtonIsVisible"
private const val ARG_ASK_COACH_IS_VISIBLE = "askCoachIsVisible"

class ZingSdkHomeViewFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    companion object {
        const val VIEW_TYPE = "zing_sdk_initializer/home_view"
    }

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return ZingSdkHomePlatformView(
            context = context,
            channel = MethodChannel(messenger, "$VIEW_TYPE/$viewId"),
            params = args as? Map<*, *>,
        )
    }
}

private class ZingSdkHomePlatformView(
    private val context: Context,
    private val channel: MethodChannel,
    params: Map<*, *>?,
) : PlatformView {

    private val container = FrameLayout(context)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private var config = configOf(params ?: emptyMap<Any, Any>())
    private var handledInsets: Any? = params?.get(ARG_HANDLED_INSETS)
    private var homeView: ZingSdkHomeView? = null

    init {
        channel.setMethodCallHandler(::onMethodCall)
        scope.launch {
            ZingSdk.authState.collect { state ->
                if (state is SdkAuthState.LoggedIn) attach() else detach()
            }
        }
    }

    private fun attach() {
        if (homeView != null) return
        val view = ZingSdkHomeView(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
            setConfig(config)
            applyHandledInsets(handledInsets)
        }
        homeView = view
        container.addView(view)
    }

    private fun detach() {
        val view = homeView ?: return
        homeView = null
        container.removeView(view)
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_SET_CONFIG -> {
                config = configOf(call.arguments as? Map<*, *> ?: emptyMap<Any, Any>())
                homeView?.setConfig(config)
                result.success(null)
            }

            METHOD_SET_HANDLED_INSETS -> {
                handledInsets = call.arguments
                homeView?.applyHandledInsets(handledInsets)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun configOf(config: Map<*, *>) = HomeScreenConfig(
        backButtonIsVisible = config[ARG_BACK_BUTTON_IS_VISIBLE] as? Boolean ?: false,
        askCoachIsVisible = config[ARG_ASK_COACH_IS_VISIBLE] as? Boolean ?: true,
    )

    override fun getView(): View = container

    override fun dispose() {
        detach()
        channel.setMethodCallHandler(null)
        scope.cancel()
    }
}
