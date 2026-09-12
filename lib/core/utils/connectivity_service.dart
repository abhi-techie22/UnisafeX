import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  // Emit initial status
  final initial = await Connectivity().checkConnectivity();
  yield _hasNetwork(initial);

  // Then stream changes
  await for (final result in Connectivity().onConnectivityChanged) {
    yield _hasNetwork(result);
  }
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).value ?? true;
});

bool _hasNetwork(List<ConnectivityResult> results) {
  return results.any((result) => result != ConnectivityResult.none);
}
