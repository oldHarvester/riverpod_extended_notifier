import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'notifier_event.dart';
part 'async_notifier_event.dart';

sealed class NotifierEventBase<State> {
  const NotifierEventBase();

  String get debugLabel;
}
