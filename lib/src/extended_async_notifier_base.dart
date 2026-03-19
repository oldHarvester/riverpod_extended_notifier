part of '../riverpod_extended_notifier.dart';

typedef ExtendedAutoDisposeAsyncNotifierMixinBase<State, Arg extends Object?> =
    ExtendedProviderNotifierMixinBase<
      AsyncValue<State>,
      Arg,
      AutoDisposeAsyncNotifierProviderRef<State>
    >;

typedef ExtendedAutoDisposeAsyncNotifierMixin<State, Arg extends Object?> =
    ExtendedAsyncNotifierBase<
      State,
      Arg,
      AutoDisposeAsyncNotifierProviderRef<State>
    >;

typedef ExtendedAsyncNotifierMixinBase<State, Arg extends Object?> =
    ExtendedProviderNotifierMixinBase<
      AsyncValue<State>,
      Arg,
      AsyncNotifierProviderRef<State>
    >;

typedef ExtendedAsyncNotifierMixin<State, Arg extends Object?> =
    ExtendedAsyncNotifierBase<State, Arg, AsyncNotifierProviderRef<State>>;

typedef AsyncNotifierUpdateResolver<State> =
    FutureOr<State> Function(State state);

typedef AsyncNotifierUpdateResolverOrNull<State> =
    FutureOr<State?> Function(State state);

typedef AsyncNotifierUpdateOnErrorResolver<State> =
    FutureOr<State> Function(Object err, StackTrace stackTrace);

typedef AsyncNotifierOnDesyncResolver<State> = void Function(State state);

mixin ExtendedAsyncNotifierBase<
  State,
  Arg extends Object?,
  ExtendedRef extends Ref<AsyncValue<State>>
>
    on ExtendedProviderNotifierMixinBase<AsyncValue<State>, Arg, ExtendedRef> {
  late FlexibleCompleter<State> _stateCompleter = _createCompleter();
  late FlexibleCompleter<State> _refreshRecompleter = _createCompleter();
  late AutoRestartExecutor<State> _retryExecutor = _createRetryExecutor();

  FlexibleCompleter<State> _createCompleter() =>
      FlexibleCompleter()..future.ignore();

  AutoRestartExecutor<State> _createRetryExecutor() =>
      AutoRestartExecutor<State>(
        handler: buildState,
        onError: disableRetries
            ? (retries, error, stk) {
                return false;
              }
            : shouldRetryOnError,
        autoStart: false,
        maxRetries: maxRetries,
        restartDuration: retryRestartDuration,
        timeOutDuration: retriesTimeoutDuration,
      );

  @protected
  FutureOr<State> buildState();

  Future<bool> refresh() async {
    try {
      ref.invalidateSelf();
      await future;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<State> get future => _refreshRecompleter.future;

  @override
  @mustCallSuper
  void onDidLoad(AsyncValue<State> state) {
    switch (state) {
      case final AsyncLoading<State> _:
        break;
      case final AsyncError<State> _:
        onDidLoadFailed(state.error, state.stackTrace);
        break;
      case final AsyncData<State> _:
        onDidLoadSucceed(state.value);
        break;
    }
  }

  @protected
  bool stateShouldNotify(State previous, State next) {
    return !FlexibleEquality.equals(previous, next);
  }

  @protected
  bool errorShouldNotify(Object previous, Object next) {
    return !FlexibleEquality.equals(previous, next);
  }

  @override
  bool updateShouldNotify(AsyncValue<State> previous, AsyncValue<State> next) {
    if (identical(previous, next)) {
      return false;
    } else if (previous.runtimeType != next.runtimeType) {
      return true;
    } else {
      final oldVal = previous.valueOrNull;
      final nextVal = next.valueOrNull;
      final oldErr = previous.error;
      final nextErr = next.error;
      if (oldVal != null && nextVal != null) {
        return stateShouldNotify(oldVal, nextVal);
      } else if (oldErr != null && nextErr != null) {
        return errorShouldNotify(oldErr, nextErr);
      } else {
        return false;
      }
    }
  }

  @protected
  FutureOr<bool?> shouldRetryOnError(
    int retries,
    Object error,
    StackTrace stackTrace,
  ) => true;

  @protected
  Duration get retryRestartDuration => Duration(seconds: 5);

  @protected
  Duration? get retriesTimeoutDuration => null;

  @protected
  int? get maxRetries => null;

  @protected
  int get retries => _retryExecutor.retries;

  @protected
  bool get disableRetries => false;

  @protected
  void onDidLoadFailed(Object error, StackTrace stackTrace) {
    _logLifecycle('on did load failed');
  }

  @protected
  void onDidLoadSucceed(State state) {
    _logLifecycle('on did load succeed');
  }

  @protected
  FutureOr<State> _fetchState() async {
    final completer = _stateCompleter;
    bool isSync() {
      return completer.canPerformAction(_stateCompleter);
    }

    try {
      final initialState = await _retryExecutor.start();
      if (isSync()) {
        _refreshRecompleter.complete(initialState);
        completer.complete(initialState);
        onDidLoad(AsyncData(initialState));
      }
      return initialState;
    } catch (e, stk) {
      if (isSync()) {
        _refreshRecompleter.completeError(e, stk);
        onDidLoad(AsyncError(e, stk));
        completer.completeError(e, stk);
      }
      rethrow;
    }
  }

  FutureOr<State> _build() async {
    final initial = !_initialized;
    _beforeBuild();
    if (initial) {
      onWillLoad(true);
    }
    ref.onDispose(() {
      if (hasListeners) {
        onInvalidate();
      }

      /// Order
      /// 1. state completers
      /// 2. retry executors
      _stateCompleter.cancel();
      _stateCompleter = _createCompleter();
      _retryExecutor.cancel();
      _retryExecutor = _createRetryExecutor();
      if (_refreshRecompleter.isCompleted) {
        onWillLoad(false);
        _refreshRecompleter = _createCompleter();
      }
    });
    return await _fetchState();
  }

  @protected
  Future<bool> executeUpdate(
    AsyncNotifierUpdateResolverOrNull<State> cb, {
    AsyncNotifierUpdateOnErrorResolver? onError,
    AsyncNotifierOnDesyncResolver<State>? onDesync,
  }) async {
    final result = await updateOrNull(cb);
    return result != null;
  }

  @protected
  Future<State?> updateOrNull(
    AsyncNotifierUpdateResolverOrNull<State> cb, {
    AsyncNotifierUpdateOnErrorResolver? onError,
    AsyncNotifierOnDesyncResolver<State>? onDesync,
  }) async {
    try {
      return await update(
        (state) async {
          final result = await cb(state);
          if (result == null) throw Exception('no returning value');
          return result;
        },
        onError: onError,
        onDesync: onDesync,
      );
    } catch (e) {
      return null;
    }
  }

  @protected
  Future<State> update(
    AsyncNotifierUpdateResolver<State> cb, {
    AsyncNotifierUpdateOnErrorResolver? onError,
    AsyncNotifierOnDesyncResolver<State>? onDesync,
  }) async {
    final completer = _refreshRecompleter;
    final unsyncException = ExtendedAsyncNotifierSyncException();
    bool isSync() {
      return _refreshRecompleter == completer && !completer.isCancelled;
    }

    try {
      final tempState = state.valueOrNull;
      final result = completer.isCompleted && tempState != null
          ? tempState
          : await completer.future;

      if (isSync()) {
        final updated = await cb(result);
        if (isSync()) {
          state = AsyncData(updated);
          return updated;
        } else {
          onDesync?.call(updated);
        }
        throw unsyncException;
      } else {
        throw unsyncException;
      }
    } catch (e, stk) {
      if (!isSync()) {
        throw unsyncException;
      }
      final errorOperation = await onError?.call(e, stk).safeExecute();
      if (errorOperation == null) {
        rethrow;
      }
      if (!isSync()) {
        final result = errorOperation.result;
        if (result != null) {
          onDesync?.call(result);
        }
        throw unsyncException;
      } else {
        return errorOperation.when(
          onSuccess: (result) {
            state = AsyncData(result);
            return result;
          },
          onError: (error, stackTrace) {
            throw error;
          },
        );
      }
    }
  }
}
