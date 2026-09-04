package com.example.zing_sdk_initializer

import android.content.Context
import android.view.View
import coach.zing.fitness.coach.embedded.home.HomeScreenViewConfig
import coach.zing.fitness.coach.embedded.home.ZingSdkHomeView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

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
        val params = args as? Map<*, *>
        return ZingSdkHomePlatformView(
            context = context,
            channel = MethodChannel(messenger, "$VIEW_TYPE/$viewId"),
            params = params,
        )
    }
}

private class ZingSdkHomePlatformView(
    context: Context,
    private val channel: MethodChannel,
    params: Map<*, *>?,
) : PlatformView {

    private val homeView = ZingSdkHomeView(context)

    init {
        params?.let {
            applyConfig(it)
            homeView.applyHandledInsets(it[ARG_HANDLED_INSETS])
        }
        channel.setMethodCallHandler(::onMethodCall)
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_SET_CONFIG -> {
                applyConfig(call.arguments as? Map<*, *> ?: emptyMap<Any, Any>())
                result.success(null)
            }

            METHOD_SET_HANDLED_INSETS -> {
                homeView.applyHandledInsets(call.arguments)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun applyConfig(config: Map<*, *>) {
        homeView.setConfig(
            HomeScreenViewConfig(
                backButtonIsVisible = config[ARG_BACK_BUTTON_IS_VISIBLE] as? Boolean ?: false,
                askCoachIsVisible = config[ARG_ASK_COACH_IS_VISIBLE] as? Boolean ?: true,
            )
        )
    }

    override fun getView(): View = homeView

    override fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
