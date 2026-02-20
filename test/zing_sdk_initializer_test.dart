import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:zing_sdk_initializer/zing_sdk_initializer.dart';
import 'package:zing_sdk_initializer/zing_sdk_initializer_method_channel.dart';
import 'package:zing_sdk_initializer/zing_sdk_initializer_platform_interface.dart';

class _MockZingSdkInitializerPlatform
    with MockPlatformInterfaceMixin
    implements ZingSdkInitializerPlatform {
  int initCount = 0;
  int loginCount = 0;
  int logoutCount = 0;
  int openScreenCount = 0;
  SdkAuthentication? lastAuth;
  StartingRoute? lastRoute;

  final _authStateController = StreamController<SdkAuthState>.broadcast();

  @override
  Future<void> init(SdkAuthentication auth) async {
    initCount += 1;
    lastAuth = auth;
  }

  @override
  Future<void> login() async {
    loginCount += 1;
  }

  @override
  Future<void> logout() async {
    logoutCount += 1;
  }

  @override
  Future<void> openScreen(StartingRoute route) async {
    openScreenCount += 1;
    lastRoute = route;
  }

  @override
  Stream<SdkAuthState> get authStateStream => _authStateController.stream;

  void emitAuthState(SdkAuthState state) => _authStateController.add(state);

  void reset() {
    initCount = 0;
    loginCount = 0;
    logoutCount = 0;
    openScreenCount = 0;
    lastAuth = null;
    lastRoute = null;
  }

  void dispose() => _authStateController.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ZingSdkInitializerPlatform initialPlatform =
      ZingSdkInitializerPlatform.instance;

  test('$MethodChannelZingSdkInitializer is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelZingSdkInitializer>());
  });

  group('ZingSdk', () {
    late _MockZingSdkInitializerPlatform mockPlatform;

    setUp(() {
      mockPlatform = _MockZingSdkInitializerPlatform();
      ZingSdkInitializerPlatform.instance = mockPlatform;
    });

    tearDown(() {
      mockPlatform.dispose();
    });

    test('init delegates to platform with apiKey auth', () async {
      const auth = SdkAuthentication.apiKey('test-key');
      await ZingSdk.instance.init(auth);

      expect(mockPlatform.initCount, equals(1));
      expect(mockPlatform.lastAuth, isA<SdkApiKeyAuth>());
      expect((mockPlatform.lastAuth as SdkApiKeyAuth).apiKey, 'test-key');
    });

    test('login delegates to platform', () async {
      await ZingSdk.instance.login();

      expect(mockPlatform.loginCount, equals(1));
    });

    test('logout delegates to platform', () async {
      await ZingSdk.instance.logout();

      expect(mockPlatform.logoutCount, equals(1));
    });

    test('openScreen delegates simple route', () async {
      await ZingSdk.instance.openScreen(const AiAssistantRoute());

      expect(mockPlatform.openScreenCount, equals(1));
      expect(mockPlatform.lastRoute, isA<AiAssistantRoute>());
    });

    test('openScreen delegates parameterized route', () async {
      await ZingSdk.instance.openScreen(const WorkoutPreviewRoute('w123'));

      expect(mockPlatform.openScreenCount, equals(1));
      final route = mockPlatform.lastRoute as WorkoutPreviewRoute;
      expect(route.workoutId, 'w123');
    });

    test('authState stream emits state changes', () async {
      final states = <SdkAuthState>[];
      final sub = ZingSdk.instance.authState.listen(states.add);

      mockPlatform.emitAuthState(const SdkAuthStateInProgress());
      mockPlatform.emitAuthState(const SdkAuthStateAuthenticated('user-1'));

      await Future<void>.delayed(Duration.zero);

      expect(states, hasLength(2));
      expect(states[0], isA<SdkAuthStateInProgress>());
      expect(states[1], isA<SdkAuthStateAuthenticated>());
      expect((states[1] as SdkAuthStateAuthenticated).partnerUserId, 'user-1');

      await sub.cancel();
    });
  });

  group('StartingRoute serialization', () {
    test('simple route serializes correctly', () {
      const route = CustomWorkoutRoute();
      expect(route.toMap(), {'route': 'custom_workout'});
    });

    test('WorkoutPreviewRoute serializes with workoutId', () {
      const route = WorkoutPreviewRoute('abc');
      expect(route.toMap(), {'route': 'workout_preview', 'workoutId': 'abc'});
    });

    test('WorkoutResultRoute serializes with workoutResultId', () {
      const route = WorkoutResultRoute('xyz');
      expect(
        route.toMap(),
        {'route': 'workout_result', 'workoutResultId': 'xyz'},
      );
    });
  });

  group('SdkAuthState deserialization', () {
    test('loggedOut', () {
      final state = SdkAuthState.fromMap({'state': 'loggedOut'});
      expect(state, isA<SdkAuthStateLoggedOut>());
    });

    test('inProgress', () {
      final state = SdkAuthState.fromMap({'state': 'inProgress'});
      expect(state, isA<SdkAuthStateInProgress>());
    });

    test('error', () {
      final state = SdkAuthState.fromMap({'state': 'error'});
      expect(state, isA<SdkAuthStateError>());
    });

    test('authenticated', () {
      final state = SdkAuthState.fromMap({
        'state': 'authenticated',
        'partnerUserId': 'u-42',
      });
      expect(state, isA<SdkAuthStateAuthenticated>());
      expect((state as SdkAuthStateAuthenticated).partnerUserId, 'u-42');
    });

    test('unknown state throws', () {
      expect(
        () => SdkAuthState.fromMap({'state': 'bogus'}),
        throwsArgumentError,
      );
    });
  });
}
