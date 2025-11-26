import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:zing_sdk_initializer/zing_sdk_initializer.dart';

Future<String?> _requestFreshAuthToken() async {
  // TODO: Replace with a real backend call that returns a short-lived client token.
  debugPrint('[demo] Simulating auth token refresh request...');
  await Future<void>.delayed(const Duration(seconds: 1));
  return 'demo-refreshed-token';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const authToken = String.fromEnvironment(
    'ZING_SDK_AUTH_TOKEN',
    defaultValue: '',
  );
  final effectiveAuthToken = authToken.isEmpty ? null : authToken;

  try {
    await ZingSdkInitializer.instance.initialize(
      config: ZingSdkInitializerConfig(
        authToken: effectiveAuthToken,
        authorizationType: ZingAuthorizationType.client,
      ),
      onRefreshAuthToken: _requestFreshAuthToken,
    );
  } on PlatformException catch (error, stackTrace) {
    debugPrint('Failed to initialize Zing SDK: ${error.message}');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hello Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        textTheme: Theme.of(
          context,
        ).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const FlutterHelloScreen(),
    );
  }
}

class FlutterHelloScreen extends StatefulWidget {
  const FlutterHelloScreen({super.key});

  @override
  State<FlutterHelloScreen> createState() => _FlutterHelloScreenState();
}

class _FlutterHelloScreenState extends State<FlutterHelloScreen> {
  String _status = 'Initialized';
  String? _error;

  Future<void> _handleLogout() async {
    setState(() {
      _status = 'Logging out…';
      _error = null;
    });

    try {
      await ZingSdkInitializer.instance.logout();
      if (!mounted) return;
      setState(() {
        _status = 'Logged out on native SDK';
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _status = 'Logout failed';
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0050AC), Color(0xFF9354B9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Hello, I'm running from Flutter",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Built with the Flutter SDK',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Status: $_status',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: $_error',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 32),
                    const WorkoutPlanCardHost(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _handleLogout,
                      child: const Text('Logout via plugin'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WorkoutPlanCardHost extends StatelessWidget {
  const WorkoutPlanCardHost({super.key});

  @override
  Widget build(BuildContext context) {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: isAndroid
            ? const _AndroidWorkoutPlanCard()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.phone_android,
                    color: Colors.white70,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'WorkoutPlanCardView is available on Android only',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AndroidWorkoutPlanCard extends StatefulWidget {
  const _AndroidWorkoutPlanCard();

  @override
  State<_AndroidWorkoutPlanCard> createState() =>
      _AndroidWorkoutPlanCardState();
}

class _AndroidWorkoutPlanCardState extends State<_AndroidWorkoutPlanCard> {
  static const _viewType = 'workout-plan-card-view';
  static const double _kEpsilon = 0.5;

  MethodChannel? _methodChannel;
  double? _layoutWidth;
  double? _pendingWidthPx;
  double? _lastSentWidthPx;
  double? _contentHeight;

  @override
  void dispose() {
    _methodChannel?.setMethodCallHandler(null);
    _methodChannel = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.hasBoundedWidth && constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        if (_layoutWidth != availableWidth) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _handleWidthChange(availableWidth);
          });
        }

        return SizedBox(
          height: _effectiveHeight,
          width: double.infinity,
          child: AndroidView(
            viewType: _viewType,
            layoutDirection: TextDirection.ltr,
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            onPlatformViewCreated: _onPlatformViewCreated,
          ),
        );
      },
    );
  }

  void _onPlatformViewCreated(int id) {
    _initializeChannel(id);
    _flushPendingWidth();
  }

  void _handleWidthChange(double width) {
    if (width <= 0) return;
    _layoutWidth = width;

    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final widthPx = width * devicePixelRatio;
    _sendWidthOrDefer(widthPx);
  }

  void _initializeChannel(int id) {
    final channel = MethodChannel('workout_plan_card_view_$id');
    channel.setMethodCallHandler((call) async {
      if (call.method == 'sizeChanged') {
        final rawArgs = call.arguments;
        if (rawArgs is! Map) return;
        final args = rawArgs.cast<String, dynamic>();
        final heightPx = (args['height'] as num?)?.toDouble();
        if (heightPx == null) {
          return;
        }

        final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
        final height = heightPx / devicePixelRatio;
        _updateContentHeight(height);
      }
    });

    _methodChannel = channel;

    _flushPendingWidth();
  }

  void _flushPendingWidth() {
    final pendingWidthPx = _pendingWidthPx;
    if (pendingWidthPx != null) {
      _sendWidthOrDefer(pendingWidthPx);
    }
  }

  void _sendWidthOrDefer(double widthPx) {
    final channel = _methodChannel;
    if (channel == null) {
      _pendingWidthPx = widthPx;
      return;
    }

    if (_lastSentWidthPx != null &&
        (_lastSentWidthPx! - widthPx).abs() < _kEpsilon) {
      return;
    }

    channel.invokeMethod('setWidth', {'width': widthPx});
    _lastSentWidthPx = widthPx;
    _pendingWidthPx = null;
  }

  void _updateContentHeight(double height) {
    if (!mounted) return;

    final previous = _contentHeight;
    if (previous != null && (previous - height).abs() < _kEpsilon) {
      return;
    }

    setState(() {
      _contentHeight = height;
    });
  }

  double get _effectiveHeight {
    final height = _contentHeight;
    if (height == null || height < 1) {
      return 1;
    }
    return height;
  }
}
