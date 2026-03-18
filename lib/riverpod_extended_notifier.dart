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

  bool _initialized = false;

  int get listeners => _listeners;

  bool get initialized => _initialized;

  bool get hasListeners => listeners > 0;

  bool get disposed => _initialized && !hasListeners;

  bool get debugLifecycle => true;

  final CustomLogger _logger = CustomLogger(owner: 'ExtendedNotifier');

  void _logLifecycle(String name) {
    if (debugLifecycle) {
      _logger.log(name);
    }
  }

  @protected
  bool updateShouldNotify(State previous, State next);

  @protected
  void listenSelf(
    void Function(State? previous, State next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
  });

  @protected
  void onWillDispose() {
    _logLifecycle('will dispose');
  }

  @protected
  void onDidDisposed() {
    _logLifecycle('did disposed');
  }

  @protected
  void onCreated() {
    _logLifecycle('on created');
  }

  @protected
  void onWillLoad() {
    _logLifecycle('on will load');
  }

  @protected
  void onDidLoad(State state) {
    _logLifecycle('on did load');
  }

  @protected
  void onWillInvalidate() {
    _logLifecycle('on will invalidate');
  }

  void _beforeBuild() {
    if (!_initialized) {
      onCreated();
      _initialized = true;
    }
    ref.onDispose(() {
      if (!hasListeners) {
        onDidDisposed();
      } else {
        onWillInvalidate();
      }
    });
    ref.onAddListener(() {
      _listeners++;
      if (!hasListeners) {
        onWillDispose();
      }
    });
    ref.onRemoveListener(() {
      _listeners--;
      if (!hasListeners) {
        onWillDispose();
      }
    });
  }
}
