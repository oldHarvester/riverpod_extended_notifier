import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

part 'notifier_event.dart';
part 'async_notifier_event.dart';
part 'lifecycle_change_event.dart';

sealed class NotifierEventBase<State> with EquatableMixin {
  const NotifierEventBase();

  String get debugLabel;
}
