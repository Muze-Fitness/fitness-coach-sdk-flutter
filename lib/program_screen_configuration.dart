/// Options for the native program screen (`ZingSDK.ProgramScreenConfiguration`).
class ProgramScreenConfiguration {
  const ProgramScreenConfiguration({
    required this.showCloseButton,
    this.showAskCoachButton = true,
  });

  /// Whether the program screen shows a close/dismiss button.
  final bool showCloseButton;

  /// Whether the program screen shows the Ask Coach button.
  final bool showAskCoachButton;

  Map<String, dynamic> toMap() => {
        'showCloseButton': showCloseButton,
        'showAskCoachButton': showAskCoachButton,
      };
}
