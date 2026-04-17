import 'dart:developer' as dev;

import 'package:example/transaction_check_provider.dart';
import 'package:flexible_internet_checker/flexible_internet_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_extended_notifier/riverpod_extended_notifier.dart';

import 'example_page.dart';

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
    Widget buildButton({
      required String title,
      VoidCallback? onPressed,
    }) {
      return ElevatedButton(
        onPressed: onPressed,
        child: Text(title),
      );
    }

    return ProviderScope(
      overrides: [
        RiverpodExtendedNotifierProviders.internetChecker.overrideWithValue(
          connectionChecker,
        ),
      ],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, child) {
            return Scaffold(
              body: SizedBox.expand(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildButton(
                      title: 'Open',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return ExamplePage();
                            },
                          ),
                        );
                      },
                    ),
                    buildButton(
                      title: 'Run transaction',
                      onPressed: () {
                        ref.transaction(
                          (ref) async {
                            dev.log('start transaction', name: 'Transaction');
                            final controller = ref.read(
                              transactionCheckProvider.notifier,
                            );
                            final items = await controller.fetchItems();
                            dev.log(
                              'end transaction: $items',
                              name: 'Transaction',
                            );
                            return items;
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
