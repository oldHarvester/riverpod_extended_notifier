part of '../../riverpod_extended_notifier.dart';

final internetConnectionCheckerProvider = Provider<InternetConnection>(
  (ref) {
    return InternetConnection.createInstance(
      checkInterval: Duration(seconds: 4),
    );
  },
);

final internetStatusProvider =
    NotifierProvider<InternetStatusNotifier, InternetStatus>(
      () {
        return InternetStatusNotifier();
      },
    );

class InternetStatusNotifier extends ExtendedNotifier<InternetStatus> {
  StreamSubscription<InternetStatus>? _connectionSub;
  final CustomLogger logger = CustomLogger(owner: 'InternetStatus');

  void _onStatusChanged(InternetStatus status) {
    if (status != state) {
      state = status;
    }
    logger.log(status.name);
  }

  @override
  void onCreate() {
    final completer = FlexibleCompleter();
    final checker = ref.read(internetConnectionCheckerProvider);
    _connectionSub = checker.onStatusChange.listen(
      (status) {
        if (completer.canPerformAction(completer)) {
          _onStatusChanged(status);
          completer.complete();
        }
      },
    );
    checker.internetStatus.then(
      (status) {
        completer.complete();
        _onStatusChanged(status);
      },
    );
  }

  @override
  void onDispose() {
    _connectionSub?.cancel();
    super.onDispose();
  }

  @override
  InternetStatus buildState() {
    return InternetStatus.connected;
  }
}
