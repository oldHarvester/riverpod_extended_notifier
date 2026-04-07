// ignore_for_file: avoid_types_as_parameter_names

part of '../../riverpod_extended_notifier.dart';

abstract class ExtendedAsyncNotifier<State> extends AsyncNotifier<State>
    with
        ExtendedAsyncNotifierMixinBase<State, Null>,
        ExtendedAsyncNotifierMixin<State, Null> {
  ExtendedAsyncNotifier({
    State? initialState,
  }) : _initialState = initialState;

  @override
  State? get initialState => _initialState;

  final State? _initialState;

  @override
  FutureOr<State> build() => _build();
}

abstract class ExtendedAutoDisposeAsyncNotifier<State>
    extends AutoDisposeAsyncNotifier<State>
    with
        ExtendedAutoDisposeAsyncNotifierMixinBase<State, Null>,
        ExtendedAutoDisposeAsyncNotifierMixin<State, Null> {
  ExtendedAutoDisposeAsyncNotifier({
    State? initialState,
  }) : _initialState = initialState;

  @override
  State? get initialState => _initialState;

  final State? _initialState;

  @override
  FutureOr<State> build() => _build();
}
