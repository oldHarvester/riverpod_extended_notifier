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

enum ConcurrencyStrategy {
  /// Takes latest
  switchMap,

  /// Takes leading
  exhaustMap,
}

mixin ExtendedAsyncNotifierBase<
  State,
  Arg extends Object?,
  ExtendedRef extends Ref<AsyncValue<State>>
>
    on ExtendedProviderNotifierMixinBase<AsyncValue<State>, Arg, ExtendedRef> {
  late FlexibleCompleter<State> _stateCompleter = _createCompleter();
  late FlexibleCompleter<State> _refreshRecompleter = _createCompleter();
  late AutoRestartExecutor<State> _retryExecutor = _createRetryExecutor();
  final FlexibleEquality _equality = FlexibleEquality();

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
        onRetryStarted: (retry, error, stackTrace) {
          _notifyEvent(
            AsyncNotifierRetryStartedEvent(
              currentAttempt: retry,
              lastError: error,
              lastStacktrace: stackTrace,
            ),
          );
        },
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

  @protected
  ConcurrencyStrategy get concurrencyStrategy => ConcurrencyStrategy.switchMap;

  Future<State> get future => _refreshRecompleter.future;

  bool get isRefreshing => !_refreshRecompleter.isCompleted;

  bool refreshOnAttach(Object error, StackTrace? stackTrace) => true;

  // This future will auto invalidate provider if it has error and return new future dependening on result
  Future<State> get safeFuture {
    if (_refreshRecompleter.isCompetedWithError) {
      ref.invalidateSelf();
      return _refreshRecompleter.future;
    } else {
      return future;
    }
  }

  @protected
  bool stateShouldNotify(State previous, State next) {
    return _equality.notEquals(previous, next);
  }

  @protected
  bool errorShouldNotify(Object previous, Object next) {
    return _equality.notEquals(previous, next);
  }

  @override
  bool updateShouldNotify(AsyncValue<State> previous, AsyncValue<State> next) {
    if (identical(previous, next)) {
      return false;
    } else {
      final prevLoading = previous.isLoading;
      final nextLoading = next.isLoading;
      if (prevLoading || nextLoading) return prevLoading != nextLoading;
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

  /// With this method you can override build success
  @protected
  State resolveValue(State value, AsyncValue<State> previous) {
    return value;
  }

  void _checkUpdateOnAttach() {
    if (isRefreshing) return;
    final error = state.error;
    final stackTrace = state.stackTrace;
    if (error != null) {
      final refresh = refreshOnAttach(error, stackTrace);
      if (refresh) {
        ref.invalidateSelf();
      }
    }
  }

  @protected
  FutureOr<State> _fetchState() async {
    final completer = _stateCompleter;
    bool isSync() {
      return completer.canPerformAction(_stateCompleter);
    }

    try {
      var initialValue = await _retryExecutor.start();
      if (isSync()) {
        final previousState = state;
        initialValue = resolveValue(initialValue, previousState);
        _refreshRecompleter.complete(initialValue);
        completer.complete(initialValue);
        final nextState = AsyncData(
          initialValue,
        ).copyWithPrevious(previousState);
        _notifyEvent(
          AsyncNotifierDidLoadEvent(
            state: nextState,
            previous: state,
          ),
        );
      }
      return initialValue;
    } catch (e, stk) {
      if (isSync()) {
        _refreshRecompleter.completeError(e, stk);
        _notifyEvent(
          AsyncNotifierLoadFailedEvent(
            didRetries: retries,
            error: e,
            stackTrace: stk,
          ),
        );
        completer.completeError(e, stk);
      }
      rethrow;
    }
  }

  void _clearCompleters() {
    /// Order
    /// 1. state completers
    /// 2. retry executors
    _stateCompleter.cancel();
    _stateCompleter = _createCompleter();
    _retryExecutor.cancel();
    _retryExecutor = _createRetryExecutor();
    if (_refreshRecompleter.isCompleted) {
      if (!disposed) {
        _notifyEvent(
          AsyncNotifierWillLoadEvent(
            initial: false,
            state: null,

            /// TODO: must be `state`, need to resolve concurrent modification
          ),
        );
      }
      // TODO: maybe also do not need to create new completer (need to test)
      _refreshRecompleter = _createCompleter();
    }
  }

  @protected
  void onCreate() {}

  @protected
  void onInvalidate() {}

  @protected
  void onDispose() {}

  @protected
  void onCancel() {}

  @protected
  void onResume() {}

  @protected
  void onEvent(AsyncNotifierEvent<State> event) {}

  void _notifyEvent(AsyncNotifierEvent<State> event) {
    if (debugEvents) {
      _logEvents(event.debugLabel);
    }
    onEvent(event);
    switch (event) {
      case final AsyncNotifierCreateEvent<State> _:
        onCreate();
        break;
      case final AsyncNotifierInvalidateEvent<State> _:
        onInvalidate();
        break;
      case final AsyncNotifierCancelEvent<State> _:
        onCancel();
        break;
      case final AsyncNotifierResumeEvent<State> _:
        onResume();
        _checkUpdateOnAttach();
        break;
      case final AsyncNotifierAddedListener<State> _:
        _checkUpdateOnAttach();
        break;
      case final AsyncNotifierRemoveListener<State> _:
        break;
      case final AsyncNotifierDisposeEvent<State> _:
        onDispose();
        break;
      case final AsyncNotifierWillLoadEvent<State> _:
        break;
      case final AsyncNotifierDidLoadEvent<State> _:
        final current = event.state;
        final previous = event.previous;
        return current.when(
          data: (data) {
            _notifyEvent(
              AsyncNotifierLoadSucceedEvent(
                value: data,
                previousValue: previous.valueOrNull,
              ),
            );
            if (retries > 0) {
              _notifyEvent(
                AsyncNotifierRetrySucceedEvent(
                  didRetries: retries,
                  value: data,
                ),
              );
            }
          },
          error: (error, stackTrace) {
            _notifyEvent(
              AsyncNotifierLoadFailedEvent(
                didRetries: retries,
                error: error,
                stackTrace: stackTrace,
              ),
            );
          },
          loading: () {},
        );
      case final AsyncNotifierLoadSucceedEvent<State> _:
        break;
      case final AsyncNotifierLoadFailedEvent<State> _:
        break;
      case final AsyncNotifierRetryStartedEvent<State> _:
        break;
      case final AsyncNotifierRetryFailedEvent<State> _:
        break;
      case final AsyncNotifierRetrySucceedEvent<State> _:
        break;
    }
  }

  @override
  void _onListenersChanged(int was, int now) {
    if (now > was) {
      _notifyEvent(AsyncNotifierAddedListener(total: now));
    } else {
      _notifyEvent(AsyncNotifierRemoveListener(total: now));
    }
    if (now <= 0) {
      _notifyEvent(AsyncNotifierCancelEvent());
    }
  }

  @protected
  FutureOr<State> _build() async {
    final initial = !_initialized;
    if (initial) {
      _notifyEvent(AsyncNotifierCreateEvent());
      _notifyEvent(
        AsyncNotifierWillLoadEvent(
          initial: initial,
          state: state,
        ),
      );
    }
    _beforeBuild();
    ref.onResume(
      () {
        _notifyEvent(AsyncNotifierResumeEvent());
      },
    );

    ref.onDispose(
      () {
        if (hasListeners) {
          _notifyEvent(AsyncNotifierInvalidateEvent());
        } else {
          _notifyEvent(AsyncNotifierDisposeEvent());
        }

        switch (concurrencyStrategy) {
          case ConcurrencyStrategy.switchMap:
            _clearCompleters();
            break;
          case ConcurrencyStrategy.exhaustMap:
            if (_refreshRecompleter.isCompleted) {
              _clearCompleters();
            }
            break;
        }
      },
    );

    return switch (concurrencyStrategy) {
      ConcurrencyStrategy.switchMap => _fetchState(),
      ConcurrencyStrategy.exhaustMap =>
        !_refreshRecompleter.isCompleted ? future : _fetchState(),
    };
  }

  @protected
  Future<bool> executeUpdate(
    AsyncNotifierUpdateResolverOrNull<State> cb, {
    AsyncNotifierUpdateOnErrorResolver? onError,
    AsyncNotifierOnDesyncResolver<State>? onDesync,
    bool skipReloading = true,
    bool skipRefreshing = true,
  }) async {
    final result = await updateOrNull(
      cb,
      onDesync: onDesync,
      onError: onError,
      skipRefreshing: skipRefreshing,
      skipReloading: skipReloading,
    );
    return result != null;
  }

  @protected
  Future<State?> updateOrNull(
    AsyncNotifierUpdateResolverOrNull<State> cb, {
    AsyncNotifierUpdateOnErrorResolver? onError,
    AsyncNotifierOnDesyncResolver<State>? onDesync,
    bool skipReloading = true,
    bool skipRefreshing = true,
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
        skipRefreshing: skipRefreshing,
        skipReloading: skipReloading,
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
    bool skipReloading = true,
    bool skipRefreshing = true,
  }) async {
    final completer = _refreshRecompleter;
    final unsyncException = ExtendedAsyncNotifierSyncException();
    bool isSync() {
      return _refreshRecompleter == completer && !completer.isCancelled;
    }

    try {
      final tempState = state.when(
        skipError: true,
        skipLoadingOnRefresh: skipRefreshing,
        skipLoadingOnReload: skipReloading,
        data: (data) => data,
        error: (error, stackTrace) => null,
        loading: () => null,
      );
      final result = tempState ?? await completer.future;

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
