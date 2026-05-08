import 'dart:ui';

/// Optional branding overrides applied to the SDK at initialization.
///
/// Any field left `null` falls back to the SDK's built-in defaults.
class SdkTheme {
  const SdkTheme({this.colors, this.cornersRounding, this.typography});

  final SdkColors? colors;
  final SdkCornerRounding? cornersRounding;
  final SdkTypography? typography;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (colors != null) map['colors'] = colors!.toMap();
    if (cornersRounding != null) {
      map['cornersRounding'] = cornersRounding!.toMap();
    }
    if (typography != null) map['typography'] = typography!.toMap();
    return map;
  }
}

/// Color overrides matching the native SDK's semantic color set.
/// Each field is optional; unset fields keep the SDK default.
class SdkColors {
  const SdkColors({
    this.brandPrimary,
    this.brandSecondary,
    this.textHeadingDarkPrimary,
    this.textHeadingLightPrimary,
    this.textBodyDarkPrimary,
    this.textBodyDarkSecondary,
    this.buttonPrimary,
    this.buttonSecondary,
    this.bgPrimary,
    this.bgSecondary,
  });

  final Color? brandPrimary;
  final Color? brandSecondary;

  final Color? textHeadingDarkPrimary;
  final Color? textHeadingLightPrimary;

  final Color? textBodyDarkPrimary;
  final Color? textBodyDarkSecondary;

  final Color? buttonPrimary;
  final Color? buttonSecondary;

  final Color? bgPrimary;
  final Color? bgSecondary;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    void put(String key, Color? color) {
      if (color != null) map[key] = color.toARGB32();
    }

    put('brand/primary', brandPrimary);
    put('brand/secondary', brandSecondary);

    put('text/heading/dark-primary', textHeadingDarkPrimary);
    put('text/heading/light-primary', textHeadingLightPrimary);

    put('text/body/dark-primary', textBodyDarkPrimary);
    put('text/body/dark-secondary', textBodyDarkSecondary);

    put('button/primary', buttonPrimary);
    put('button/secondary', buttonSecondary);

    put('bg/primary', bgPrimary);
    put('bg/secondary', bgSecondary);

    return map;
  }
}

/// Typography overrides. Each field is the resource name of a font file
/// in the host app's platform font resources
/// (Android: `res/font/`, iOS: registered font family name).
class SdkTypography {
  const SdkTypography({this.system, this.brand});

  /// System (body/UI) font resource name.
  final String? system;

  /// Brand (display/heading) font resource name.
  final String? brand;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (system != null) map['system'] = system;
    if (brand != null) map['brand'] = brand;
    return map;
  }
}

/// Corner-radius overrides. Each field is optional; unset fields keep
/// the SDK default.
class SdkCornerRounding {
  const SdkCornerRounding({this.buttonBorder});

  final SdkRadius? buttonBorder;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (buttonBorder != null) map['button/border'] = buttonBorder!.toMap();
    return map;
  }
}

/// A resolved corner radius: a fixed point value or a fully-rounded pill.
/// Use `SdkRadius.value(0)` for no rounding.
sealed class SdkRadius {
  const SdkRadius();

  /// A fixed radius in logical points. Pass `0` to disable rounding.
  const factory SdkRadius.value(double value) = SdkRadiusValue;

  /// A pill shape — corners rounded to half the shorter side.
  const factory SdkRadius.pill() = SdkRadiusPill;

  Map<String, dynamic> toMap();
}

class SdkRadiusValue extends SdkRadius {
  const SdkRadiusValue(this.value);

  final double value;

  @override
  Map<String, dynamic> toMap() => {'type': 'value', 'value': value};
}

class SdkRadiusPill extends SdkRadius {
  const SdkRadiusPill();

  @override
  Map<String, dynamic> toMap() => const {'type': 'pill'};
}
