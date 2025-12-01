import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:flutter/services.dart';

/// Host widget that renders the native WorkoutPlanCard platform view.
class WorkoutPlanCardHost extends StatelessWidget {
  const WorkoutPlanCardHost({
    super.key,
    this.unsupportedPlaceholder,
  });

  /// Optional widget to render when the platform view is not supported.
  final Widget? unsupportedPlaceholder;

  static const _viewType = 'workout-plan-card-view';

  @override
  Widget build(BuildContext context) {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0050AC), Color(0xFF9354B9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isAndroid
            ? const _AndroidWorkoutPlanCard()
            : unsupportedPlaceholder ?? const _UnsupportedPlatformNotice(),
      ),
    );
  }
}

class _AndroidWorkoutPlanCard extends StatelessWidget {
  const _AndroidWorkoutPlanCard();

  @override
  Widget build(BuildContext context) {
    return const AndroidView(
      viewType: WorkoutPlanCardHost._viewType,
      layoutDirection: TextDirection.ltr,
      hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{},
    );
  }
}

class _UnsupportedPlatformNotice extends StatelessWidget {
  const _UnsupportedPlatformNotice();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.phone_android,
            color: Colors.white70,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            'WorkoutPlanCardView is available on Android only',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );
  }
}

