import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_extended_notifier/riverpod_extended_notifier.dart';

final transactionCheckProvider =
    AutoDisposeAsyncNotifierProvider<TransactionCheckNotifier, List<int>>(
      () {
        return TransactionCheckNotifier();
      },
    );

class TransactionCheckNotifier
    extends ExtendedAutoDisposeAsyncNotifier<List<int>> {
  @override
  String? get debugLabel => 'TransactionCheck';

  @override
  bool get debugLifecycle => true;

  @override
  bool get debugEvents => false;

  Future<List<int>> fetchItems() async {
    return safeFuture;
  }

  @override
  FutureOr<List<int>> buildState() {
    return Future.delayed(
      Duration(seconds: 5),
      () {
        return List.generate(10, (index) => Random().nextInt(10));
      },
    );
  }
}
