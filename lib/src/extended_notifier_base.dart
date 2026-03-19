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

  @override
  bool get debugLifecycle => true;

  State? get stateOrNull;

  @override
  bool updateShouldNotify(State previous, State next) {
    return FlexibleEquality.equals(previous, next);
  }

  State _build() {
    ref.onDispose(() {
      if (hasListeners) {
        onInvalidate();
        onWillLoad(false);
      }
    });
    final initialBuild = !initialized;
    _beforeBuild();
    if (initialBuild) {
      onWillLoad(true);
    }
    final initialState = buildState();
    try {
      return initialState;
    } finally {
      final state = stateOrNull;
      if (state != null) {
        onDidLoad(state);
      } else {
        onDidLoad(initialState);
      }
    }
  }
}
