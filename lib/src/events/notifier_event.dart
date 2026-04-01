part of 'notifier_event_base.dart';

sealed class NotifierEvent<State> extends NotifierEventBase<State> {
  const NotifierEvent();
}

class NotifierCreateEvent<State> extends NotifierEvent<State> {
  const NotifierCreateEvent();

  @override
  String get debugLabel => 'create';

  @override
  List<Object?> get props => [];
}

class NotifierWillInvalidateEvent<State> extends NotifierEvent<State> {
  const NotifierWillInvalidateEvent();

  @override
  String get debugLabel => 'will invalidate';

  @override
  List<Object?> get props => [];
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

  @override
  List<Object?> get props => [];
}

class NotifierCancelEvent<State> extends NotifierEvent<State> {
  const NotifierCancelEvent();

  @override
  String get debugLabel => 'cancel';

  @override
  List<Object?> get props => [];
}

class NotifierResumeEvent<State> extends NotifierEvent<State> {
  const NotifierResumeEvent();

  @override
  String get debugLabel => 'resume';

  @override
  List<Object?> get props => [];
}

class NotifierAddedListenerEvent<State> extends NotifierEvent<State> {
  const NotifierAddedListenerEvent({required this.total});
  final int total;

  @override
  String get debugLabel => 'added listener ($total)';

  @override
  List<Object?> get props => [total];
}

class NotifierRemovedListenerEvent<State> extends NotifierEvent<State> {
  const NotifierRemovedListenerEvent({required this.total});
  final int total;

  @override
  String get debugLabel => 'removed listener ($total)';

  @override
  List<Object?> get props => [total];
}

class NotifierDisposeEvent<State> extends NotifierEvent<State> {
  const NotifierDisposeEvent();

  @override
  String get debugLabel => 'dispose';

  @override
  List<Object?> get props => [];
}
