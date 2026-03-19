import 'package:example/test_async_provider.dart';
import 'package:example/test_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExamplePage extends ConsumerStatefulWidget {
  const ExamplePage({super.key});

  @override
  ConsumerState<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends ConsumerState<ExamplePage> {
  @override
  void initState() {
    super.initState();
    ref.read(testAsyncProvider.notifier).add(10);
  }

  Widget buildView({
    required AsyncValue<List<int>> state,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: state.when(
                skipError: false,
                skipLoadingOnRefresh: false,
                skipLoadingOnReload: false,
                error: (error, stackTrace) {
                  return Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  );
                },
                loading: () {
                  return SizedBox.square(
                    dimension: 30,
                    child: CircularProgressIndicator(),
                  );
                },
                data: (data) {
                  return Text(
                    data.join(', '),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapBorder({required Widget child}) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final testAsyncState = ref.watch(testAsyncProvider);
    final testAsyncController = ref.watch(testAsyncProvider.notifier);
    final testSyncState = ref.watch(testProvider);
    // final testSyncController = ref.watch(testProvider.notifier);
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: _wrapBorder(
              child: buildView(
                onRefresh: testAsyncController.refresh,
                state: testAsyncState,
              ),
            ),
          ),
          Expanded(
            child: _wrapBorder(
              child: buildView(
                onRefresh: () async {
                  ref.invalidate(testProvider);
                },
                state: AsyncData(testSyncState),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
