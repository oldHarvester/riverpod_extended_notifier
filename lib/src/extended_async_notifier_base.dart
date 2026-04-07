part of '../riverpod_extended_notifier.dart';

extension InternetStatusX on InternetConnectionStatus {
  bool get connected => this == InternetConnectionStatus.connected;

  bool get disconnected => this == InternetConnectionStatus.disconnected;
}

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

enum ErrorRefreshTrigger {
  onResume,
  onInternetGained,
}

enum RefreshTrigger {
  onResume,
}

mixin ExtendedAsyncNotifierBase<
  State,
  Arg extends Object?,
  ExtendedRef extends Ref<AsyncValue<State>>
>
    on ExtendedProviderNotifierMixinBase<AsyncValue<State>, Arg, ExtendedRef> {
  late FlexibleCompleter<State> _stateCompleter = _createCompleter();
  late FlexibleCompleter<State> _refreshRecompleter = _createCompleter();
  late FlexibleCompleter<void> _connectionCompleter = internetStatus.connected
      ? (_createCompleter()..complete())
      : _createCompleter();
  late AutoRestartExecutor<State> _retryExecutor = _createRetryExecutor();
  final FlexibleEquality _equality = FlexibleEquality();

  bool _initialStateResolved = false;

  FlexibleCompleter<T> _createCompleter<T>() =>
      FlexibleCompleter<T>()..future.ignore();

  Future<void> get _connectionWaiter => _connectionCompleter.future;

  AutoRestartExecutor<State> _createRetryExecutor() =>
      AutoRestartExecutor<State>(
        handler: () async {
          if (keepLoadingWhileConnecting) {
            await _connectionWaiter;
          }
          return buildState();
        },
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
  State initialStateResolver({
    State? initialState,
    required State Function() builder,
  }) {
    if (!_initialStateResolved && initialState != null) {
      _initialStateResolved = true;
      return initialState as State;
    }
    return builder();
  }

  @protected
  ConcurrencyStrategy get concurrencyStrategy => ConcurrencyStrategy.switchMap;

  @protected
  Set<ErrorRefreshTrigger> errorRefreshTriggers = {
    ErrorRefreshTrigger.onResume,
    ErrorRefreshTrigger.onInternetGained,
  };

  @protected
  Set<RefreshTrigger> refreshTriggers = {};

  Future<State> get future => _refreshRecompleter.future;

  @protected
  bool get isRefreshing => !_refreshRecompleter.isCompleted;

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

  @protected
  bool willTriggerErrorRefresh(
    Object error,
    StackTrace? stackTrace,
    ErrorRefreshTrigger trigger,
  ) => true;

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

  InternetConnectionStatus _internetStatus =
      InternetConnectionStatus.disconnected;

  @protected
  InternetConnectionStatus get internetStatus => _internetStatus;

  @protected
  Duration? get retriesTimeoutDuration => null;

  @protected
  int? get maxRetries => null;

  @protected
  int get retries => _retryExecutor.retries;

  @protected
  bool get disableRetries => false;

  @protected
  bool get keepLoadingWhileConnecting => false;

  /// With this method you can override build success
  @protected
  State resolveValue(State value, AsyncValue<State> previous) {
    return value;
  }

  void _resolveErrorRefreshTrigger(ErrorRefreshTrigger trigger) {
    if (isRefreshing) return;
    final error = state.error;
    final stackTrace = state.stackTrace;
    if (error != null && errorRefreshTriggers.contains(trigger)) {
      final result = willTriggerErrorRefresh(error, stackTrace, trigger);
      if (result) {
        CleverWidgetsBinding.executeFrame(
          () {
            if (!disposed) {
              ref.invalidateSelf();
            }
          },
        );
      }
    }
  }

  void _resolveRefreshTrigger(RefreshTrigger trigger) {
    if (isRefreshing) return;
    if (refreshTriggers.contains(trigger)) {
      ref.invalidateSelf();
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

            /// TODO: must be `state`, need to resolve concurrent modification
            state: null,
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

  void _onInternetStatusChanged(InternetConnectionStatus status) {
    if (status.disconnected && _connectionCompleter.isCompleted) {
      _connectionCompleter = FlexibleCompleter();
    } else if (status.connected) {
      _connectionCompleter.complete();
    }
    _notifyEvent(
      AsyncNotifierInternetStatusChangedEvent(
        status: status,
      ),
    );
    _internetStatus = status;
    if (status.connected) {
      _resolveErrorRefreshTrigger(ErrorRefreshTrigger.onInternetGained);
    }
  }

  void _notifyEvent(AsyncNotifierEvent<State> event) {
    if (debugEvents) {
      _logEvents(event.debugLabel);
    }
    onEvent(event);
    switch (event) {
      case final AsyncNotifierCreateEvent<State> _:
        onCreate();
        _internetStatus = ref.read(
          RiverpodExtendedNotifierProviders.internetStatusProvider,
        );
        break;
      case final AsyncNotifierInternetStatusChangedEvent<State> _:
        break;
      case final AsyncNotifierInvalidateEvent<State> _:
        onInvalidate();
        break;
      case final AsyncNotifierCancelEvent<State> _:
        onCancel();
        break;
      case final AsyncNotifierResumeEvent<State> _:
        onResume();
        _resolveErrorRefreshTrigger(ErrorRefreshTrigger.onResume);
        _resolveRefreshTrigger(RefreshTrigger.onResume);
        break;
      case final AsyncNotifierAddedListener<State> _:
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
          skipError: false,
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
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
    ref.watch(
      RiverpodExtendedNotifierProviders.internetStatusProvider.select(
        (value) => true,
      ),
    );
    ref.listen(
      RiverpodExtendedNotifierProviders.internetStatusProvider,
      (previous, next) {
        _onInternetStatusChanged(next);
      },
    );
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
