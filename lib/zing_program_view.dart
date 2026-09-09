import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'program_screen_configuration.dart';
import 'zing_home_android_view.dart';

class ZingProgramView extends StatelessWidget {
  const ZingProgramView({
    super.key,
    required this.configuration,
  });

  final ProgramScreenConfiguration configuration;

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
