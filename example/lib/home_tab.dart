import 'dart:async';

import 'package:flutter/material.dart';

import 'package:zing_sdk_initializer/zing_sdk_initializer.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  SdkAuthState? _authState;
  StreamSubscription<SdkAuthState>? _authStateSub;

  @override
  void initState() {
    super.initState();
    _authStateSub = ZingSdk.instance.authState.listen(
      (state) => setState(() => _authState = state),
    );
  }

  @override
  void dispose() {
    _authStateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_authState is! SdkAuthStateAuthenticated) {
      return const _LoginRequired();
    }

    return const ZingHomeView(
      configuration: HomeScreenConfiguration(showCloseButton: false),
    );
  }
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Log in on the Settings tab to see the Zing home screen',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}
