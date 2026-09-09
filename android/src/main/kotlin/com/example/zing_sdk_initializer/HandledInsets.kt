package com.example.zing_sdk_initializer

import coach.zing.fitness.coach.embedded.ZingSdkEmbeddedView

internal const val ARG_HANDLED_INSETS = "handledInsets"
internal const val METHOD_SET_HANDLED_INSETS = "setHandledInsets"

internal fun ZingSdkEmbeddedView.applyHandledInsets(args: Any?) {
    val insets = args as? Map<*, *> ?: return
    fun edge(key: String) = (insets[key] as? Number)?.toInt() ?: 0
    setHandledInsets(
        left = edge("left"),
        top = edge("top"),
        right = edge("right"),
        bottom = edge("bottom"),
    )
}
