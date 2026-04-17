part of '../../riverpod_extended_notifier.dart';

abstract class TransactionRef {
  final List<ProviderSubscription> _subscriptions = [];

  T read<T>(ProviderListenable<T> listenable);

  static FutureOr<T> run<T, TRef extends TransactionRef>(
      TRef ref, FutureOr<T> Function(TRef ref) operation) async {
    try {
      final result = await operation(ref);
      return result;
    } finally {
      ref._clear();
    }
  }

  void _clear() {
    final subs = [..._subscriptions];
    _subscriptions.clear();
    for (final sub in subs) {
      sub.close();
    }
  }
}

class NotifierTransactionRef extends TransactionRef {
  NotifierTransactionRef({required Ref ref}) : _ref = ref;
  final Ref _ref;

  @override
  T read<T>(ProviderListenable<T> listenable) {
    final value = _ref.read(listenable);
    final sub = _ref.listen(
      listenable.select(
        (value) => true,
      ),
      (previous, next) {},
    );
    _subscriptions.add(sub);
    return value;
  }
}

class WidgetTransactionRef extends TransactionRef {
  WidgetTransactionRef({required WidgetRef ref}) : _ref = ref;
  final WidgetRef _ref;

  @override
  T read<T>(ProviderListenable<T> listenable) {
    final value = _ref.read(listenable);
    final sub = _ref.listenManual(
      listenable.select(
        (value) => true,
      ),
      (previous, next) {},
    );
    _subscriptions.add(sub);
    return value;
  }
}
