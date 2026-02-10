import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zing_sdk_initializer/zing_sdk_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await ZingSdkInitializer.instance.initialize();
  } on PlatformException catch (error, stackTrace) {
    debugPrint('Failed to initialize Zing SDK: ${error.message}');
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
  final _sdk = ZingSdkInitializer.instance;
  String? _error;

  Future<void> _openScreen(ZingSdkScreen screen) async {
    setState(() => _error = null);
    try {
      await _sdk.openScreen(screen);
    } on StateError catch (e) {
      setState(() => _error = e.message);
    } on PlatformException catch (e) {
      setState(() => _error = '${e.code}: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zing SDK Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 200, child: WorkoutPlanCardHost()),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          for (final screen in ZingSdkScreen.values) ...[
            OutlinedButton(
              onPressed: () => _openScreen(screen),
              child: Text(screen.name),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
