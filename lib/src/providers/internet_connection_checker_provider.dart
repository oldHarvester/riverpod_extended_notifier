part of '../../riverpod_extended_notifier.dart';

abstract final class RiverpodExtendedNotifierProviders {
  static final internetConnectionCheckerProvider =
      Provider<InternetConnectionChecker>(
        (ref) {
          return InternetConnectionChecker.createInstance(
            checkInterval: Duration(seconds: 4),
          );
        },
      );

  static final internetStatusProvider =
      NotifierProvider<InternetStatusNotifier, InternetConnectionStatus>(
        () {
          return InternetStatusNotifier();
        },
      );
}

class InternetStatusNotifier
    extends ExtendedNotifier<InternetConnectionStatus> {
  StreamSubscription<InternetConnectionStatus>? _connectionSub;
  final CustomLogger logger = CustomLogger(owner: 'InternetStatus');
  late final InternetConnectionChecker _connectionChecker = ref.read(
    RiverpodExtendedNotifierProviders.internetConnectionCheckerProvider,
  );
  FlexibleCompleter<InternetConnectionStatus>? _statusFetchCompleter;

  @protected
  void onStatusChanged(InternetConnectionStatus status) {}

  void _changeStatus(InternetConnectionStatus status) {
    if (status != state) {
      state = status;
      logger.log(status.name);
      onStatusChanged(status);
    }
  }

  Future<InternetConnectionStatus> checkStatus() async {
    final oldCompleter = _statusFetchCompleter;
    if (oldCompleter != null && !oldCompleter.isCompleted) {
      return oldCompleter.future;
    }
    final completer = FlexibleCompleter<InternetConnectionStatus>();
    try {
      final status = await _connectionChecker.connectionStatus;
      if (completer.canPerformAction(_statusFetchCompleter)) {
        completer.complete(status);
        _changeStatus(status);
      }
    } catch (e, stk) {
      completer.completeError(e, stk);
      rethrow;
    }
    return completer.future;
  }

  @override
  void onCreate() {
    _connectionSub = _connectionChecker.onStatusChange.listen(
      (status) {
        _changeStatus(status);
      },
    );
    checkStatus();
  }

  @override
  void onWillInvalidate() {
    checkStatus();
  }

  @override
  void onDispose() {
    _connectionSub?.cancel();
    super.onDispose();
  }

  @override
  InternetConnectionStatus buildState() {
    // ignore: invalid_use_of_visible_for_testing_member
    return _connectionChecker.lastStatus ?? InternetConnectionStatus.connected;
  }
}
