part of 'notifier_event_base.dart';

sealed class AsyncNotifierEvent<State> extends NotifierEventBase<State> {
  const AsyncNotifierEvent();
}

class AsyncNotifierCreateEvent<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierCreateEvent();

  @override
  String get debugLabel => 'create';

  @override
  List<Object?> get props => [];
}

class AsyncNotifierInvalidateEvent<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierInvalidateEvent();

  @override
  String get debugLabel => 'invalidate';

  @override
  List<Object?> get props => [];
}

class AsyncNotifierCancelEvent<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierCancelEvent();

  @override
  String get debugLabel => 'cancel';

  @override
  List<Object?> get props => [];
}

class AsyncNotifierResumeEvent<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierResumeEvent();

  @override
  String get debugLabel => 'resume';

  @override
  List<Object?> get props => [];
}

class AsyncNotifierAddedListener<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierAddedListener({required this.total});
  final int total;

  @override
  String get debugLabel => 'added listener ($total)';

  @override
  List<Object?> get props => [total];
}

class AsyncNotifierRemoveListener<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierRemoveListener({required this.total});
  final int total;

  @override
  String get debugLabel => 'removed listener ($total)';

  @override
  List<Object?> get props => [total];
}

class AsyncNotifierDisposeEvent<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierDisposeEvent();

  @override
  String get debugLabel => 'dispose';

  @override
  List<Object?> get props => [];
}

class AsyncNotifierWillLoadEvent<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierWillLoadEvent({
    required this.initial,
    required this.state,
  });

  final bool initial;
  final AsyncValue<State>? state;

  @override
  String get debugLabel => 'will load';

  @override
  List<Object?> get props => [initial, state];
}

class AsyncNotifierDidLoadEvent<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierDidLoadEvent({
    required this.state,
    required this.previous,
  });

  final AsyncValue<State> state;
  final AsyncValue<State> previous;

  @override
  String get debugLabel => 'did load';

  @override
  List<Object?> get props => [state, previous];
}

class AsyncNotifierLoadSucceedEvent<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierLoadSucceedEvent({
    required this.value,
    this.previousValue,
  });

  final State? previousValue;
  final State value;

  @override
  String get debugLabel => 'load succeed event';

  @override
  List<Object?> get props => [previousValue, value];
}

class AsyncNotifierLoadFailedEvent<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierLoadFailedEvent({
    required this.didRetries,
    required this.error,
    required this.stackTrace,
  });

  final int didRetries;
  final Object error;
  final StackTrace stackTrace;

  @override
  String get debugLabel => 'load failed event';

  @override
  List<Object?> get props => [didRetries, error, stackTrace];
}

class AsyncNotifierRetryStartedEvent<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierRetryStartedEvent({
    required this.currentAttempt,
    required this.lastError,
    required this.lastStacktrace,
  });

  final int currentAttempt;
  final Object lastError;
  final StackTrace lastStacktrace;

  @override
  String get debugLabel => 'retry started ($currentAttempt)';

  @override
  List<Object?> get props => [
        currentAttempt,
        lastError,
        lastStacktrace,
      ];
}

class AsyncNotifierRetryFailedEvent<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierRetryFailedEvent({
    required this.didRetries,
    required this.error,
    required this.stackTrace,
  });

  final int didRetries;
  final Object error;
  final StackTrace stackTrace;

  @override
  String get debugLabel => 'retry failed';

  @override
  List<Object?> get props => [didRetries, error, stackTrace];
}

class AsyncNotifierRetrySucceedEvent<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierRetrySucceedEvent({
    required this.didRetries,
    required this.value,
  });

  final int didRetries;
  final State value;

  @override
  String get debugLabel => 'retry succeed ($didRetries)';

  @override
  List<Object?> get props => [didRetries, value];
}

class AsyncNotifierInternetStatusChangedEvent<State>
    extends AsyncNotifierEvent<State> {
  const AsyncNotifierInternetStatusChangedEvent({
    required this.status,
  });

  final InternetStatus status;

  @override
  String get debugLabel => 'internet status changed: $status';

  @override
  List<Object?> get props => [status];
}
