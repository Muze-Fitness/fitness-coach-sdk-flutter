import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zing_sdk_initializer/zing_sdk_initializer.dart';

/// Exercises the workout activity API: one-shot reads, live subscriptions and
/// their lifecycle. Subscriptions close on logout, which shows up in the log
/// as "closed".
class WorkoutsTab extends StatefulWidget {
  const WorkoutsTab({super.key});

  @override
  State<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends State<WorkoutsTab> {
  final _log = <String>[];
  StreamSubscription<List<PlannedWorkout>>? _plannedSub;
  StreamSubscription<List<CompletedWorkout>>? _completedSub;
  StreamSubscription<int>? _countSub;

  ({DateTime start, DateTime end}) get _lastWeek {
    final now = DateTime.now();
    return (start: now.subtract(const Duration(days: 7)), end: now);
  }

  @override
  void dispose() {
    _plannedSub?.cancel();
    _completedSub?.cancel();
    _countSub?.cancel();
    super.dispose();
  }

  void _append(String line) {
    final time = TimeOfDay.now().format(context);
    setState(() => _log.insert(0, '$time  $line'));
  }

  String _describeError(Object error) =>
      error is PlatformException ? '${error.code}: ${error.message}' : '$error';

  String _describePlanned(List<PlannedWorkout> workouts) => workouts.isEmpty
      ? 'none'
      : workouts
          .map((w) =>
              '${w.date.month}/${w.date.day} ${w.workoutType.name} ${w.estimatedDuration.inMinutes}m')
          .join(', ');

  String _describeCompleted(List<CompletedWorkout> workouts) => workouts.isEmpty
      ? 'none'
      : workouts
          .map((w) =>
              '${w.date.month}/${w.date.day} ${w.date.hour}:${w.date.minute.toString().padLeft(2, '0')} '
              '${w.workoutType.name} ${w.actualDuration.inMinutes}m')
          .join(', ');

  Future<void> _run(String label, Future<String> Function() call) async {
    try {
      _append('$label → ${await call()}');
    } catch (error) {
      _append('$label ✗ ${_describeError(error)}');
    }
  }

  StreamSubscription<T> _observe<T>(
    String label,
    Stream<T> stream,
    String Function(T value) describe,
    VoidCallback onClosed,
  ) {
    _append('$label: subscribed');
    return stream.listen(
      (value) => _append('$label → ${describe(value)}'),
      onError: (Object error) => _append('$label ✗ ${_describeError(error)}'),
      onDone: () {
        _append('$label: closed');
        setState(onClosed);
      },
    );
  }

  void _togglePlanned() {
    if (_plannedSub != null) {
      _plannedSub!.cancel();
      _append('observePlanned: cancelled');
      setState(() => _plannedSub = null);
      return;
    }
    setState(() {
      _plannedSub = _observe(
        'observePlanned',
        ZingSdk.instance.observePlannedWorkouts(),
        _describePlanned,
        () => _plannedSub = null,
      );
    });
  }

  void _toggleCompleted() {
    if (_completedSub != null) {
      _completedSub!.cancel();
      _append('observeCompleted: cancelled');
      setState(() => _completedSub = null);
      return;
    }
    final week = _lastWeek;
    setState(() {
      _completedSub = _observe(
        'observeCompleted',
        ZingSdk.instance.observeCompletedWorkouts(week.start, week.end),
        _describeCompleted,
        () => _completedSub = null,
      );
    });
  }

  void _toggleCount() {
    if (_countSub != null) {
      _countSub!.cancel();
      _append('observeRegularCount: cancelled');
      setState(() => _countSub = null);
      return;
    }
    final week = _lastWeek;
    setState(() {
      _countSub = _observe(
        'observeRegularCount',
        ZingSdk.instance.observeCompletedWorkoutsCount(
          week.start,
          week.end,
          SdkWorkoutType.regular,
        ),
        (count) => '$count',
        () => _countSub = null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final week = _lastWeek;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => _run(
                  'getPlanned',
                  () async => _describePlanned(
                    await ZingSdk.instance.getPlannedWorkouts(),
                  ),
                ),
                child: const Text('Get planned'),
              ),
              OutlinedButton(
                onPressed: () => _run(
                  'getCompleted (7d)',
                  () async => _describeCompleted(
                    await ZingSdk.instance
                        .getCompletedWorkouts(week.start, week.end),
                  ),
                ),
                child: const Text('Get completed (7d)'),
              ),
              FilledButton.tonal(
                onPressed: _togglePlanned,
                child: Text(
                  _plannedSub == null ? 'Observe planned' : 'Stop planned',
                ),
              ),
              FilledButton.tonal(
                onPressed: _toggleCompleted,
                child: Text(
                  _completedSub == null
                      ? 'Observe completed (7d)'
                      : 'Stop completed',
                ),
              ),
              FilledButton.tonal(
                onPressed: _toggleCount,
                child: Text(
                  _countSub == null
                      ? 'Observe regular count (7d)'
                      : 'Stop count',
                ),
              ),
              TextButton(
                onPressed: () => setState(_log.clear),
                child: const Text('Clear log'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _log.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _log[index],
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
