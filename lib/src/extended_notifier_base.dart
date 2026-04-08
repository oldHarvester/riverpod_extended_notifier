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
  bool _initialStateResolved = false;

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

  /// Useful if u have initial state
  @protected
  State initialStateResolver({
    State? initialState,
    required State Function() builder,
  }) {
    if (!_initialStateResolved && initialState != null) {
      _initialStateResolved = true;
      return initialState as State;
    }
    return builder();
  }

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
        _initialStateResolved = true;
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
    final state = buildState();
    final previousState = stateOrNull;
    if (!initialBuild) {
      Future.delayed(
        Duration.zero,
        () {
          _notifyEvent(
            NotifierDidInvalidateEvent(
              previous: previousState,
              state: state,
            ),
          );
        },
      );
    }
    return state;
  }
}
