import 'dart:ui';

/// Optional branding overrides applied to the SDK at initialization.
///
/// Any field left `null` falls back to the SDK's built-in defaults.
class SdkTheme {
  const SdkTheme({
    this.colors,
    this.cornersRounding,
    this.typography,
    this.blurStyle,
  });

  final SdkColors? colors;
  final SdkCornerRounding? cornersRounding;
  final SdkTypography? typography;

  /// iOS blur style for the SDK's base blur token. Ignored on Android.
  final SdkBlurStyle? blurStyle;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (colors != null) map['colors'] = colors!.toMap();
    if (cornersRounding != null) {
      map['cornersRounding'] = cornersRounding!.toMap();
    }
    if (typography != null) map['typography'] = typography!.toMap();
    if (blurStyle != null) map['blurStyle'] = blurStyle!.name;
    return map;
  }
}

/// iOS `UIBlurEffect.Style` values. `extraDark` is unavailable on iOS.
enum SdkBlurStyle {
  extraLight,
  light,
  dark,
  regular,
  prominent,
  systemUltraThinMaterial,
  systemThinMaterial,
  systemMaterial,
  systemThickMaterial,
  systemChromeMaterial,
  systemUltraThinMaterialLight,
  systemThinMaterialLight,
  systemMaterialLight,
  systemThickMaterialLight,
  systemChromeMaterialLight,
  systemUltraThinMaterialDark,
  systemThinMaterialDark,
  systemMaterialDark,
  systemThickMaterialDark,
  systemChromeMaterialDark,
}

/// Color overrides matching the native iOS color tokens.
/// Each field is optional; unset fields keep the SDK default.
///
/// Map keys are the native token strings and are applied 1-1 on iOS.
class SdkColors {
  const SdkColors({
    this.bgPrimary,
    this.bgSecondary,
    this.bgTertiary,
    this.bgLight,
    this.bgLight24,
    this.bgLight64,
    this.bgLight8,
    this.bgAccentLayer,
    this.borderPrimary,
    this.borderSecondary,
    this.borderGloss,
    this.brandPrimary,
    this.brandSecondary,
    this.brandTertiary,
    this.brandText,
    this.buttonPrimary,
    this.buttonSecondary,
    this.buttonLightYellow,
    this.buttonLightOrchid,
    this.buttonLightBlue,
    this.buttonIconTransparent,
    this.cardBgPrimary,
    this.cardBgSecondary,
    this.cvBgBodyScan,
    this.cvBgFitnessTest,
    this.cvBgFlexibilityTest,
    this.cvPrimary,
    this.fgPrimary,
    this.fgSecondary,
    this.fgPrimaryDark,
    this.fgPrimaryInv,
    this.fgPrimaryLight,
    this.fgRed,
    this.headingPrimary,
    this.headingPrimaryInv,
    this.overlayBlackDark,
    this.overlayBlackMedium,
    this.overlayCadetMedium,
    this.overlayCardAccent,
    this.overlayCardDefault,
    this.textBodyLightPrimary,
    this.textBodyLightSecondary,
    this.textBodyBluePrimary,
    this.textBodyBlueSecondary,
    this.textBodyYellowPrimary,
    this.textBodyOrchidPrimary,
  });

  final Color? bgPrimary;
  final Color? bgSecondary;
  final Color? bgTertiary;
  final Color? bgLight;
  final Color? bgLight24;
  final Color? bgLight64;
  final Color? bgLight8;
  final Color? bgAccentLayer;

  final Color? borderPrimary;
  final Color? borderSecondary;
  final Color? borderGloss;

  final Color? brandPrimary;
  final Color? brandSecondary;
  final Color? brandTertiary;
  final Color? brandText;

  final Color? buttonPrimary;
  final Color? buttonSecondary;
  final Color? buttonLightYellow;
  final Color? buttonLightOrchid;
  final Color? buttonLightBlue;
  final Color? buttonIconTransparent;

  final Color? cardBgPrimary;
  final Color? cardBgSecondary;

  final Color? cvBgBodyScan;
  final Color? cvBgFitnessTest;
  final Color? cvBgFlexibilityTest;
  final Color? cvPrimary;

  final Color? fgPrimary;
  final Color? fgSecondary;
  final Color? fgPrimaryDark;
  final Color? fgPrimaryInv;
  final Color? fgPrimaryLight;
  final Color? fgRed;

  final Color? headingPrimary;
  final Color? headingPrimaryInv;

  final Color? overlayBlackDark;
  final Color? overlayBlackMedium;
  final Color? overlayCadetMedium;

  final Color? overlayCardAccent;
  final Color? overlayCardDefault;

  final Color? textBodyLightPrimary;
  final Color? textBodyLightSecondary;
  final Color? textBodyBluePrimary;
  final Color? textBodyBlueSecondary;
  final Color? textBodyYellowPrimary;
  final Color? textBodyOrchidPrimary;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    void put(String key, Color? color) {
      if (color != null) map[key] = color.toARGB32();
    }

    put('bg/primary', bgPrimary);
    put('bg/secondary', bgSecondary);
    put('bg/tertiary', bgTertiary);
    put('bg/light', bgLight);
    put('bg/light-24', bgLight24);
    put('bg/light-64', bgLight64);
    put('bg/light-8', bgLight8);
    put('bg/accent-layer', bgAccentLayer);

    put('border/primary', borderPrimary);
    put('border/secondary', borderSecondary);
    put('border/gloss', borderGloss);

    put('brand/primary', brandPrimary);
    put('brand/secondary', brandSecondary);
    put('brand/tertiary', brandTertiary);
    put('brand/text', brandText);

    put('button/bg-primary', buttonPrimary);
    put('button/bg-secondary', buttonSecondary);
    put('button/bg-light-yellow', buttonLightYellow);
    put('button/bg-light-orchid', buttonLightOrchid);
    put('button/bg-light-blue', buttonLightBlue);
    put('button/bg-icon-transparent', buttonIconTransparent);

    put('card-bg/primary', cardBgPrimary);
    put('card-bg/secondary', cardBgSecondary);

    put('cv/bg-body-scan', cvBgBodyScan);
    put('cv/bg-fitness-test', cvBgFitnessTest);
    put('cv/bg-flexibility-test', cvBgFlexibilityTest);
    put('cv/primary', cvPrimary);

    put('fg/primary', fgPrimary);
    put('fg/secondary', fgSecondary);
    put('fg/primary-dark', fgPrimaryDark);
    put('fg/primary-inv', fgPrimaryInv);
    put('fg/primary-light', fgPrimaryLight);
    put('fg/red', fgRed);

    put('heading/primary', headingPrimary);
    put('heading/primary-inv', headingPrimaryInv);

    put('overlay/black-dark', overlayBlackDark);
    put('overlay/black-medium', overlayBlackMedium);
    put('overlay/cadet-medium', overlayCadetMedium);

    put('overlay/card/accent', overlayCardAccent);
    put('overlay/card/default', overlayCardDefault);

    put('text/body/light-primary', textBodyLightPrimary);
    put('text/body/light-secondary', textBodyLightSecondary);
    put('text/body/blue-primary', textBodyBluePrimary);
    put('text/body/blue-secondary', textBodyBlueSecondary);
    put('text/body/yellow-primary', textBodyYellowPrimary);
    put('text/body/orchid-primary', textBodyOrchidPrimary);

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
  const SdkCornerRounding({
    this.button,
    this.input,
    this.hero,
    this.modal,
    this.cardSm,
    this.cardMd,
    this.cardLg,
  });

  final SdkRadius? button;
  final SdkRadius? input;
  final SdkRadius? hero;
  final SdkRadius? modal;
  final SdkRadius? cardSm;
  final SdkRadius? cardMd;
  final SdkRadius? cardLg;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    void put(String key, SdkRadius? radius) {
      if (radius != null) map[key] = radius.toMap();
    }

    put('radius/button', button);
    put('radius/input', input);
    put('radius/hero', hero);
    put('radius/modal', modal);
    put('radius/card-sm', cardSm);
    put('radius/card-md', cardMd);
    put('radius/card-lg', cardLg);

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
