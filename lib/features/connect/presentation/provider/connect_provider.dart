import 'package:couple_note/core/services/connectivity_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connect_provider.g.dart';

@riverpod
ConnectivityService connectivityService(Ref ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
}
