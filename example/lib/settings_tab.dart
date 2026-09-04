import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zing_sdk_initializer/zing_sdk_initializer.dart';

import 'api_keys.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _sdk = ZingSdk.instance;
  String? _error;
  SdkAuthState? _authState;
  StreamSubscription<SdkAuthState>? _authStateSub;
  String? _partnerUserId;

  static const _routes = <(String, StartingRoute)>[
    ('Home', HomeRoute()),
    ('Custom Workout', CustomWorkoutRoute()),
    ('AI Assistant', AiAssistantRoute()),
    ('Workout Plan Details', WorkoutPlanDetailsRoute()),
    ('Full Schedule', FullScheduleRoute()),
    ('Profile Settings', ProfileSettingsRoute()),
    ('Body Scan', BodyScanRoute()),
    ('Flexibility Test', FlexibilityTestRoute()),
    ('Fitness Test', FitnessTestRoute())
  ];

  @override
  void initState() {
    super.initState();
    _authStateSub = _sdk.authState.listen(
      (state) => setState(() => _authState = state),
      onError: (Object error) => setState(() => _error = error.toString()),
    );
  }

  @override
  void dispose() {
    _authStateSub?.cancel();
    super.dispose();
  }

  Future<void> _loginOrLogout() async {
    setState(() => _error = null);
    try {
      final state = _authState;
      if (state is SdkAuthStateAuthenticated) {
        await _sdk.logout();
      } else if (state is! SdkAuthStateInProgress) {
        await _sdk.login(
          SdkAuthentication.apiKey(
            ios: apiKeyIos,
            android: apiKeyAndroid,
            partnerUserId: _partnerUserId,
          ),
        );
      }
    } on PlatformException catch (e) {
      setState(() => _error = '${e.code}: ${e.message}');
    }
  }

  Future<void> _setProfileParams() async {
    setState(() => _error = null);
    try {
      await _sdk.setProfileParams(
        const ProfileParams(
          name: 'Username',
          gender: UserGender.male,
          height: 178.9,
          weight: 67.8,
          age: 23,
          measurementSystem: MeasurementSystem.metric,
        ),
      );
    } on PlatformException catch (e) {
      setState(() => _error = '${e.code}: ${e.message}');
    }
  }

  Future<void> _showSetPartnerIdDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _SetPartnerIdDialog(initialValue: _partnerUserId),
    );

    if (result == null || !mounted) return;
    setState(() {
      _partnerUserId = result.trim().isEmpty ? null : result.trim();
    });
  }

  Future<void> _openScreen(StartingRoute route) async {
    setState(() => _error = null);
    try {
      await _sdk.openScreen(route);
    } on PlatformException catch (e) {
      setState(() => _error = '${e.code}: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                onPressed: _authState is SdkAuthStateInProgress
                    ? null
                    : _loginOrLogout,
                child: Text(
                  switch (_authState) {
                    SdkAuthStateAuthenticated() => 'Logout',
                    SdkAuthStateInProgress() => 'In Progress...',
                    _ => 'Login',
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.tonal(
                onPressed: _authState is SdkAuthStateAuthenticated
                    ? _setProfileParams
                    : null,
                child: const Text('Set Profile Params'),
              ),
            ),
            if (_authState is SdkAuthStateLoggedOut) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton(
                  onPressed: _showSetPartnerIdDialog,
                  child: Text(
                    _partnerUserId == null
                        ? 'Set Partner ID'
                        : 'Partner ID: $_partnerUserId',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Auth state: ${switch (_authState) {
                  SdkAuthStateAuthenticated() => 'Authenticated',
                  SdkAuthStateInProgress() => 'In progress',
                  SdkAuthStateLoggedOut() => 'Logged out',
                  null => 'Unknown',
                }}',
              ),
            ),
            if (_authState case SdkAuthStateAuthenticated(:final userId)) ...[
              const SizedBox(height: 4),
              Center(
                child: InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: userId));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User ID copied')),
                    );
                  },
                  child: Text('User ID: $userId'),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 48),
            for (final (label, route) in _routes) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton(
                  onPressed: () => _openScreen(route),
                  child: Text(label),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _SetPartnerIdDialog extends StatefulWidget {
  const _SetPartnerIdDialog({required this.initialValue});

  final String? initialValue;

  @override
  State<_SetPartnerIdDialog> createState() => _SetPartnerIdDialogState();
}

class _SetPartnerIdDialogState extends State<_SetPartnerIdDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Partner ID'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'partnerUserId'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Setup'),
        ),
      ],
    );
  }
}
