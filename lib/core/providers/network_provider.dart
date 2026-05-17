import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_provider.g.dart';

enum NetworkStatus { online, offline, checking, slow }

@Riverpod(keepAlive: true)
class NetworkNotifier extends _$NetworkNotifier {
  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _connectionChecker =
      InternetConnectionChecker.createInstance();

  @override
  NetworkStatus build() {
    final connectionSub = _connectionChecker.onStatusChange.listen((
      InternetConnectionStatus status,
    ) {
      switch (status) {
        case InternetConnectionStatus.connected:
          state = NetworkStatus.online;
          break;
        case InternetConnectionStatus.disconnected:
          state = NetworkStatus.offline;
          break;
        case InternetConnectionStatus.slow:
          state = NetworkStatus.slow;
          break;
      }
    });

    ref.onDispose(() => connectionSub.cancel());

    return NetworkStatus.checking;
  }

  Future<void> checkConnection() async {
    state = NetworkStatus.checking;

    final connectivityResult = await _connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      state = NetworkStatus.offline;
      return;
    }

    final hasConnection = await _connectionChecker.hasConnection;
    state = hasConnection ? NetworkStatus.online : NetworkStatus.offline;
  }
}
