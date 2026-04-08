import 'package:equatable/equatable.dart';
import 'package:flexible_internet_checker/flexible_internet_checker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'notifier_event.dart';
part 'async_notifier_event.dart';
part 'lifecycle_change_event.dart';

sealed class NotifierEventBase<State> with EquatableMixin {
  const NotifierEventBase();

  String get debugLabel;
}
