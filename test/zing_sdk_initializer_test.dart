import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:zing_sdk_initializer/zing_sdk_initializer.dart';
import 'package:zing_sdk_initializer/zing_sdk_initializer_method_channel.dart';
import 'package:zing_sdk_initializer/zing_sdk_initializer_platform_interface.dart';

class _MockZingSdkInitializerPlatform
    with MockPlatformInterfaceMixin
    implements ZingSdkInitializerPlatform {
  ZingSdkInitializerConfig? lastConfig;
  Future<String?> Function()? refreshHandler;
  String? lastUpdatedToken;
  bool? refreshSupportEnabled;
  bool logoutCalled = false;

  @override
  Future<void> initialize({
    required ZingSdkInitializerConfig config,
  }) async {
    lastConfig = config;
  }

  @override
  Future<void> updateAuthToken(String token) async {
    lastUpdatedToken = token;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<void> setTokenRefreshSupport(bool isEnabled) async {
    refreshSupportEnabled = isEnabled;
  }

  @override
  void setAuthTokenRefreshHandler(
    Future<String?> Function()? handler,
  ) {
    refreshHandler = handler;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ZingSdkInitializerPlatform initialPlatform =
      ZingSdkInitializerPlatform.instance;

  test('$MethodChannelZingSdkInitializer is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelZingSdkInitializer>());
  });

  test('initialize forwards config to platform', () async {
    final mockPlatform = _MockZingSdkInitializerPlatform();
    ZingSdkInitializerPlatform.instance = mockPlatform;

    const config = ZingSdkInitializerConfig(
      authToken: 'demo-token',
      authorizationType: ZingAuthorizationType.client,
    );
    Future<String?> handler() async => 'token';
    await ZingSdkInitializer.instance.initialize(
      config: config,
      onRefreshAuthToken: handler,
    );

    expect(mockPlatform.lastConfig, equals(config));
    expect(mockPlatform.refreshHandler, same(handler));
    expect(mockPlatform.refreshSupportEnabled, isTrue);
  });

  test('registerTokenRefreshDelegate toggles native support', () async {
    final mockPlatform = _MockZingSdkInitializerPlatform();
    ZingSdkInitializerPlatform.instance = mockPlatform;

    Future<String?> handler() async => 'token';
    await ZingSdkInitializer.instance.registerTokenRefreshDelegate(handler);

    expect(mockPlatform.refreshHandler, same(handler));
    expect(mockPlatform.refreshSupportEnabled, isTrue);

    await ZingSdkInitializer.instance.registerTokenRefreshDelegate(null);
    expect(mockPlatform.refreshSupportEnabled, isFalse);
  });

  test('updateAuthToken delegates to platform', () async {
    final mockPlatform = _MockZingSdkInitializerPlatform();
    ZingSdkInitializerPlatform.instance = mockPlatform;

    await ZingSdkInitializer.instance.updateAuthToken('fresh-token');

    expect(mockPlatform.lastUpdatedToken, 'fresh-token');
  });

  test('logout delegates to platform', () async {
    final mockPlatform = _MockZingSdkInitializerPlatform();
    ZingSdkInitializerPlatform.instance = mockPlatform;

    await ZingSdkInitializer.instance.logout();

    expect(mockPlatform.logoutCalled, isTrue);
  });
}
