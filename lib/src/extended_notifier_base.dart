part of '../riverpod_extended_notifier.dart';

typedef ExtendedNotifierMixin<State, Arg extends Object?> =
    ExtendedNotifierBase<State, Arg, NotifierProviderRef<State>>;

typedef ExtendedNotifierMixinBase<State, Arg extends Object?> =
    ExtendedProviderNotifierMixinBase<State, Arg, NotifierProviderRef<State>>;

typedef ExtendedAutoDisposeNotifierMixin<State, Arg extends Object?> =
    ExtendedNotifierBase<State, Arg, AutoDisposeNotifierProviderRef<State>>;

typedef ExtendedAutoDisposeNotifierMixinBase<State, Arg extends Object?> =
    ExtendedProviderNotifierMixinBase<
      State,
      Arg,
      AutoDisposeNotifierProviderRef<State>
    >;

mixin ExtendedNotifierBase<
  State,
  Arg extends Object?,
  ExtendedRef extends Ref<State>
>
    on ExtendedProviderNotifierMixinBase<State, Arg, ExtendedRef> {
  @protected
  State buildState();

  State? get stateOrNull;

  final FlexibleEquality _equality = FlexibleEquality();

  @override
  bool updateShouldNotify(State previous, State next) {
    return _equality.notEquals(previous, next);
  }

  @override
  void _onCreated() {
    _notifyEvent(NotifierCreateEvent());
  }

  @override
  void _onListenersChanged(int was, int now) {
    if (now > was) {
      _notifyEvent(NotifierAddedListenerEvent(total: now));
    } else {
      _notifyEvent(NotifierRemovedListenerEvent(total: now));
    }
    if (now <= 0) {
      _notifyEvent(NotifierCancelEvent());
    }
  }

  void onEvent(NotifierEvent<State> event) {}

  void _notifyEvent(NotifierEvent<State> event) {
    if (debugEvents) {
      _logEvents(event.debugLabel);
    }
    onEvent(event);
    switch (event) {
      case NotifierCreateEvent<State> _:
        onCreate();
        break;
      case NotifierWillInvalidateEvent<State> _:
        onWillInvalidate();
        break;
      case NotifierDidInvalidateEvent<State> _:
        onDidInvalidate();
        break;
      case NotifierCancelEvent<State> _:
        onCancel();
        break;
      case NotifierResumeEvent<State> _:
        onResume();
        break;
      case NotifierAddedListenerEvent<State> _:
        break;
      case NotifierRemovedListenerEvent<State> _:
        break;
      case NotifierDisposeEvent<State> _:
        onDispose();
        break;
    }
  }

  @protected
  void onCreate() {}

  @protected
  void onWillInvalidate() {}

  @protected
  void onDidInvalidate() {}

  @protected
  void onDispose() {}

  @protected
  void onCancel() {}

  @protected
  void onResume() {}

  State _build() {
    ref.onDispose(
      () {
        if (hasListeners) {
          _notifyEvent(
            NotifierWillInvalidateEvent(),
          );
        } else {
          _notifyEvent(NotifierDisposeEvent());
        }
      },
    );
    ref.onResume(
      () {
        _notifyEvent(NotifierResumeEvent());
      },
    );
    final initialBuild = !_initialized;
    _beforeBuild();
    final initialState = buildState();
    final previousState = stateOrNull;
    try {
      return initialState;
    } finally {
      if (!initialBuild) {
        _notifyEvent(
          NotifierDidInvalidateEvent(
            previous: previousState,
            state: initialState,
          ),
        );
      }
    }
  }
}
