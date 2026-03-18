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
  State buildState();

  State _build() {
    _beforeBuild();
    return buildState();
  }
}
