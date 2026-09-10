import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zing_sdk_initializer/zing_sdk_initializer.dart';
import 'home_tab.dart';
import 'settings_tab.dart';

const apiKeyIos = 'yVbJzsVP.33rljbAHo9zm4zbyeOvc0dDV3bSSgDxf';
const apiKeyAndroid = 'BFmIaLAC.7ACCWtEDJjxX5OxiYftMVOd0zHIW580S';

/// SDK setup used both on app startup (foreground) and in the headless background
/// isolate (Health Connect background sync). Must be a top-level function annotated
/// with `@pragma('vm:entry-point')` so it survives tree-shaking and can be looked up
/// by the native side in a fresh isolate.
@pragma('vm:entry-point')
Future<void> zingSdkSetup() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ZingSdk.instance.init(
    configuration: const SdkConfiguration(
      coachesAvailability: CoachesAvailability.userGenderBased,
      genderAvailability: GenderAvailability.binary,
      healthBackgroundSync: true,
    ),
    theme: const SdkTheme(
      colors: SdkColors(
        brandPrimary: Color(0xFFF2001F),
        brandSecondary: Color(0xFF980052),
      ),
      cornersRounding: SdkCornerRounding(
        button: SdkRadius.value(0),
      ),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await zingSdkSetup();
    // Register the same setup so the native side can run it in a headless isolate
    // when the process is started in the background (alarm / reboot) for HC sync.
    await ZingSdk.instance.registerBackgroundSetup(zingSdkSetup);
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
      home: const RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  // ZingProgramView draws its own header and expects the full viewport, so the
  // Home tab runs without an app bar; the bottom navigation bar is fine to keep.
  static const _tabs =
      <({String label, IconData icon, Widget page, bool hasAppBar})>[
        (
          label: 'Settings',
          icon: Icons.settings_outlined,
          page: SettingsTab(),
          hasAppBar: true,
        ),
        (
          label: 'Home',
          icon: Icons.home_outlined,
          page: HomeTab(),
          hasAppBar: false,
        ),
      ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _tabs[_index].hasAppBar
          ? AppBar(title: Text(_tabs[_index].label))
          : null,
      // IndexedStack keeps each tab alive so switching tabs does not tear down
      // the SDK view or lose the auth state subscription.
      body: IndexedStack(
        index: _index,
        children: [for (final tab in _tabs) tab.page],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}
