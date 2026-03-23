part of 'notifier_event_base.dart';

sealed class NotifierEvent<State> extends NotifierEventBase<State> {
  const NotifierEvent();
}

class NotifierCreateEvent<State> extends NotifierEvent<State> {
  const NotifierCreateEvent();

  @override
  String get debugLabel => 'create';
}

class NotifierWillInvalidateEvent<State> extends NotifierEvent<State> {
  const NotifierWillInvalidateEvent();

  @override
  String get debugLabel => 'will invalidate';
}

class NotifierDidInvalidateEvent<State> extends NotifierEvent<State> {
  const NotifierDidInvalidateEvent({
    required this.previous,
    required this.state,
  });

  final State? previous;
  final State state;

  @override
  String get debugLabel => 'did invalidate';
}

class NotifierCancelEvent<State> extends NotifierEvent<State> {
  const NotifierCancelEvent();

  @override
  String get debugLabel => 'cancel';
}

class NotifierResumeEvent<State> extends NotifierEvent<State> {
  const NotifierResumeEvent();

  @override
  String get debugLabel => 'resume';
}

class NotifierAddedListenerEvent<State> extends NotifierEvent<State> {
  const NotifierAddedListenerEvent({required this.total});
  final int total;

  @override
  String get debugLabel => 'added listener ($total)';
}

class NotifierRemovedListenerEvent<State> extends NotifierEvent<State> {
  const NotifierRemovedListenerEvent({required this.total});
  final int total;

  @override
  String get debugLabel => 'removed listener ($total)';
}

class NotifierDisposeEvent<State> extends NotifierEvent<State> {
  const NotifierDisposeEvent();

  @override
  String get debugLabel => 'dispose';
}
