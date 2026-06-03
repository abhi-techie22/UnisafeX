import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  // Emit initial status
  final initial = await Connectivity().checkConnectivity();
  yield initial != ConnectivityResult.none;

  // Then stream changes
  await for (final result in Connectivity().onConnectivityChanged) {
    yield result != ConnectivityResult.none;
  }
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).value ?? true;
});
