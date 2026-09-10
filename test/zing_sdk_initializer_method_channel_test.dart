import 'package:flutter/foundation.dart';
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

  test('init forwards configuration as method channel args', () async {
    await platform.init(
      configuration: const SdkConfiguration(
        coachesAvailability: CoachesAvailability.userGenderBased,
        genderAvailability: GenderAvailability.binary,
      ),
    );

    expect(capturedCall?.method, 'init');
    expect(
      capturedCall?.arguments,
      equals({
        'configuration': {
          'coachesAvailability': 'userGenderBased',
          'genderAvailability': 'binary',
          'healthBackgroundSync': false,
        },
      }),
    );
  });

  test('init forwards theme payload', () async {
    await platform.init(
      theme: const SdkTheme(
        colors: SdkColors(
          brandPrimary: Color(0xFFFF0000),
          bgPrimary: Color(0xA0000000),
          bgSecondary: Color(0x80123456),
        ),
        cornersRounding: SdkCornerRounding(button: SdkRadius.value(16.0)),
      ),
    );

    expect(capturedCall?.method, 'init');
    expect(
      capturedCall?.arguments,
      equals({
        'theme': {
          'colors': {
            'brand/primary': 0xFFFF0000,
            'bg/primary': 0xA0000000,
            'bg/secondary': 0x80123456,
          },
          'cornersRounding': {
            'radius/button': {'type': 'value', 'value': 16.0},
          },
        },
      }),
    );
  });

  test('login with apiKey sends correct android arguments', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await platform.login(
      const SdkAuthentication.apiKey(ios: 'ios-key', android: 'android-key'),
    );

    expect(capturedCall?.method, 'login');
    expect(
      capturedCall?.arguments,
      equals({'type': 'apiKey', 'apiKey': 'android-key'}),
    );
  });

  test('login with apiKey sends correct ios arguments', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await platform.login(
      const SdkAuthentication.apiKey(ios: 'ios-key', android: 'android-key'),
    );

    expect(capturedCall?.method, 'login');
    expect(
      capturedCall?.arguments,
      equals({'type': 'apiKey', 'apiKey': 'ios-key'}),
    );
  });

  test('login with apiKey forwards partnerUserId when provided', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await platform.login(
      const SdkAuthentication.apiKey(
        ios: 'ios-key',
        android: 'android-key',
        partnerUserId: 'user-1',
      ),
    );

    expect(capturedCall?.method, 'login');
    expect(
      capturedCall?.arguments,
      equals({
        'type': 'apiKey',
        'apiKey': 'android-key',
        'partnerUserId': 'user-1',
      }),
    );
  });

  test('login with externalToken sends the jwt', () async {
    await platform.login(
      const SdkAuthentication.externalToken('stub-token'),
    );

    expect(capturedCall?.method, 'login');
    expect(
      capturedCall?.arguments,
      equals({'type': 'externalToken', 'jwtToken': 'stub-token'}),
    );
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

  test('openScreen forwards onboarding route', () async {
    await platform.openScreen(const OnboardingRoute());

    expect(capturedCall?.method, 'openScreen');
    expect(
      capturedCall?.arguments,
      equals({'route': 'onboarding'}),
    );
  });

  test('openScreen forwards home route configuration', () async {
    await platform.openScreen(
      const HomeRoute(
        configuration: HomeScreenConfiguration(
          showCloseButton: false,
          showAskCoachButton: false,
        ),
      ),
    );

    expect(capturedCall?.method, 'openScreen');
    expect(
      capturedCall?.arguments,
      equals({
        'route': 'home',
        'showCloseButton': false,
        'showAskCoachButton': false,
      }),
    );
  });

  test('native critical error reaches the registered callback', () async {
    final callback = _StubCallback();
    platform.setCriticalErrorCallback(callback);
    addTearDown(() => platform.setCriticalErrorCallback(null));

    await _sendNativeCriticalError({
      'code': 'auth_error',
      'message': 'invalidCredentialsForRefreshRequest',
    });

    expect(callback.errors, hasLength(1));
    expect(callback.errors.single.code, 'auth_error');
    expect(
      callback.errors.single.message,
      'invalidCredentialsForRefreshRequest',
    );
  });

  test('unmapped native error code is forwarded verbatim', () async {
    final callback = _StubCallback();
    platform.setCriticalErrorCallback(callback);
    addTearDown(() => platform.setCriticalErrorCallback(null));

    await _sendNativeCriticalError({'code': 'unknown', 'message': null});

    expect(callback.errors.single.code, 'unknown');
    expect(callback.errors.single.message, isNull);
  });

  test('native critical error is dropped when no callback is set', () async {
    platform.setCriticalErrorCallback(null);

    await expectLater(
      _sendNativeCriticalError({'code': 'auth_error', 'message': 'error'}),
      completes,
    );
  });

  test('setProfileParams sends full payload', () async {
    await platform.setProfileParams(
      const ProfileParams(
        name: 'Username',
        gender: UserGender.male,
        height: 178.9,
        weight: 67.8,
        age: 23,
        measurementSystem: MeasurementSystem.metric,
      ),
    );

    expect(capturedCall?.method, 'setProfileParams');
    expect(
      capturedCall?.arguments,
      equals({
        'name': 'Username',
        'gender': 'male',
        'height': 178.9,
        'weight': 67.8,
        'age': 23,
        'measurementSystem': 'metric',
      }),
    );
  });
}

Future<void> _sendNativeCriticalError(Map<String, Object?> payload) {
  return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'zing_sdk_initializer/critical_error_handler',
        const StandardMethodCodec().encodeMethodCall(
          MethodCall('onCriticalError', payload),
        ),
        (ByteData? _) {},
      );
}

class _StubCallback implements CriticalErrorCallback {
  final errors = <PlatformException>[];

  @override
  void onCriticalError(PlatformException error) => errors.add(error);
}
