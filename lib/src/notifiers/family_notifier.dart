part of '../../riverpod_extended_notifier.dart';

abstract class ExtendedFamilyNotifier<State, Arg>
    extends FamilyNotifier<State, Arg>
    with
        ExtendedNotifierMixinBase<State, Arg>,
        ExtendedNotifierMixin<State, Arg> {
  @override
  State build(Arg arg) => _build();
}

abstract class ExtendedAutoDisposeFamilyNotifier<State, Arg>
    extends AutoDisposeFamilyNotifier<State, Arg>
    with
        ExtendedAutoDisposeNotifierMixinBase<State, Arg>,
        ExtendedAutoDisposeNotifierMixin<State, Arg> {
  @override
  State build(Arg arg) => _build();
}
