import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zing_sdk_initializer/zing_sdk_initializer.dart';
import 'home_tab.dart';
import 'settings_tab.dart';

/// Shared with [SettingsTab]'s theme switcher: `ZingSdk.init` resets whatever
/// it isn't passed (native `ZingSdk.handleConfiguration` nulls out the
/// configuration when it's omitted), so every call site that re-inits at
/// runtime must keep passing this, not just the theme.
const sdkConfiguration = SdkConfiguration(
  coachesAvailability: CoachesAvailability.userGenderBased,
  genderAvailability: GenderAvailability.binary,
  healthBackgroundSync: true,
);

const lightSdkTheme = SdkTheme(
  cornersRounding: SdkCornerRounding(
    button: SdkRadius.value(0),
  ),
);

// Color overrides from DesignSystem.Theme.defaultDark. Unset tokens
// stay on the light default, which is the base of that theme.
const darkSdkTheme = SdkTheme(
  colors: SdkColors(
    bgPrimary: Color(0xFF000000),
    bgSecondary: Color(0xFF000000),
    bgTertiary: Color(0xFF394052),
    bgAccentLayer: Color(0x29FFFFFF),
    borderPrimary: Color(0x1FFFFFFF),
    borderGloss: Color(0x29FFFFFF),
    brandText: Color(0xFF95A6FF),
    buttonPrimary: Color(0xFFFFFFFF),
    buttonSecondary: Color(0x29FFFFFF),
    cardBgPrimary: Color(0xFF1D212C),
    cardBgSecondary: Color(0xFF1D212C),
    cvBgBodyScan: Color(0xFF8C25F4),
    cvBgFitnessTest: Color(0xFFB68300),
    fgPrimary: Color(0xFFFFFFFF),
    fgSecondary: Color(0xFFA3ABC3),
    fgPrimaryInv: Color(0xFF000000),
    fgRed: Color(0xFFC02640),
    headingPrimary: Color(0xFFFFFFFF),
    headingPrimaryInv: Color(0xFF000000),
    overlayCardAccent: Color(0x66FFFFFF),
    overlayCardDefault: Color(0x66100D29),
  ),
  cornersRounding: SdkCornerRounding(
    button: SdkRadius.value(0),
  ),
  blurStyle: SdkBlurStyle.systemMaterialDark,
);

/// SDK setup used both on app startup (foreground) and in the headless background
/// isolate (Health Connect background sync). Must be a top-level function annotated
/// with `@pragma('vm:entry-point')` so it survives tree-shaking and can be looked up
/// by the native side in a fresh isolate.
@pragma('vm:entry-point')
Future<void> zingSdkSetup() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ZingSdk.instance.init(
    configuration: sdkConfiguration,
    theme: lightSdkTheme,
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
  // ZingHomeView draws its own header and expects the full viewport, so the
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
