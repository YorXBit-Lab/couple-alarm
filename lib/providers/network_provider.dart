import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

enum NetworkStatus { online, offline, checking, slow }

class NetworkNotifier extends StateNotifier<NetworkStatus> {
  NetworkNotifier() : super(NetworkStatus.checking) {
    _initialize();
  }

  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _connectionChecker =
      InternetConnectionChecker.createInstance();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  StreamSubscription<InternetConnectionStatus>? _connectionSubscription;

  void _initialize() async {
    _connectionSubscription = _connectionChecker.onStatusChange.listen((
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

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}

final networkProvider = StateNotifierProvider<NetworkNotifier, NetworkStatus>(
  (ref) => NetworkNotifier(),
);
