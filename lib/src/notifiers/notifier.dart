// ignore_for_file: avoid_types_as_parameter_names

part of '../../riverpod_extended_notifier.dart';

abstract class ExtendedNotifier<State> extends Notifier<State>
    with
        ExtendedNotifierMixinBase<State, Null>,
        ExtendedNotifierMixin<State, Null> {
  ExtendedNotifier({
    State? initialState,
  }) : _initialState = initialState;

  @override
  State? get initialState => _initialState;

  final State? _initialState;

  @override
  State build() => _build();
}

abstract class ExtendedAutoDisposeNotifier<State>
    extends AutoDisposeNotifier<State>
    with
        ExtendedAutoDisposeNotifierMixinBase<State, Null>,
        ExtendedAutoDisposeNotifierMixin<State, Null> {
  ExtendedAutoDisposeNotifier({
    State? initialState,
  }) : _initialState = initialState;

  @override
  State? get initialState => _initialState;

  final State? _initialState;

  @override
  State build() => _build();
}
