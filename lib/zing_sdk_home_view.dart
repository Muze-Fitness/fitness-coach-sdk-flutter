import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'zing_sdk_handled_insets.dart';

/// The SDK's native home screen, embedded into the Flutter widget tree.
///
/// Android only — on other platforms it takes up no space. The screen draws its own
/// header and expects the whole viewport, so the host must not put an app bar above
/// it; a bottom navigation bar is fine.
///
/// Whatever the Flutter layout above this widget has already accounted for is
/// reported to the native side instead of being padded twice, so hosts need no inset
/// bookkeeping of their own, with or without a [SafeArea] around the widget.
class ZingSdkHomeView extends StatefulWidget {
  const ZingSdkHomeView({
    super.key,
    this.backButtonIsVisible = false,
    this.askCoachIsVisible = true,
  });

  /// Whether the screen shows its own back button. Off by default: an embedded
  /// screen usually sits inside navigation owned by the host app.
  final bool backButtonIsVisible;

  /// Whether the "ask coach" entry point is shown.
  final bool askCoachIsVisible;

  @override
  State<ZingSdkHomeView> createState() => _ZingSdkHomeViewState();
}

class _ZingSdkHomeViewState extends State<ZingSdkHomeView> {
  static const _viewType = 'zing_sdk_initializer/home_view';
  static const _setConfig = 'setConfig';

  Map<String, int> _handledInsets = zingSdkNoHandledInsets;
  MethodChannel? _channel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final handledInsets = zingSdkHandledInsets(context);
    if (mapEquals(handledInsets, _handledInsets)) return;
    _handledInsets = handledInsets;
    _channel?.invokeMethod<void>(zingSdkSetHandledInsetsMethod, handledInsets);
  }

  @override
  void didUpdateWidget(ZingSdkHomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backButtonIsVisible == widget.backButtonIsVisible &&
        oldWidget.askCoachIsVisible == widget.askCoachIsVisible) {
      return;
    }
    _channel?.invokeMethod<void>(_setConfig, _config());
  }

  Map<String, dynamic> _config() => <String, dynamic>{
    'backButtonIsVisible': widget.backButtonIsVisible,
    'askCoachIsVisible': widget.askCoachIsVisible,
  };

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    final creationParams = <String, dynamic>{
      ..._config(),
      zingSdkHandledInsetsArg: _handledInsets,
    };
    final layoutDirection = Directionality.of(context);

    return PlatformViewLink(
      viewType: _viewType,
      surfaceFactory: (context, controller) => AndroidViewSurface(
        controller: controller as AndroidViewController,
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
      ),
      onCreatePlatformView: (params) {
        return PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: _viewType,
          layoutDirection: layoutDirection,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () => params.onFocusChanged(true),
        )
          ..addOnPlatformViewCreatedListener((id) {
            _channel = MethodChannel('$_viewType/$id');
            _channel?.invokeMethod<void>(
              zingSdkSetHandledInsetsMethod,
              _handledInsets,
            );
            params.onPlatformViewCreated(id);
          })
          ..create();
      },
    );
  }
}
