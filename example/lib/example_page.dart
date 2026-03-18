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
    ref.read(testProvider.notifier).add(10);
  }

  @override
  Widget build(BuildContext context) {
    final testState = ref.watch(testProvider);
    final testController = ref.watch(testProvider.notifier);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: testController.refresh,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: testState.when(
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
                    return Text(data.join(', '));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
