# riverpod_extended_notifier

Расширение для [flutter_riverpod](https://pub.dev/packages/flutter_riverpod), добавляющее продвинутые возможности управления состоянием: lifecycle-события, retry-логику, отслеживание подключения к интернету, стратегии конкурентности и безопасные мутации состояния.

---

## Содержание

- [Установка](#установка)
- [Базовые классы](#базовые-классы)
- [Lifecycle-события](#lifecycle-события)
- [Async-события](#async-события)
- [Стратегии конкурентности](#стратегии-конкурентности)
- [Retry-логика](#retry-логика)
- [Интернет-соединение](#интернет-соединение)
- [Безопасные мутации состояния](#безопасные-мутации-состояния)
- [Транзакции](#транзакции)
- [Жизненный цикл (Lifecycle State)](#жизненный-цикл-lifecycle-state)
- [Дебаггинг](#дебаггинг)
- [Утилиты](#утилиты)
- [Примеры](#примеры)

---

## Установка

Добавьте зависимость в `pubspec.yaml`:

```yaml
dependencies:
  riverpod_extended_notifier:
    git:
      url: https://github.com/your-repo/riverpod_extended_notifier.git
```

### Android

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### macOS

```xml
<key>com.apple.security.network.server</key>
<true/>
```

---

## Базовые классы

Пакет предоставляет четыре конкретных класса-нотификатора и два семейства (family):

| Класс | Базовый Riverpod класс | Auto-dispose |
|---|---|---|
| `ExtendedNotifier<State>` | `Notifier<State>` | нет |
| `ExtendedAutoDisposeNotifier<State>` | `AutoDisposeNotifier<State>` | да |
| `ExtendedAsyncNotifier<State>` | `AsyncNotifier<State>` | нет |
| `ExtendedAutoDisposeAsyncNotifier<State>` | `AutoDisposeAsyncNotifier<State>` | да |
| `ExtendedFamilyAsyncNotifier<State, Arg>` | `FamilyAsyncNotifier<State, Arg>` | нет |
| `ExtendedAutoDisposeFamilyAsyncNotifier<State, Arg>` | `AutoDisposeFamilyAsyncNotifier<State, Arg>` | да |

### Синхронный нотификатор

```dart
final counterProvider = AutoDisposeNotifierProvider<CounterNotifier, int>(
  () => CounterNotifier(),
);

class CounterNotifier extends ExtendedAutoDisposeNotifier<int> {
  @override
  int buildState() => 0;

  void increment() => state = state + 1;
}
```

### Асинхронный нотификатор

```dart
final usersProvider = AutoDisposeAsyncNotifierProvider<UsersNotifier, List<User>>(
  () => UsersNotifier(),
);

class UsersNotifier extends ExtendedAutoDisposeAsyncNotifier<List<User>> {
  @override
  FutureOr<List<User>> buildState() async {
    return api.fetchUsers();
  }
}
```

---

## Lifecycle-события

### Синхронный нотификатор (`ExtendedNotifierBase`)

```dart
class MyNotifier extends ExtendedAutoDisposeNotifier<MyState> {
  @override
  MyState buildState() => MyState.initial();

  @override
  void onCreate() {
    // Вызывается один раз при первом создании провайдера
  }

  @override
  void onWillInvalidate() {
    // Вызывается перед инвалидацией (провайдер пересоздаётся, слушатели есть)
  }

  @override
  void onDidInvalidate() {
    // Вызывается после инвалидации — buildState уже выполнен
  }

  @override
  void onDispose() {
    // Вызывается при окончательном удалении (нет слушателей)
  }

  @override
  void onCancel() {
    // Вызывается когда количество слушателей становится 0
  }

  @override
  void onResume() {
    // Вызывается когда первый слушатель снова подписывается после паузы
  }

  @override
  void onEvent(NotifierEvent<MyState> event) {
    // Единая точка подписки на все события нотификатора
    super.onEvent(event);
  }
}
```

#### События `NotifierEvent<State>`

| Событие | Когда происходит |
|---|---|
| `NotifierCreateEvent` | Первое создание провайдера |
| `NotifierWillInvalidateEvent` | Перед инвалидацией (есть слушатели) |
| `NotifierDidInvalidateEvent` | После инвалидации, содержит `previous` и `state` |
| `NotifierCancelEvent` | Слушателей стало 0 |
| `NotifierResumeEvent` | Первый слушатель после паузы |
| `NotifierAddedListenerEvent` | Добавлен новый слушатель, содержит `total` |
| `NotifierRemovedListenerEvent` | Удалён слушатель, содержит `total` |
| `NotifierDisposeEvent` | Провайдер окончательно уничтожен |

---

## Async-события

### Асинхронный нотификатор (`ExtendedAsyncNotifierBase`)

```dart
class ProductsNotifier extends ExtendedAutoDisposeAsyncNotifier<List<Product>> {
  @override
  FutureOr<List<Product>> buildState() async {
    return api.fetchProducts();
  }

  @override
  void onCreate() {
    // Провайдер создан, можно подписаться на стримы
  }

  @override
  void onInvalidate() {
    // Провайдер инвалидируется (слушатели есть)
  }

  @override
  void onDispose() {
    // Провайдер уничтожается (слушателей нет)
  }

  @override
  void onCancel() {
    // Все слушатели отписались
  }

  @override
  void onResume() {
    // Первый слушатель после паузы
  }

  @override
  void onDidLoad(AsyncNotifierDidLoadEvent<List<Product>> event) {
    // Данные загружены, event.state — новое состояние, event.previous — предыдущее
    final products = event.state.valueOrNull;
  }

  @override
  void onEvent(AsyncNotifierEvent<List<Product>> event) {
    // Все async-события нотификатора
    super.onEvent(event);
  }
}
```

#### События `AsyncNotifierEvent<State>`

| Событие | Когда происходит | Поля |
|---|---|---|
| `AsyncNotifierCreateEvent` | Первое создание | — |
| `AsyncNotifierInvalidateEvent` | Инвалидация (есть слушатели) | — |
| `AsyncNotifierDisposeEvent` | Уничтожение (нет слушателей) | — |
| `AsyncNotifierCancelEvent` | Слушателей стало 0 | — |
| `AsyncNotifierResumeEvent` | Первый слушатель после паузы | — |
| `AsyncNotifierWillLoadEvent` | Начало загрузки | `initial`, `state` |
| `AsyncNotifierDidLoadEvent` | Завершение загрузки | `state`, `previous` |
| `AsyncNotifierLoadSucceedEvent` | Данные загружены успешно | `value`, `previousValue` |
| `AsyncNotifierLoadFailedEvent` | Загрузка завершилась ошибкой | `error`, `stackTrace`, `didRetries` |
| `AsyncNotifierRetryStartedEvent` | Начата попытка повтора | `currentAttempt`, `lastError`, `lastStacktrace` |
| `AsyncNotifierRetrySucceedEvent` | Повтор успешен | `didRetries`, `value` |
| `AsyncNotifierRetryFailedEvent` | Повтор не удался | `didRetries`, `error`, `stackTrace` |
| `AsyncNotifierInternetStatusChangedEvent` | Изменился статус сети | `status` |
| `AsyncNotifierAddedListener` | Добавлен слушатель | `total` |
| `AsyncNotifierRemoveListener` | Удалён слушатель | `total` |

---

## Стратегии конкурентности

Управляют поведением при повторной загрузке (инвалидации) во время текущей загрузки.

```dart
class MyNotifier extends ExtendedAutoDisposeAsyncNotifier<Data> {
  @override
  ConcurrencyStrategy get concurrencyStrategy => ConcurrencyStrategy.switchMap;
  // или ConcurrencyStrategy.exhaustMap
}
```

| Стратегия | Поведение |
|---|---|
| `switchMap` (по умолчанию) | Отменяет текущую загрузку, начинает новую. Берёт последний запрос. |
| `exhaustMap` | Игнорирует новые запросы, пока идёт текущая загрузка. Берёт первый запрос. |

---

## Retry-логика

Автоматически повторяет `buildState` при ошибке.

```dart
class ResilientNotifier extends ExtendedAutoDisposeAsyncNotifier<Data> {
  @override
  bool get disableRetries => false; // включены по умолчанию

  @override
  int? get maxRetries => 3; // null = бесконечно

  @override
  Duration get retryRestartDuration => Duration(seconds: 5); // задержка между попытками

  @override
  Duration? get retriesTimeoutDuration => Duration(seconds: 30); // общий таймаут

  @override
  FutureOr<bool?> shouldRetryOnError(
    int retries,
    Object error,
    StackTrace stackTrace,
  ) {
    // Вернуть true — повторить, false — остановить, null — остановить
    if (error is NetworkException) return true;
    return false;
  }

  @override
  FutureOr<Data> buildState() async {
    return api.fetchData(); // при ошибке будет автоматически повторено
  }
}
```

Текущее количество попыток доступно через геттер `retries`:

```dart
@override
FutureOr<Data> buildState() async {
  print('Попытка $retries');
  return api.fetchData();
}
```

---

## Интернет-соединение

Пакет автоматически отслеживает состояние сети через `InternetStatusNotifier`.

### Автоматический перезапуск при ошибке

```dart
class NetworkNotifier extends ExtendedAutoDisposeAsyncNotifier<Data> {
  @override
  Set<ErrorRefreshTrigger> errorRefreshTriggers = {
    ErrorRefreshTrigger.onResume,           // перезапуск при возвращении в приложение
    ErrorRefreshTrigger.onInternetGained,   // перезапуск при восстановлении сети
  };

  @override
  bool willTriggerErrorRefresh(
    Object error,
    StackTrace? stackTrace,
    ErrorRefreshTrigger trigger,
  ) {
    // Фильтрация: перезапускать ли при конкретном триггере и ошибке
    if (trigger == ErrorRefreshTrigger.onInternetGained) {
      return error is NetworkException;
    }
    return true;
  }
}
```

### Автоматический refresh без ошибки

```dart
@override
Set<RefreshTrigger> refreshTriggers = {
  RefreshTrigger.onResume, // обновлять данные при каждом возвращении в приложение
};
```

### Ожидание подключения перед загрузкой

`useConnectionTx` приостанавливает выполнение `buildState` до тех пор, пока не появится интернет:

```dart
@override
FutureOr<Data> buildState() async {
  return useConnectionTx(() async {
    // этот код выполнится только при наличии интернета
    return api.fetchData();
  });
}
```

### Текущий статус сети

```dart
@override
void onCreate() {
  final status = internetStatus; // InternetStatus? — текущий статус
  if (status?.connected == true) {
    // ...
  }
}
```

---

## Безопасные мутации состояния

Три метода для безопасного изменения состояния `AsyncNotifier`, которые учитывают конкурентность и синхронизацию:

### `update` — обновление с текущим значением

```dart
Future<void> likePost(int postId) async {
  await update((currentPosts) async {
    final updated = await api.likePost(postId);
    return currentPosts.map((p) => p.id == postId ? updated : p).toList();
  });
}
```

Параметры:

```dart
Future<State> update(
  AsyncNotifierUpdateResolver<State> cb, {
  AsyncNotifierUpdateOnErrorResolver? onError,    // обработка ошибки
  AsyncNotifierOnDesyncResolver<State>? onDesync, // вызывается если провайдер инвалидировался
  bool skipReloading = true,   // ждать ли первичную загрузку
  bool skipRefreshing = true,  // ждать ли текущий refresh
})
```

### `updateOrNull` — обновление без исключения

Возвращает `null` вместо исключения, если `cb` вернул `null` или произошла ошибка:

```dart
Future<void> tryUpdateTitle(String newTitle) async {
  final result = await updateOrNull((state) async {
    if (newTitle.isEmpty) return null; // пропустить обновление
    return state.copyWith(title: newTitle);
  });
  if (result == null) print('Обновление отменено');
}
```

### `executeUpdate` — возвращает bool

Упрощённый вариант, возвращающий `true` при успехе:

```dart
Future<void> deleteItem(int id) async {
  final success = await executeUpdate(
    (state) async {
      await api.delete(id);
      return state.where((item) => item.id != id).toList();
    },
    onError: (error, stackTrace) async {
      showErrorSnackbar('Ошибка удаления');
      return state.valueOrNull!; // вернуть текущее состояние без изменений
    },
  );
}
```

### Исходный resolver

```dart
// Вызывается при каждом успешном set state
@override
State resolveValue(State value, AsyncValue<State> previous, bool fromBuild) {
  // fromBuild = true если вызов из buildState
  // можно нормализовать/обогатить данные
  return value;
}
```

---

## Транзакции

Транзакции гарантируют, что все прочитанные провайдеры живут на протяжении всей операции. Это предотвращает авто-dispose провайдеров-зависимостей во время async-операции.

### В нотификаторе (`Ref`)

```dart
class OrderNotifier extends ExtendedAutoDisposeAsyncNotifier<Order> {
  Future<void> placeOrder() async {
    await ref.transaction((txRef) async {
      // Все прочитанные провайдеры будут живы до конца транзакции
      final cart = txRef.read(cartProvider);
      final user = txRef.read(userProvider);
      await api.placeOrder(cart: cart, userId: user.id);
    });
  }
}
```

### В виджете (`WidgetRef`)

```dart
class CheckoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        await ref.transaction((txRef) async {
          final cart = txRef.read(cartProvider);
          final user = txRef.read(userProvider);
          await ref.read(orderNotifier.notifier).placeOrder(
            cart: cart,
            userId: user.id,
          );
        });
      },
      child: Text('Оформить заказ'),
    );
  }
}
```

---

## Жизненный цикл (Lifecycle State)

Каждый нотификатор хранит текущее состояние жизненного цикла:

```dart
enum NotifierLifecycleState {
  idle,      // начальное состояние до первого build
  working,   // активен, есть слушатели
  paused,    // нет слушателей (auto-dispose ещё не сработал)
  disposed,  // уничтожен
}
```

Доступ к состоянию и событиям изменения:

```dart
class MyNotifier extends ExtendedAutoDisposeAsyncNotifier<Data> {
  @override
  void onLifecycleChanged(NotifierLifecycleChangeEvent event) {
    print('${event.previous} → ${event.next}');

    if (event.started) {
      // idle → working: первый запуск
    }
    if (event.resumed) {
      // paused → working: вернулись слушатели
    }
  }

  void checkState() {
    print(lifecycleState); // NotifierLifecycleState.working
    print(hasListeners);   // true/false
    print(listeners);      // количество слушателей
    print(disposed);       // true если initialized && !hasListeners
  }
}
```

---

## Дебаггинг

```dart
class MyNotifier extends ExtendedAutoDisposeAsyncNotifier<Data> {
  @override
  String? get debugLabel => 'MyNotifier'; // имя в логах

  @override
  bool get debugEvents => true; // логировать все события

  @override
  bool get debugLifecycle => true; // логировать изменения lifecycle
}
```

Пример вывода в консоль при включённом `debugEvents`:

```
[MyNotifier] create
[MyNotifier] will load
[MyNotifier] added listener (1)
[MyNotifier] did load
[MyNotifier] load succeed event
```

---

## Утилиты

### `future` и `safeFuture`

```dart
// future — текущий Future загрузки (throws если ошибка)
final data = await notifier.future;

// safeFuture — если есть ошибка, автоматически инвалидирует и возвращает новый Future
final data = await notifier.safeFuture;
```

### `refresh()`

```dart
// Инвалидирует провайдер и ждёт завершения загрузки
// Возвращает true при успехе, false при ошибке
final success = await ref.read(myProvider.notifier).refresh();
```

### `AsyncValue.asFuture`

Extension для конвертации `AsyncValue` в `Future`:

```dart
final future = asyncValue.asFuture;
// - data → Future.value(data)
// - error → Future.error(error)
// - loading → Future, который никогда не завершится
```

### `initialStateResolver`

Позволяет задать начальное состояние при первом построении (например, из навигационных аргументов):

```dart
class ProductNotifier extends ExtendedAutoDisposeAsyncNotifier<Product> {
  Product? initialProduct;

  @override
  FutureOr<Product> buildState() {
    return initialStateResolver(
      initialState: initialProduct, // используется только в первый раз
      builder: () async => api.fetchProduct(arg),
    );
  }
}
```

---

## Примеры

### Полный пример: асинхронный нотификатор с retry и интернетом

```dart
final postsProvider = AutoDisposeAsyncNotifierProvider<PostsNotifier, List<Post>>(
  () => PostsNotifier(),
);

class PostsNotifier extends ExtendedAutoDisposeAsyncNotifier<List<Post>> {
  @override
  String? get debugLabel => 'PostsNotifier';

  @override
  bool get debugEvents => true;

  // Стратегия конкурентности: берём только последний запрос
  @override
  ConcurrencyStrategy get concurrencyStrategy => ConcurrencyStrategy.switchMap;

  // До 3 повторных попыток с интервалом 5 секунд
  @override
  int? get maxRetries => 3;

  @override
  Duration get retryRestartDuration => Duration(seconds: 5);

  // Автоматически обновляем при восстановлении сети (если была ошибка)
  @override
  Set<ErrorRefreshTrigger> errorRefreshTriggers = {
    ErrorRefreshTrigger.onInternetGained,
    ErrorRefreshTrigger.onResume,
  };

  @override
  FutureOr<List<Post>> buildState() async {
    // Ждём интернет перед загрузкой
    return useConnectionTx(() async {
      return api.fetchPosts();
    });
  }

  @override
  void onDidLoad(AsyncNotifierDidLoadEvent<List<Post>> event) {
    final posts = event.state.valueOrNull;
    analytics.track('posts_loaded', {'count': posts?.length});
  }

  Future<void> addPost(String title) async {
    await executeUpdate(
      (currentPosts) async {
        final newPost = await api.createPost(title: title);
        return [newPost, ...currentPosts];
      },
      onError: (error, stackTrace) async {
        showErrorToast('Не удалось создать пост');
        return state.valueOrNull!;
      },
    );
  }
}
```

### Пример транзакции с несколькими провайдерами

```dart
class CheckoutNotifier extends ExtendedAutoDisposeAsyncNotifier<OrderResult> {
  @override
  FutureOr<OrderResult> buildState() => OrderResult.empty();

  Future<void> checkout() async {
    await ref.transaction((txRef) async {
      // cartProvider и userProvider гарантированно живут до конца операции
      final cart = txRef.read(cartProvider);
      final user = txRef.read(userProvider);

      await executeUpdate((_) async {
        final result = await api.checkout(
          cartId: cart.id,
          userId: user.id,
        );
        return result;
      });
    });
  }
}
```

### Пример синхронного нотификатора с lifecycle

```dart
final filterProvider = AutoDisposeNotifierProvider<FilterNotifier, FilterState>(
  () => FilterNotifier(),
);

class FilterNotifier extends ExtendedAutoDisposeNotifier<FilterState> {
  @override
  FilterState buildState() => FilterState.initial();

  @override
  void onCreate() {
    // Восстановить фильтры из хранилища
    final saved = storage.loadFilters();
    if (saved != null) state = saved;
  }

  @override
  void onDispose() {
    // Сохранить фильтры при уничтожении
    storage.saveFilters(state);
  }

  void setCategory(String category) {
    state = state.copyWith(category: category);
  }
}
```

---

## Архитектура

```
ExtendedProviderNotifierMixinBase  ← базовый mixin (lifecycle, listeners)
    ├── ExtendedNotifierBase       ← sync: buildState, события Notifier
    │       ├── ExtendedNotifier
    │       ├── ExtendedAutoDisposeNotifier
    │       ├── ExtendedFamilyNotifier
    │       └── ExtendedAutoDisposeFamilyNotifier
    └── ExtendedAsyncNotifierBase  ← async: buildState, retry, internet, update
            ├── ExtendedAsyncNotifier
            ├── ExtendedAutoDisposeAsyncNotifier
            ├── ExtendedFamilyAsyncNotifier
            └── ExtendedAutoDisposeFamilyAsyncNotifier
```
