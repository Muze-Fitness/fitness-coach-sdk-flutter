import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zing_sdk_initializer/zing_sdk_initializer.dart';
import 'package:zing_sdk_initializer/zing_sdk_initializer_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelZingSdkInitializer();
  const channel = MethodChannel('zing_sdk_initializer');

  MethodCall? capturedCall;
  setUp(() {
    capturedCall = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          capturedCall = methodCall;
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('init with apiKey sends correct arguments', () async {
    await platform.init(const SdkAuthentication.apiKey('my-key'));

    expect(capturedCall?.method, 'init');
    expect(
      capturedCall?.arguments,
      equals({'type': 'apiKey', 'apiKey': 'my-key'}),
    );
  });

  test('init with externalToken sends correct arguments', () async {
    await platform.init(SdkAuthentication.externalToken(_StubCallback()));

    expect(capturedCall?.method, 'init');
    expect(
      capturedCall?.arguments,
      equals({'type': 'externalToken'}),
    );
  });

  test('login delegates through method channel', () async {
    await platform.login();

    expect(capturedCall?.method, 'login');
    expect(capturedCall?.arguments, isNull);
  });

  test('logout delegates through method channel', () async {
    await platform.logout();

    expect(capturedCall?.method, 'logout');
    expect(capturedCall?.arguments, isNull);
  });

  test('openScreen forwards simple route', () async {
    await platform.openScreen(const CustomWorkoutRoute());

    expect(capturedCall?.method, 'openScreen');
    expect(
      capturedCall?.arguments,
      equals({'route': 'custom_workout'}),
    );
  });

  test('openScreen forwards parameterized WorkoutPreviewRoute', () async {
    await platform.openScreen(const WorkoutPreviewRoute('w-1'));

    expect(capturedCall?.method, 'openScreen');
    expect(
      capturedCall?.arguments,
      equals({'route': 'workout_preview', 'workoutId': 'w-1'}),
    );
  });

  test('openScreen forwards parameterized WorkoutResultRoute', () async {
    await platform.openScreen(const WorkoutResultRoute('r-1'));

    expect(capturedCall?.method, 'openScreen');
    expect(
      capturedCall?.arguments,
      equals({'route': 'workout_result', 'workoutResultId': 'r-1'}),
    );
  });
}

class _StubCallback implements AuthTokenCallback {
  @override
  Future<String> getAuthToken() async => 'stub-token';

  @override
  void onTokenInvalid() {}
}
