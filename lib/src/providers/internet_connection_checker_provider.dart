part of '../../riverpod_extended_notifier.dart';

final internetConnectionCheckerProvider = Provider<InternetConnectionChecker>(
  (ref) {
    return InternetConnectionChecker.createInstance(
      checkInterval: Duration(seconds: 4),
    );
  },
);

final internetStatusProvider =
    NotifierProvider<InternetStatusNotifier, InternetConnectionStatus>(
      () {
        return InternetStatusNotifier();
      },
    );

class InternetStatusNotifier
    extends ExtendedNotifier<InternetConnectionStatus> {
  StreamSubscription<InternetConnectionStatus>? _connectionSub;
  final CustomLogger logger = CustomLogger(owner: 'InternetStatus');
  late final InternetConnectionChecker _connectionChecker = ref.read(
    internetConnectionCheckerProvider,
  );

  void _onStatusChanged(InternetConnectionStatus status) {
    if (status != state) {
      state = status;
      logger.log(status.name);
    }
  }

  @override
  void onCreate() {
    final completer = FlexibleCompleter();
    _connectionSub = _connectionChecker.onStatusChange.listen(
      (status) {
        completer.complete();
        _onStatusChanged(status);
      },
    );
    _connectionChecker.connectionStatus.then(
      (status) {
        if (completer.canPerformAction(completer)) {
          _onStatusChanged(status);
          completer.complete();
        }
      },
    );
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
