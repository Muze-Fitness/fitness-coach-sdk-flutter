import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'zing_sdk_initializer_platform_interface.dart';

/// An implementation of [ZingSdkInitializerPlatform] that uses method channels.
class MethodChannelZingSdkInitializer extends ZingSdkInitializerPlatform {
  MethodChannelZingSdkInitializer();

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('zing_sdk_initializer');

  @override
  Future<void> initialize() {
    return methodChannel.invokeMethod<void>('initialize');
  }

  @override
  Future<void> logout() {
    return methodChannel.invokeMethod<void>('logout');
  }

  @override
  Future<void> openScreen(String routeId) {
    return methodChannel.invokeMethod<void>(
      'openScreen',
      <String, String>{'route': routeId},
    );
  }
}
