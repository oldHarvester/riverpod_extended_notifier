part of '../../riverpod_extended_notifier.dart';

abstract class ExtendedNotifier<State> extends Notifier<State>
    with
        ExtendedNotifierMixinBase<State, Null>,
        ExtendedNotifierMixin<State, Null> {
  @override
  State build() => _build();
}

abstract class ExtendedAutoDisposeNotifier<State>
    extends AutoDisposeNotifier<State>
    with
        ExtendedAutoDisposeNotifierMixinBase<State, Null>,
        ExtendedAutoDisposeNotifierMixin<State, Null> {
  @override
  State build() => _build();
}
