import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_extended_notifier/riverpod_extended_notifier.dart';

final testAsyncProvider =
    AutoDisposeAsyncNotifierProvider<TestAsyncNotifier, List<int>>(
      () {
        return TestAsyncNotifier();
      },
    );

class TestAsyncNotifier extends ExtendedAutoDisposeAsyncNotifier<List<int>> {
  final Duration duration = Duration(seconds: 2);

  @override
  String? get debugLabel => 'TestAsyncNotifier';

  @override
  bool get debugLifecycle => true;

  void add(int id) async {
    executeUpdate(
      (state) async {
        await Future.delayed(Duration(seconds: 1));
        return [...state, id];
      },
    );
    await Future.delayed(duration ~/ 2);
    ref.invalidateSelf();
  }

  @override
  int? get maxRetries => super.maxRetries;

  @override
  bool get disableRetries => false;

  @override
  Duration? get retriesTimeoutDuration => super.retriesTimeoutDuration;

  @override
  Duration get retryRestartDuration => super.retryRestartDuration;

  @override
  FutureOr<List<int>> buildState() async {
    await Future.delayed(duration);
    if (retries < 4) {
      throw UnimplementedError('Some error: $retries');
    }
    return List.generate(5, (index) => Random().nextInt(10));
  }
}
