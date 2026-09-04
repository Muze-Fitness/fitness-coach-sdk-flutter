import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zing_sdk_initializer/zing_sdk_initializer.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  /// Creation params of every platform view the pumped tree asked for.
  late List<Map<Object?, Object?>> createdViews;

  setUp(() {
    createdViews = <Map<Object?, Object?>>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      (call) async {
        if (call.method != 'create') return null;
        final args = call.arguments as Map<Object?, Object?>;
        final params = args['params'] as Uint8List;
        createdViews.add(
          const StandardMessageCodec().decodeMessage(
                ByteData.sublistView(params),
              )
              as Map<Object?, Object?>,
        );
        return null;
      },
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      null,
    );
  });

  /// A window with [top] and [bottom] system bars, in physical pixels. The device
  /// pixel ratio is deliberately not 1, so that the conversion is exercised too.
  void setUpWindow(WidgetTester tester, {double top = 0, double bottom = 0}) {
    tester.view.devicePixelRatio = 2;
    tester.view.viewPadding = FakeViewPadding(top: top, bottom: bottom);
    tester.view.padding = FakeViewPadding(top: top, bottom: bottom);
    addTearDown(tester.view.reset);
  }

  Map<Object?, Object?> handledInsetsOfCreatedView() {
    expect(createdViews, hasLength(1));
    return createdViews.single['handledInsets']! as Map<Object?, Object?>;
  }

  testWidgets(
    'reports the bottom inset a bottom navigation bar took over',
    (tester) async {
      setUpWindow(tester, bottom: 48);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ZingSdkHomeView(),
            bottomNavigationBar: SizedBox(height: 60),
          ),
        ),
      );

      // Scaffold hands the bottom edge to the navigation bar, so the native view
      // must not pad for it a second time.
      expect(handledInsetsOfCreatedView()['bottom'], 48);
    },
    variant: const TargetPlatformVariant({TargetPlatform.android}),
  );

  testWidgets(
    'reports nothing when the host left the insets alone',
    (tester) async {
      setUpWindow(tester, bottom: 48);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ZingSdkHomeView())),
      );

      // Nobody consumed the bottom edge, so the native view keeps padding for it.
      expect(handledInsetsOfCreatedView()['bottom'], 0);
    },
    variant: const TargetPlatformVariant({TargetPlatform.android}),
  );

  testWidgets(
    'reports the top inset a SafeArea took over',
    (tester) async {
      setUpWindow(tester, top: 72);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SafeArea(child: ZingSdkHomeView())),
        ),
      );

      expect(handledInsetsOfCreatedView()['top'], 72);
    },
    variant: const TargetPlatformVariant({TargetPlatform.android}),
  );
}
