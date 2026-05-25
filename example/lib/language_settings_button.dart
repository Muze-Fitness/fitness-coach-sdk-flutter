import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';

/// Opens the per-app language settings screen, mirroring the logic in
/// ZingSettingsCallbacks.createLanguageSettingsIntent() from the main app.
///
/// Android 13+: Settings.ACTION_APP_LOCALE_SETTINGS (per-app picker)
/// Android <13: Settings.ACTION_LOCALE_SETTINGS (system locale settings)
class LanguageSettingsButton extends StatelessWidget {
  const LanguageSettingsButton({super.key, required this.packageName});

  final String packageName;

  Future<void> _openLanguageSettings() async {
    if (!Platform.isAndroid) return;

    final appLocaleIntent = AndroidIntent(
      action: 'android.settings.APP_LOCALE_SETTINGS',
      data: 'package:$packageName',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    if (await appLocaleIntent.canResolveActivity() == true) {
      await appLocaleIntent.launch();
      return;
    }

    const AndroidIntent(
      action: 'android.settings.LOCALE_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    ).launch();
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _openLanguageSettings,
      child: const Text('Language Settings'),
    );
  }
}
