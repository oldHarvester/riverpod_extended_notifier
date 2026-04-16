import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

extension AsyncValueExtension<T> on AsyncValue<T> {
  Future<T> get asFuture {
    return when(
      skipError: false,
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      data: (data) {
        return Future.value(data);
      },
      error: (error, stackTrace) {
        return Future.error(error, stackTrace);
      },
      loading: () {
        return Completer<T>().future;
      },
    );
  }
}
