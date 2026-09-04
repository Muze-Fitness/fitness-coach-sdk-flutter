import 'dart:math' as math;

import 'package:flutter/widgets.dart';

const zingSdkHandledInsetsArg = 'handledInsets';
const zingSdkSetHandledInsetsMethod = 'setHandledInsets';

const zingSdkNoHandledInsets = <String, int>{
  'left': 0,
  'top': 0,
  'right': 0,
  'bottom': 0,
};

Map<String, int> zingSdkHandledInsets(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final windowPadding = View.of(context).viewPadding;
  final remaining = mediaQuery.viewPadding;
  final ratio = mediaQuery.devicePixelRatio;

  int handled(double windowEdge, double remainingEdge) =>
      math.max(0.0, windowEdge - remainingEdge * ratio).round();

  return <String, int>{
    'left': handled(windowPadding.left, remaining.left),
    'top': handled(windowPadding.top, remaining.top),
    'right': handled(windowPadding.right, remaining.right),
    'bottom': handled(windowPadding.bottom, remaining.bottom),
  };
}
