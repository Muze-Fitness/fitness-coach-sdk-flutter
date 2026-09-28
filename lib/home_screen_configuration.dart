/// Options for the native home screen.
class HomeScreenConfiguration {
  const HomeScreenConfiguration({
    required this.showCloseButton,
    this.showAskCoachButton = true,
    this.showBodyScanWidget = true,
  });

  /// Whether the program screen shows a close/dismiss button.
  final bool showCloseButton;

  /// Whether the program screen shows the Ask Coach button.
  final bool showAskCoachButton;

  /// Whether the program screen shows the Body Scan widget.
  final bool showBodyScanWidget;

  Map<String, dynamic> toMap() => {
        'showCloseButton': showCloseButton,
        'showAskCoachButton': showAskCoachButton,
        'showBodyScanWidget': showBodyScanWidget,
      };
}
