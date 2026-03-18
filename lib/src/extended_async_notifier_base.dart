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

  FlexibleCompleter<State> _createCompleter() =>
      FlexibleCompleter()..future.ignore();

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

  FutureOr<State> fetchState() async {
    final completer = _stateCompleter;
    bool isSync() {
      return completer.canPerformAction(_stateCompleter);
    }

    try {
      final initialState = await buildState();
      if (isSync()) {
        _refreshRecompleter.complete(initialState);
        completer.complete(initialState);
      }
      return initialState;
    } catch (e) {
      if (isSync()) {
        completer.completeError(e);
      }
      rethrow;
    }
  }

  FutureOr<State> _build() async {
    _beforeBuild();
    ref.onDispose(() {
      _stateCompleter.cancel();
      _stateCompleter = _createCompleter();
      if (_refreshRecompleter.isCompleted) {
        _refreshRecompleter = _createCompleter();
      }
    });
    return await fetchState();
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
