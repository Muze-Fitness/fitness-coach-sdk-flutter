import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'home_screen_configuration.dart';
import 'embedded_android/zing_home_android_view.dart';

class ZingHomeView extends StatelessWidget {
  const ZingHomeView({
    super.key,
    required this.configuration,
  });

  final HomeScreenConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return ZingHomeAndroidView(configuration: configuration);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'zing_sdk_initializer/program_view',
        creationParams: configuration.toMap(),
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
