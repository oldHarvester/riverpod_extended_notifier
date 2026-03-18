part of '../../riverpod_extended_notifier.dart';

abstract class ExtendedFamilyAsyncNotifier<State, Arg>
    extends FamilyAsyncNotifier<State, Arg>
    with
        ExtendedAsyncNotifierMixinBase<State, Arg>,
        ExtendedAsyncNotifierMixin<State, Arg> {
  @override
  FutureOr<State> build(Arg arg) => _build();
}

abstract class ExtendedAutoDisposeFamilyAsyncNotifier<State, Arg>
    extends AutoDisposeFamilyAsyncNotifier<State, Arg>
    with
        ExtendedAutoDisposeAsyncNotifierMixinBase<State, Arg>,
        ExtendedAutoDisposeAsyncNotifierMixin<State, Arg> {
  @override
  FutureOr<State> build(Arg arg) => _build();
}
