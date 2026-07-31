/// The user's gender as accepted by the native SDKs.
enum UserGender {
  male,
  female,
  other,
  preferNotToSay
}

/// Preferred units for measurements shown in the SDK UI.
enum MeasurementSystem {
  metric,
  imperial
}

/// Optional profile fields forwarded to the native SDK.
///
/// Providing [name] or [gender] skips the matching onboarding screens; the
/// other fields pre-fill them. After onboarding the params update the profile
/// directly.
///
/// [height] is in centimeters and [weight] in kilograms regardless of
/// [measurementSystem], which only selects the units shown in the SDK UI.
class ProfileParams {
  const ProfileParams({
    this.name,
    this.gender,
    this.height,
    this.weight,
    this.age,
    this.measurementSystem,
  });

  /// The user's display name.
  final String? name;

  /// The user's gender.
  final UserGender? gender;

  /// Height in centimeters (cm).
  final double? height;

  /// Weight in kilograms (kg).
  final double? weight;

  /// Age in full years.
  final int? age;

  /// Preferred units for measurements in the SDK UI.
  final MeasurementSystem? measurementSystem;

  Map<String, dynamic> toMap() => {
        if (name != null) 'name': name,
        if (gender != null) 'gender': gender!.name,
        if (height != null) 'height': height,
        if (weight != null) 'weight': weight,
        if (age != null) 'age': age,
        if (measurementSystem != null)
          'measurementSystem': measurementSystem!.name,
      };
}
