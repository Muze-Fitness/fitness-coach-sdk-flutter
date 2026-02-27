import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zing_sdk_initializer/zing_sdk_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await ZingSdk.instance.init(
      SdkAuthentication.apiKey('2QClmj1z.VFuF5vEgYtoogpVTvmu97o0vwOQPPSZ9'),
    );
  } on PlatformException catch (error, stackTrace) {
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zing SDK Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _sdk = ZingSdk.instance;
  String? _error;
  SdkAuthState? _authState;
  StreamSubscription<SdkAuthState>? _authStateSub;

  static const _routes = <(String, StartingRoute)>[
    ('Custom Workout', CustomWorkoutRoute()),
    ('AI Assistant', AiAssistantRoute()),
    ('Workout Plan Details', WorkoutPlanDetailsRoute()),
    ('Full Schedule', FullScheduleRoute()),
    ('Profile Settings', ProfileSettingsRoute()),
    ('Health Connect Permissions', HealthConnectPermissionsRoute()),
  ];

  @override
  void initState() {
    super.initState();
    _authStateSub = _sdk.authState.listen(
      (state) => setState(() => _authState = state),
      onError: (Object error) => setState(() => _error = error.toString()),
    );
    _autoLogin();
  }

  Future<void> _autoLogin() async {
    final state = await _sdk.authState.first;
    if (state is! SdkAuthStateAuthenticated &&
        state is! SdkAuthStateInProgress) {
      try {
        await _sdk.login();
      } on PlatformException catch (e) {
        if (mounted) setState(() => _error = '${e.code}: ${e.message}');
      }
    }
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
        await _sdk.login();
      }
    } on PlatformException catch (e) {
      setState(() => _error = '${e.code}: ${e.message}');
    }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Zing SDK Example')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const WorkoutPlanCardHost(),
            const SizedBox(height: 16),
            FilledButton(
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
            const SizedBox(height: 8),
            Text('Auth state: ${_authState ?? 'unknown'}'),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            for (final (label, route) in _routes) ...[
              OutlinedButton(
                onPressed: () => _openScreen(route),
                child: Text(label),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
