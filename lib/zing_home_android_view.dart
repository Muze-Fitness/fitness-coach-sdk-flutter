import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'program_screen_configuration.dart';
import 'zing_sdk_handled_insets.dart';

class ZingHomeAndroidView extends StatefulWidget {
  const ZingHomeAndroidView({
    super.key,
    required this.configuration,
  });

  final ProgramScreenConfiguration configuration;

  @override
  State<ZingHomeAndroidView> createState() => _ZingHomeAndroidViewState();
}

class _ZingHomeAndroidViewState extends State<ZingHomeAndroidView> {
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
  void didUpdateWidget(ZingHomeAndroidView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.configuration;
    final current = widget.configuration;
    if (old.showCloseButton == current.showCloseButton &&
        old.showAskCoachButton == current.showAskCoachButton) {
      return;
    }
    _channel?.invokeMethod<void>(_setConfig, _config());
  }

  Map<String, dynamic> _config() => <String, dynamic>{
        'backButtonIsVisible': widget.configuration.showCloseButton,
        'askCoachIsVisible': widget.configuration.showAskCoachButton,
      };

  @override
  Widget build(BuildContext context) {
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
