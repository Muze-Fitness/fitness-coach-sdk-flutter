import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zing_sdk_initializer/zing_sdk_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await ZingSdk.instance.init(
      authentication: SdkAuthentication.apiKey(
        ios: 'yVbJzsVP.33rljbAHo9zm4zbyeOvc0dDV3bSSgDxf',
        android: 'BFmIaLAC.7ACCWtEDJjxX5OxiYftMVOd0zHIW580S',
      ),
      configuration: const SdkConfiguration(
        coachesAvailability: CoachesAvailability.userGenderBased,
        genderAvailability: GenderAvailability.binary,
      ),
      theme: const SdkTheme(
        colors: SdkColors(
          brandPrimary: Color(0xFFF2001F),
          brandSecondary: Color(0xFF980052),
        ),
        cornersRounding: SdkCornerRounding(
          buttonBorder: SdkRadius.value(0),
        ),
      ),
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
    ('Home', HomeRoute()),
    ('Custom Workout', CustomWorkoutRoute()),
    ('AI Assistant', AiAssistantRoute()),
    ('Workout Plan Details', WorkoutPlanDetailsRoute()),
    ('Full Schedule', FullScheduleRoute()),
    ('Profile Settings', ProfileSettingsRoute()),
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
            Center(child: Text('Auth state: ${_authState ?? 'unknown'}')),
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
