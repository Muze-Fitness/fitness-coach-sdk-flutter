import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zing_sdk_initializer/zing_sdk_initializer.dart';
import 'package:zing_sdk_initializer/zing_sdk_initializer_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('zing_sdk_initializer');
  final calls = <MethodCall>[];
  Object? Function(MethodCall call) respond = (_) => null;
  late MethodChannelZingSdkInitializer platform;

  final start = DateTime.fromMillisecondsSinceEpoch(1000);
  final end = DateTime.fromMillisecondsSinceEpoch(5000);
  final plannedMap = {
    'workoutType': 'recovery',
    'date': 1763337600000,
    'estimatedDuration': 1200000,
  };
  final completedMap = {
    'workoutType': 'regular',
    'date': 1763370000000,
    'actualDuration': 1500000,
  };

  setUp(() {
    platform = MethodChannelZingSdkInitializer();
    calls.clear();
    respond = (_) => null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return respond(call);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  int subscriptionId(MethodCall call) => (call.arguments as Map)['id'] as int;

  test('getPlannedWorkouts parses native maps', () async {
    respond = (_) => [plannedMap];

    final workouts = await platform.getPlannedWorkouts();

    expect(calls.single.method, 'getPlannedWorkouts');
    expect(workouts, [
      PlannedWorkout(
        workoutType: SdkWorkoutType.recovery,
        date: DateTime.fromMillisecondsSinceEpoch(1763337600000),
        estimatedDuration: const Duration(minutes: 20),
      ),
    ]);
  });

  test('getCompletedWorkouts sends the interval in epoch millis', () async {
    respond = (_) => [completedMap];

    final workouts = await platform.getCompletedWorkouts(start, end);

    expect(calls.single.method, 'getCompletedWorkouts');
    expect(calls.single.arguments, {'start': 1000, 'end': 5000});
    expect(workouts.single.actualDuration, const Duration(minutes: 25));
    expect(workouts.single.workoutType, SdkWorkoutType.regular);
  });

  test('an interval ending before it starts is rejected', () {
    expect(
      () => platform.getCompletedWorkouts(end, start),
      throwsArgumentError,
    );
  });

  test('native error codes surface as PlatformException', () async {
    respond = (_) => throw PlatformException(code: 'not_logged_in');

    await expectLater(
      platform.getPlannedWorkouts(),
      throwsA(isA<PlatformException>().having(
        (e) => e.code,
        'code',
        WorkoutActivityErrorCode.notLoggedIn,
      )),
    );
  });

  test('observeCompletedWorkouts emits native events until done', () async {
    final events = <List<CompletedWorkout>>[];
    var done = false;
    platform
        .observeCompletedWorkouts(start, end)
        .listen(events.add, onDone: () => done = true);
    await pumpEventQueue();

    final subscribe = calls.single;
    final id = subscriptionId(subscribe);
    expect(subscribe.method, 'observeCompletedWorkouts');
    expect(subscribe.arguments, {'start': 1000, 'end': 5000, 'id': id});

    await _sendEvent('onData', {
      'id': id,
      'data': [completedMap],
    });
    await _sendEvent('onData', {'id': id, 'data': []});
    await _sendEvent('onDone', {'id': id});
    await pumpEventQueue();

    expect(events.map((it) => it.length), [1, 0]);
    expect(done, isTrue);
    expect(
      calls.map((it) => it.method),
      isNot(contains('cancelWorkoutActivity')),
    );
  });

  test('a native stream error closes the stream', () async {
    final errors = <Object>[];
    var done = false;
    platform
        .observePlannedWorkouts()
        .listen(null, onError: errors.add, onDone: () => done = true);
    await pumpEventQueue();

    await _sendEvent('onError', {
      'id': subscriptionId(calls.single),
      'code': 'workout_activity_failed',
      'message': 'boom',
    });
    await pumpEventQueue();

    expect(errors.single, isA<PlatformException>());
    expect(done, isTrue);
  });

  test('a rejected subscription emits the error', () async {
    respond = (_) => throw PlatformException(code: 'onboarding_not_completed');

    await expectLater(
      platform.observePlannedWorkouts(),
      emitsError(isA<PlatformException>().having(
        (e) => e.code,
        'code',
        WorkoutActivityErrorCode.onboardingNotCompleted,
      )),
    );
  });

  test('cancelling a subscription cancels it natively', () async {
    final subscription = platform.observePlannedWorkouts().listen(null);
    await pumpEventQueue();
    final id = subscriptionId(calls.single);

    await subscription.cancel();

    expect(calls.last.method, 'cancelWorkoutActivity');
    expect(calls.last.arguments, {'id': id});
  });

  test('each subscription gets its own id', () async {
    final first = platform.observePlannedWorkouts().listen(null);
    final second = platform.observeCompletedWorkouts(start, end).listen(null);
    await pumpEventQueue();

    expect(calls.map(subscriptionId).toSet(), hasLength(2));
    await first.cancel();
    await second.cancel();
  });
}

Future<void> _sendEvent(String method, Map<String, Object?> args) {
  return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
    'zing_sdk_initializer/workout_activity',
    const StandardMethodCodec().encodeMethodCall(MethodCall(method, args)),
    (ByteData? _) {},
  );
}
