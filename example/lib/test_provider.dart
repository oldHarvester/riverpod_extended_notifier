import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_extended_notifier/riverpod_extended_notifier.dart';

final testProvider = AutoDisposeNotifierProvider<TestNotifier, List<int>>(
  () {
    return TestNotifier();
  },
);

class TestNotifier extends ExtendedAutoDisposeNotifier<List<int>> {
  @override
  String? get debugLabel => 'TestNotifier';

  @override
  bool get debugLifecycle => true;

  @override
  List<int> buildState() {
    return List.generate(
      10,
      (index) => Random().nextInt(10),
    );
  }
}
