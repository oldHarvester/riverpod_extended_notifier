import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_toolkit/flutter_toolkit.dart';

part 'src/notifiers/notifier.dart';
part 'src/notifiers/family_notifier.dart';
part 'src/notifiers/async_notifier.dart';
part 'src/notifiers/family_async_notifier.dart';
part 'src/extended_async_notifier_base.dart';
part 'src/extended_notifier_base.dart';

class ExtendedAsyncNotifierSyncException implements Exception {}

mixin ExtendedProviderNotifierMixinBase<
  State,
  Arg extends Object?,
  ExtendedRef extends Ref<State>
> {
  ExtendedRef get ref;

  State get state;

  set state(State value);

  int _listeners = 0;

  bool _initialized = true;

  int get listeners => _listeners;

  bool get initialized => _initialized;

  bool get hasListeners => listeners > 0;

  bool get disposed => _initialized && !hasListeners;

  bool updateShouldNotify(State previous, State next);

  void listenSelf(
    void Function(State? previous, State next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
  });

  void _beforeBuild() {
    _initialized = true;
    ref.onDispose(() {
      if (!hasListeners) {}
    });
    ref.onAddListener(() {
      _listeners++;
    });
    ref.onRemoveListener(() {
      _listeners--;
    });
  }
}
