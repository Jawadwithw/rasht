import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rasht/rasht.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Rasht.enabled = true;
  Rasht.initialize(appRunner: () => runApp(const RashtExampleApp()));
}

class RashtExampleApp extends StatefulWidget {
  const RashtExampleApp({super.key});

  @override
  State<RashtExampleApp> createState() => _RashtExampleAppState();
}

class _RashtExampleAppState extends State<RashtExampleApp> {
  late final Dio _dio;

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    _dio.interceptors.add(RashtInterceptor(RashtStore.instance));
  }

  Future<void> _sendSampleRequest() async {
    await _dio.get('https://jsonplaceholder.typicode.com/todos/1');
  }

  void _triggerTestError() {
    Future<void>.delayed(Duration.zero, () {
      throw StateError('Rasht example: test async error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rasht Example',
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF18537C)),
      ),
      builder: (context, child) {
        return RashtOverlay(
          navigatorKey: _navigatorKey,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(
        appBar: AppBar(title: const Text('Rasht Example')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Tap the umbrella button to open the full-screen inspector.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _sendSampleRequest,
                  child: const Text('Send sample GET request'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _triggerTestError,
                  child: const Text('Trigger test error'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
