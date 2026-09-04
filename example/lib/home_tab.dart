import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:zing_sdk_initializer/zing_sdk_initializer.dart';

/// Home tab: the SDK's native home screen, embedded through the plugin's
/// [ZingSdkHomeView] widget.
///
/// Stateless on purpose — the native side owns the screen state, this widget only
/// says where the view lives and which settings it is created with. The screen
/// expects the full viewport, so `RootPage` shows no app bar above this tab.
///
/// The `SafeArea` is the host's choice, not a requirement: it keeps the screen out
/// from under the status bar, which the `Scaffold` background then fills. Either way
/// no edge is padded twice — `ZingSdkHomeView` reports whichever insets the Flutter
/// layout took over and leaves the rest to the native view.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const _UnsupportedPlatform();
    }

    return ZingSdkHomeView(backButtonIsVisible: false);
  }
}

class _UnsupportedPlatform extends StatelessWidget {
  const _UnsupportedPlatform();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'ZingSdkHomeView is only available on Android',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
