# Riverpod Extended Notifier

Extended notifiers for [Riverpod](https://riverpod.dev/) with lifecycle callbacks, automatic retries, and convenient async state update methods.

## Features

- **Lifecycle callbacks** — `onCreated`, `onWillLoad`, `onDidLoad`, `onWillDispose`, `onDidDisposed`, `onWillInvalidate`
- **Automatic retries** — configurable retry logic for async notifiers with customizable delay, max retries, and timeout
- **Safe async updates** — `update`, `updateOrNull`, and `executeUpdate` methods that handle desync (invalidation during update)
- **Listener tracking** — `listeners`, `hasListeners`, `disposed` properties
- **Debug logging** — opt-in lifecycle logging via `debugLifecycle`
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
  void onCreated() {
    super.onCreated();
    // Called once when the notifier is first created
  }

  @override
  void onWillLoad() {
    super.onWillLoad();
    // Called before buildState executes
  }

  @override
  void onDidLoadSucceed(Data state) {
    // Called when buildState completes successfully
  }

  @override
  void onDidLoadFailed(Object error, StackTrace stackTrace) {
    // Called when buildState throws an error
  }

  @override
  void onWillDispose() {
    super.onWillDispose();
    // Called when all listeners are removed
  }

  @override
  void onDidDisposed() {
    super.onDidDisposed();
    // Called when the notifier is fully disposed
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
    // Return false to stop retrying for specific errors
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

## Requirements

- Dart SDK `^3.10.0`
- Flutter `>=1.17.0`
- `flutter_riverpod` `>=2.0.0 <3.0.0`

## License

See [LICENSE](LICENSE) for details.
