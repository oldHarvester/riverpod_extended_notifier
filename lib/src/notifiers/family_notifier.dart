// ignore_for_file: avoid_types_as_parameter_names

part of '../../riverpod_extended_notifier.dart';

abstract class ExtendedFamilyNotifier<State, Arg>
    extends FamilyNotifier<State, Arg>
    with
        ExtendedNotifierMixinBase<State, Arg>,
        ExtendedNotifierMixin<State, Arg> {
  ExtendedFamilyNotifier({
    State? initialState,
  }) : _initialState = initialState;

  @override
  State? get initialState => _initialState;

  final State? _initialState;

  @override
  State build(Arg arg) => _build();
}

abstract class ExtendedAutoDisposeFamilyNotifier<State, Arg>
    extends AutoDisposeFamilyNotifier<State, Arg>
    with
        ExtendedAutoDisposeNotifierMixinBase<State, Arg>,
        ExtendedAutoDisposeNotifierMixin<State, Arg> {
  ExtendedAutoDisposeFamilyNotifier({
    State? initialState,
  }) : _initialState = initialState;

  @override
  State? get initialState => _initialState;

  final State? _initialState;

  @override
  State build(Arg arg) => _build();
}
