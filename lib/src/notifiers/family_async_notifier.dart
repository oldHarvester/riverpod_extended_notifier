// ignore_for_file: avoid_types_as_parameter_names

part of '../../riverpod_extended_notifier.dart';

abstract class ExtendedFamilyAsyncNotifier<State, Arg>
    extends FamilyAsyncNotifier<State, Arg>
    with
        ExtendedAsyncNotifierMixinBase<State, Arg>,
        ExtendedAsyncNotifierMixin<State, Arg> {
  ExtendedFamilyAsyncNotifier({
    State? initialState,
  }) : _initialState = initialState;

  @override
  State? get initialState => _initialState;

  final State? _initialState;

  @override
  FutureOr<State> build(Arg arg) => _build();
}

abstract class ExtendedAutoDisposeFamilyAsyncNotifier<State, Arg>
    extends AutoDisposeFamilyAsyncNotifier<State, Arg>
    with
        ExtendedAutoDisposeAsyncNotifierMixinBase<State, Arg>,
        ExtendedAutoDisposeAsyncNotifierMixin<State, Arg> {
  ExtendedAutoDisposeFamilyAsyncNotifier({
    State? initialState,
  }) : _initialState = initialState;

  @override
  State? get initialState => _initialState;

  final State? _initialState;

  @override
  FutureOr<State> build(Arg arg) => _build();
}
