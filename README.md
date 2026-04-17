# Riverpod Extended Notifier

Extended notifiers for [Riverpod](https://riverpod.dev/) with lifecycle callbacks, automatic retries, transactions, internet connectivity tracking, and convenient async state update methods.

## Features

- **Lifecycle callbacks** — `onCreate`, `onWillInvalidate`, `onDidInvalidate`, `onDispose`, `onCancel`, `onResume`
- **Automatic retries** — configurable retry logic for async notifiers with customizable delay, max retries, and timeout
- **Safe async updates** — `update`, `updateOrNull`, and `executeUpdate` methods that handle desync (invalidation during update)
- **Transactions** — `ref.transaction()` keeps provider dependencies alive for the duration of an async operation
- **Internet connectivity** — built-in `InternetStatusNotifier` with auto-refresh on connection regained
- **`safeFuture`** — auto-invalidates the provider on error and returns the fresh future
- **`AsyncValue.asFuture`** — converts `AsyncValue<T>` to `Future<T>`
- **Listener tracking** — `listeners`, `hasListeners`, `disposed` properties
- **Debug logging** — opt-in lifecycle logging via `debugLifecycle` / `debugEvents`
- **Full notifier coverage** — extended versions for all Riverpod notifier types:
  - `ExtendedNotifier` / `ExtendedAutoDisposeNotifier`
  - `ExtendedAsyncNotifier` / `ExtendedAutoDisposeAsyncNotifier`
  - `ExtendedFamilyNotifier` / `ExtendedAutoDisposeFamilyNotifier`
  - `ExtendedFamilyAsyncNotifier` / `ExtendedAutoDisposeFamilyAsyncNotifier`

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  riverpod_extended_notifier:
    git:
      url: https://github.com/oldHarvester/riverpod_extended_notifier.git
```

## Usage

### Basic async notifier

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_extended_notifier/riverpod_extended_notifier.dart';

final usersProvider = AutoDisposeAsyncNotifierProvider<UsersNotifier, List<User>>(
  () => UsersNotifier(),
);

class UsersNotifier extends ExtendedAutoDisposeAsyncNotifier<List<User>> {
  @override
  FutureOr<List<User>> buildState() async {
    return await api.fetchUsers();
  }

  Future<void> addUser(User user) async {
    await executeUpdate((state) async {
      await api.createUser(user);
      return [...state, user];
    });
  }
}
```

### Lifecycle callbacks

Override any lifecycle method to hook into the notifier's lifecycle:

```dart
class MyNotifier extends ExtendedAutoDisposeAsyncNotifier<Data> {
  @override
  FutureOr<Data> buildState() => api.fetchData();

  @override
  void onCreate() {
    // Called once when the notifier is first created
  }

  @override
  void onDispose() {
    super.onDispose();
    // Called when the notifier is disposed (no listeners left)
  }

  @override
  void onResume() {
    // Called when a new listener is added after being cancelled
  }

  @override
  void onCancel() {
    // Called when all listeners are removed
  }
}
```

For synchronous notifiers, additional invalidation hooks are available:

```dart
class MyNotifier extends ExtendedAutoDisposeNotifier<Data> {
  @override
  Data buildState() => initialData;

  @override
  void onWillInvalidate() {
    // Called just before the notifier is invalidated
  }

  @override
  void onDidInvalidate() {
    // Called after invalidation rebuilds state
  }
}
```

### Automatic retries

Async notifiers support automatic retries on failure:

```dart
class ResilientNotifier extends ExtendedAutoDisposeAsyncNotifier<Data> {
  @override
  FutureOr<Data> buildState() => api.fetchData();

  @override
  int? get maxRetries => 5; // null = unlimited

  @override
  Duration get retryRestartDuration => Duration(seconds: 3);

  @override
  Duration? get retriesTimeoutDuration => Duration(seconds: 30);

  @override
  FutureOr<bool?> shouldRetryOnError(int retries, Object error, StackTrace stackTrace) {
    if (error is AuthException) return false;
    return true;
  }
}
```

To disable retries entirely:

```dart
@override
bool get disableRetries => true;
```

### Desync-safe updates

The `update` method handles cases where the notifier is invalidated during an async update:

```dart
// Returns the updated state or throws
final result = await update((state) async {
  await api.save(state);
  return state.copyWith(saved: true);
},
  onError: (error, stackTrace) => fallbackState,
  onDesync: (updatedState) {
    // Called when invalidation happened during update —
    // the result was computed but can't be applied
  },
);

// Returns null instead of throwing
final result = await updateOrNull((state) async { ... });

// Returns true/false for success/failure
final success = await executeUpdate((state) async { ... });
```

### Transactions

A transaction keeps all providers read inside it alive (subscribed) for the duration of the async operation. This prevents providers from being auto-disposed mid-operation.

Use `ref.transaction()` inside a notifier, or `ref.transaction()` on `WidgetRef` in a widget:

```dart
// Inside a notifier
Future<void> doWork() async {
  await ref.transaction((tx) async {
    final user = tx.read(userProvider);     // kept alive
    final prefs = tx.read(prefsProvider);   // kept alive
    await api.save(user, prefs);
  });
}

// Inside a widget
ElevatedButton(
  onPressed: () => ref.transaction((tx) async {
    final cart = tx.read(cartProvider);
    await ref.read(orderProvider.notifier).submit(cart);
  }),
)
```

All subscriptions created via `tx.read()` are automatically closed when the operation completes.

### Internet connectivity

The package includes `RiverpodExtendedNotifierProviders.internetStatus`, a built-in provider that tracks connectivity via `InternetStatus` (`connected` / `disconnected`).

Async notifiers automatically listen to connectivity changes. By default, if a notifier is in an error state it will refresh when the connection is regained:

```dart
class MyNotifier extends ExtendedAutoDisposeAsyncNotifier<Data> {
  @override
  FutureOr<Data> buildState() => api.fetchData();

  // Auto-refresh triggers (defaults shown):
  @override
  Set<ErrorRefreshTrigger> errorRefreshTriggers = {
    ErrorRefreshTrigger.onResume,
    ErrorRefreshTrigger.onInternetGained,
  };

  // Trigger a full refresh (not just on error) when internet is regained:
  @override
  Set<RefreshTrigger> refreshTriggers = {
    RefreshTrigger.onResume,
  };

  // Fine-grained control over whether to trigger refresh
  @override
  bool willTriggerErrorRefresh(Object error, StackTrace? stackTrace, ErrorRefreshTrigger trigger) {
    if (error is CacheException) return false;
    return true;
  }
}
```

Wait for a connection before executing an operation:

```dart
@override
FutureOr<Data> buildState() async {
  return useConnectionTx(() => api.fetchData());
}
```

You can also read the current internet status from within a notifier:

```dart
final status = internetStatus; // InternetStatus?
```

Or listen to it anywhere:

```dart
final status = ref.watch(RiverpodExtendedNotifierProviders.internetStatus);
```

### `safeFuture`

`safeFuture` is like `future`, but if the current state is an error it automatically invalidates the provider and returns the new loading future. Useful when you want to await the next successful state after a potential failure:

```dart
Future<List<Item>> fetchItems() {
  return safeFuture; // invalidates + re-fetches if currently errored
}
```

### `AsyncValue.asFuture`

Convert an `AsyncValue<T>` to a `Future<T>`:

- `AsyncData` → resolves immediately with the value
- `AsyncError` → rejects immediately with the error
- `AsyncLoading` → never completes (returns a `Completer` future)

```dart
final future = ref.read(myProvider).asFuture;
final value = await future;
```

### Pull-to-refresh

Every async notifier has a built-in `refresh()` method:

```dart
RefreshIndicator(
  onRefresh: ref.read(myProvider.notifier).refresh,
  child: ...
)
```

### Synchronous notifier

```dart
class CounterNotifier extends ExtendedAutoDisposeNotifier<int> {
  @override
  int buildState() => 0;

  void increment() => state++;
}
```

### Concurrency strategy

Control how re-builds are handled when a notifier is invalidated while a previous build is still in progress:

```dart
@override
ConcurrencyStrategy get concurrencyStrategy => ConcurrencyStrategy.exhaustMap; // keep leading
// default: ConcurrencyStrategy.switchMap  (take latest)
```

## Requirements

- Dart SDK `^3.10.0`
- Flutter `>=1.17.0`
- `flutter_riverpod` `>=2.0.0 <3.0.0`

## License

See [LICENSE](LICENSE) for details.
