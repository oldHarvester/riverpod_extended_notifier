part of '../../riverpod_extended_notifier.dart';

extension ExtendedWidgetRefExtension on WidgetRef {
  /// All providers using transaction ref will live throughout the entire operation
  FutureOr<T> transaction<T>(
    FutureOr<T> Function(WidgetTransactionRef ref) operation,
  ) {
    return TransactionRef.run(WidgetTransactionRef(ref: this), operation);
  }
}
