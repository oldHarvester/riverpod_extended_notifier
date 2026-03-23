import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_toolkit/flutter_toolkit.dart';
import 'package:riverpod_extended_notifier/src/events/notifier_event_base.dart';

part 'src/notifiers/notifier.dart';
part 'src/notifiers/family_notifier.dart';
part 'src/notifiers/async_notifier.dart';
part 'src/notifiers/family_async_notifier.dart';
part 'src/extended_async_notifier_base.dart';
part 'src/extended_notifier_base.dart';

class ExtendedAsyncNotifierSyncException implements Exception {}

enum NotifierLifecycleState {
  idle,
  paused,
  working,
  disposed,
}

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

  bool get debugEvents => false;

  bool get debugLifecycle => false;

  String? get debugLabel => null;

  NotifierLifecycleState _lifecycleState = NotifierLifecycleState.idle;

  NotifierLifecycleState get lifecycleState => _lifecycleState;

  late final CustomLogger _logger = CustomLogger(
    owner: debugLabel ?? 'ExtendedNotifier',
  );

  void _logEvents(String name) {
    if (debugEvents) {
      _logger.log(name);
    }
  }

  void _logLifecycle(NotifierLifecycleState state) {
    if (debugLifecycle) {
      _logger.log('lifecycle changed - ${state.name}');
    }
  }

  @protected
  bool updateShouldNotify(State previous, State next);

  void onLifecycleChanged(
    NotifierLifecycleState previous,
    NotifierLifecycleState next,
  ) {}

  @protected
  void listenSelf(
    void Function(State? previous, State next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
  });

  @protected
  void _onCreated() {}

  void _onListenersChanged(int was, int now) {}

  void _changeLifecycle(NotifierLifecycleState state) {
    final previous = _lifecycleState;
    if (previous != state) {
      _lifecycleState = state;
      onLifecycleChanged(previous, state);
      _logLifecycle(state);
    }
  }

  void _beforeBuild() {
    if (!_initialized) {
      _onCreated();
      _changeLifecycle(NotifierLifecycleState.working);
      _initialized = true;
    }
    ref.onAddListener(
      () {
        _onListenersChanged(_listeners, ++_listeners);
      },
    );
    ref.onDispose(
      () {
        if (!hasListeners) {
          _changeLifecycle(NotifierLifecycleState.disposed);
        }
      },
    );
    ref.onResume(
      () {
        _changeLifecycle(NotifierLifecycleState.working);
      },
    );
    ref.onRemoveListener(
      () {
        _onListenersChanged(_listeners, --_listeners);
        if (!hasListeners) {
          _changeLifecycle(NotifierLifecycleState.paused);
        }
      },
    );
  }
}
