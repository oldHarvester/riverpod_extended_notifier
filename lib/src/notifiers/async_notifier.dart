part of '../../riverpod_extended_notifier.dart';

abstract class ExtendedAsyncNotifier<State> extends AsyncNotifier<State>
    with
        ExtendedAsyncNotifierMixinBase<State, Null>,
        ExtendedAsyncNotifierMixin<State, Null> {
  @override
  FutureOr<State> build() => _build();
}

abstract class ExtendedAutoDisposeAsyncNotifier<State>
    extends AutoDisposeAsyncNotifier<State>
    with
        ExtendedAutoDisposeAsyncNotifierMixinBase<State, Null>,
        ExtendedAutoDisposeAsyncNotifierMixin<State, Null> {
  @override
  FutureOr<State> build() => _build();
}
