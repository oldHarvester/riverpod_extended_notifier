part of '../../riverpod_extended_notifier.dart';

extension ExtendedRefExtension on Ref {
  /// All providers using transaction ref will live throughout the entire operation
  FutureOr<T> transaction<T>(
    FutureOr<T> Function(NotifierTransactionRef ref) operation,
  ) {
    return TransactionRef.run(NotifierTransactionRef(ref: this), operation);
  }
}
