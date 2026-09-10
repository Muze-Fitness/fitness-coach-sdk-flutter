import 'package:flutter/material.dart';

import 'package:zing_sdk_initializer/zing_sdk_initializer.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ZingProgramView(
      configuration: ProgramScreenConfiguration(showCloseButton: false),
    );
  }
}
