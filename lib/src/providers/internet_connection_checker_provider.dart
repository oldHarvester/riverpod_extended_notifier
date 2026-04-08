part of '../../riverpod_extended_notifier.dart';

abstract final class RiverpodExtendedNotifierProviders {
  static final internetChecker = Provider<FlexibleInternetChecker>(
    (ref) {
      return FlexibleInternetChecker.createInstance(
        interval: Duration(seconds: 4),
      );
    },
  );

  static final internetStatus =
      NotifierProvider<InternetStatusNotifier, InternetStatus>(
        () {
          return InternetStatusNotifier();
        },
      );
}

class InternetStatusNotifier extends ExtendedNotifier<InternetStatus> {
  final CustomLogger logger = CustomLogger(owner: 'InternetStatus');
  late final FlexibleInternetChecker _connectionChecker = ref.read(
    RiverpodExtendedNotifierProviders.internetChecker,
  );
  StreamSubscription<InternetStatus>? _connectionSub;

  @protected
  void onStatusChanged(InternetStatus status) {}

  void _changeStatus(InternetStatus status) {
    if (status != state) {
      state = status;
      logger.log('${status.name} ${DateTime.now()}');
      onStatusChanged(status);
    }
  }

  Future<InternetStatus> checkStatus() async {
    return _connectionChecker.fetchStatus();
  }

  @override
  void onCreate() {
    _connectionSub ??= _connectionChecker.status.listen(
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
  InternetStatus buildState() {
    return _connectionChecker.lastStatus ?? InternetStatus.disconnected;
  }
}
