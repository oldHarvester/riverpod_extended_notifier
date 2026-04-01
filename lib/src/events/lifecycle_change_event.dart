part of 'notifier_event_base.dart';

enum NotifierLifecycleState {
  idle,
  paused,
  working,
  disposed,
}

class NotifierLifecycleChangeEvent<State> extends NotifierEventBase<State> {
  const NotifierLifecycleChangeEvent({
    required this.previous,
    required this.next,
  });

  final NotifierLifecycleState previous;
  final NotifierLifecycleState next;

  bool get resumed =>
      previous == NotifierLifecycleState.paused &&
      next == NotifierLifecycleState.working;

  bool get started =>
      previous == NotifierLifecycleState.idle &&
      next == NotifierLifecycleState.working;

  @override
  String get debugLabel => 'lifecycle changed - $next';

  @override
  List<Object?> get props => [previous, next];
}
