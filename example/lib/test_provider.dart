import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_extended_notifier/riverpod_extended_notifier.dart';

final testProvider = AutoDisposeAsyncNotifierProvider<TestNotifier, List<int>>(
  () {
    return TestNotifier();
  },
);

class TestNotifier extends ExtendedAutoDisposeAsyncNotifier<List<int>> {
  final Duration duration = Duration(seconds: 3);

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
  FutureOr<List<int>> buildState() async {
    await Future.delayed(duration);
    return List.generate(5, (index) => Random().nextInt(10));
  }
}
