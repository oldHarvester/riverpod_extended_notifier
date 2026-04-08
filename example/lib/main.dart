import 'package:example/example_page.dart';
import 'package:flexible_internet_checker/flexible_internet_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_extended_notifier/riverpod_extended_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final checker = FlexibleInternetChecker.createInstance(
    interval: Duration(seconds: 3),
  );
  final status = await checker.fetchStatus();
  runApp(
    MyApp(
      connectionChecker: checker,
      status: status,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.connectionChecker,
    required this.status,
  });

  final FlexibleInternetChecker connectionChecker;
  final InternetStatus status;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        RiverpodExtendedNotifierProviders.internetChecker.overrideWithValue(
          connectionChecker,
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return ExamplePage();
                        },
                      ),
                    );
                  },
                  child: Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
