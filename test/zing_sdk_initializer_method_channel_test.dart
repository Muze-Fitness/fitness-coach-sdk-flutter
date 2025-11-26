import 'dart:async';
import 'dart:typed_data';

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

  test('initialize delegates through method channel', () async {
    const config = ZingSdkInitializerConfig(
      authToken: 'client-token',
      authorizationType: ZingAuthorizationType.client,
    );
    platform.setAuthTokenRefreshHandler(() async => 'token');

    await platform.initialize(config: config);

    expect(capturedCall?.method, 'initialize');
    expect(capturedCall?.arguments, containsPair('authToken', 'client-token'));
    expect(
      capturedCall?.arguments,
      containsPair('authorizationType', 'client'),
    );
    expect(capturedCall?.arguments, containsPair('supportsAuthTokenRefresh', true));
  });

  test('updateAuthToken delegates through method channel', () async {
    await platform.updateAuthToken('fresh');

    expect(capturedCall?.method, 'updateAuthToken');
    expect(capturedCall?.arguments, containsPair('token', 'fresh'));
  });

  test('logout delegates through method channel', () async {
    await platform.logout();

    expect(capturedCall?.method, 'logout');
    expect(capturedCall?.arguments, isNull);
  });

  test('setTokenRefreshSupport toggles native delegate', () async {
    await platform.setTokenRefreshSupport(true);

    expect(capturedCall?.method, 'setTokenRefreshSupport');
    expect(capturedCall?.arguments, containsPair('enabled', true));
  });

  test('refreshAuthToken call is routed to Dart handler', () async {
    var invoked = false;
    platform.setAuthTokenRefreshHandler(() async {
      invoked = true;
      return 'fresh';
    });

    final codec = const StandardMethodCodec();
    final completer = Completer<ByteData?>();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'zing_sdk_initializer',
      codec.encodeMethodCall(const MethodCall('refreshAuthToken')),
      completer.complete,
    );

    final encodedReply = await completer.future;
    final reply = codec.decodeEnvelope(encodedReply!) as String?;

    expect(invoked, isTrue);
    expect(reply, equals('fresh'));
  });
}
