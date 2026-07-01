/// Controls which coaches are offered to the user.
enum CoachesAvailability {
  /// All coaches are available regardless of user gender.
  allCoaches,

  /// Only coaches matching the user's gender are available.
  userGenderBased,
}

/// Controls which gender options are exposed in the SDK UI.
enum GenderAvailability {
  /// All gender options are exposed.
  all,

  /// Only binary gender options (male/female) are exposed.
  binary,
}

/// Cross-platform SDK configuration.
class SdkConfiguration {
  const SdkConfiguration({
    this.coachesAvailability = CoachesAvailability.allCoaches,
    this.genderAvailability = GenderAvailability.all,
    this.healthBackgroundSync = false,
  });

  final CoachesAvailability coachesAvailability;
  final GenderAvailability genderAvailability;

  /// Enables background sync of health data (Health Connect on Android,
  /// HealthKit background delivery on iOS).
  ///
  /// On Android this additionally requires registering a background setup
  /// handler via [ZingSdk.registerBackgroundSetup] and declaring the background
  /// sync service in the host app manifest.
  final bool healthBackgroundSync;

  Map<String, dynamic> toMap() => {
        'coachesAvailability': coachesAvailability.name,
        'genderAvailability': genderAvailability.name,
        'healthBackgroundSync': healthBackgroundSync,
      };
}
