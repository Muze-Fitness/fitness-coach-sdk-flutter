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

  test('init with apiKey sends correct android arguments', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await platform.init(
      authentication: const SdkAuthentication.apiKey(
        ios: 'ios-key',
        android: 'android-key',
      ),
    );

    expect(capturedCall?.method, 'init');
    expect(
      capturedCall?.arguments,
      equals({'type': 'apiKey', 'apiKey': 'android-key'}),
    );
  });

  test('init with apiKey sends correct ios arguments', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await platform.init(
      authentication: const SdkAuthentication.apiKey(
        ios: 'ios-key',
        android: 'android-key',
      ),
    );

    expect(capturedCall?.method, 'init');
    expect(
      capturedCall?.arguments,
      equals({'type': 'apiKey', 'apiKey': 'ios-key'}),
    );
  });

  test('init with externalToken sends correct arguments', () async {
    await platform.init(
      authentication: SdkAuthentication.externalToken(_StubCallback()),
    );

    expect(capturedCall?.method, 'init');
    expect(
      capturedCall?.arguments,
      equals({'type': 'externalToken'}),
    );
  });

  test('init forwards configuration as method channel args', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await platform.init(
      authentication: const SdkAuthentication.apiKey(
        ios: 'ios-key',
        android: 'android-key',
      ),
      configuration: const SdkConfiguration(
        coachesAvailability: CoachesAvailability.userGenderBased,
        genderAvailability: GenderAvailability.binary,
      ),
    );

    expect(capturedCall?.method, 'init');
    expect(
      capturedCall?.arguments,
      equals({
        'type': 'apiKey',
        'apiKey': 'ios-key',
        'configuration': {
          'coachesAvailability': 'userGenderBased',
          'genderAvailability': 'binary',
          'healthBackgroundSync': false,
        },
      }),
    );
  });

  test('init forwards theme payload', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await platform.init(
      authentication: const SdkAuthentication.apiKey(
        ios: 'ios-key',
        android: 'android-key',
      ),
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
        'type': 'apiKey',
        'apiKey': 'ios-key',
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

class _StubCallback implements AuthTokenCallback {
  @override
  Future<String> getAuthToken() async => 'stub-token';

  @override
  void onTokenInvalid() {}
}
