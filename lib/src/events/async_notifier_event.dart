part of 'notifier_event_base.dart';

sealed class AsyncNotifierEvent<State> extends NotifierEventBase<State> {
  const AsyncNotifierEvent();
}

class AsyncNotifierCreateEvent<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierCreateEvent();

  @override
  String get debugLabel => 'create';
}

class AsyncNotifierInvalidateEvent<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierInvalidateEvent();

  @override
  String get debugLabel => 'invalidate';
}

class AsyncNotifierCancelEvent<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierCancelEvent();

  @override
  String get debugLabel => 'cancel';
}

class AsyncNotifierResumeEvent<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierResumeEvent();

  @override
  String get debugLabel => 'resume';
}

class AsyncNotifierAddedListener<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierAddedListener({required this.total});
  final int total;

  @override
  String get debugLabel => 'added listener ($total)';
}

class AsyncNotifierRemoveListener<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierRemoveListener({required this.total});
  final int total;

  @override
  String get debugLabel => 'removed listener ($total)';
}

class AsyncNotifierDisposeEvent<State> extends AsyncNotifierEvent<State> {
  const AsyncNotifierDisposeEvent();

  @override
  String get debugLabel => 'dispose';
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
}
