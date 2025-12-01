import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:zing_sdk_initializer/zing_sdk_initializer.dart';
import 'package:zing_sdk_initializer/zing_sdk_initializer_method_channel.dart';
import 'package:zing_sdk_initializer/zing_sdk_initializer_platform_interface.dart';

class _MockZingSdkInitializerPlatform
    with MockPlatformInterfaceMixin
    implements ZingSdkInitializerPlatform {
  int initializeCount = 0;
  int logoutCount = 0;
  int openScreenCount = 0;
  String? lastOpenedRouteId;

  @override
  Future<void> initialize() async {
    initializeCount += 1;
  }

  @override
  Future<void> logout() async {
    logoutCount += 1;
  }

  @override
  Future<void> openScreen(String routeId) async {
    openScreenCount += 1;
    lastOpenedRouteId = routeId;
  }

  void reset() {
    initializeCount = 0;
    logoutCount = 0;
    openScreenCount = 0;
    lastOpenedRouteId = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ZingSdkInitializerPlatform initialPlatform =
      ZingSdkInitializerPlatform.instance;

  test('$MethodChannelZingSdkInitializer is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelZingSdkInitializer>());
  });

  group('ZingSdkInitializer', () {
    late _MockZingSdkInitializerPlatform mockPlatform;

    setUp(() async {
      mockPlatform = _MockZingSdkInitializerPlatform();
      ZingSdkInitializerPlatform.instance = mockPlatform;
      await ZingSdkInitializer.instance.logout();
      mockPlatform.reset();
    });

    test('initialize delegates to platform once per lifecycle', () async {
      await ZingSdkInitializer.instance.initialize();
      await ZingSdkInitializer.instance.initialize();

      expect(mockPlatform.initializeCount, equals(1));
    });

    test('logout delegates to platform and allows reinitialization', () async {
      await ZingSdkInitializer.instance.initialize();
      expect(mockPlatform.initializeCount, equals(1));

      await ZingSdkInitializer.instance.logout();
      expect(mockPlatform.logoutCount, equals(1));

      mockPlatform.reset();
      await ZingSdkInitializer.instance.initialize();
      expect(mockPlatform.initializeCount, equals(1));
    });

    test('openScreen throws when SDK is not initialized', () async {
      expect(
        () => ZingSdkInitializer.instance.openScreen(
          ZingSdkScreen.aiAssistant,
        ),
        throwsStateError,
      );
    });

    test('openScreen delegates once SDK is initialized', () async {
      await ZingSdkInitializer.instance.initialize();

      await ZingSdkInitializer.instance.openScreen(
        ZingSdkScreen.fullSchedule,
      );

      expect(mockPlatform.openScreenCount, equals(1));
      expect(mockPlatform.lastOpenedRouteId, equals('full_schedule'));
    });
  });
}
