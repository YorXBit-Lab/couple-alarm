import 'package:couple_note/core/providers/global_providers.dart';
import 'package:couple_note/features/invitation/domain/usecases/create_invitation_usecase.dart';
import 'package:couple_note/features/invitation/domain/usecases/get_pending_invitation.dart';
import 'package:couple_note/features/invitation/domain/usecases/update_invitation_status_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scanner_provider.g.dart';

@riverpod
CreateInvitationUseCase createInvitationUseCase(Ref ref) {
  return CreateInvitationUseCase(ref.read(invitationRepositoryProvider));
}

@riverpod
GetPendingInvitationsUseCase getPendingInvitationsUseCase(Ref ref) {
  return GetPendingInvitationsUseCase(ref.read(invitationRepositoryProvider));
}

@riverpod
UpdateInvitationStatusUseCase updateInvitationStatus(Ref ref) {
  return UpdateInvitationStatusUseCase(ref.read(invitationRepositoryProvider));
}

class QRScannerConfig {
  final bool enableFlash;
  final bool enableCameraSwitch;
  final bool enableManualInput;
  final double scanAreaSize;

  const QRScannerConfig({
    this.enableFlash = true,
    this.enableCameraSwitch = true,
    this.enableManualInput = true,
    this.scanAreaSize = 0.7,
  });
}

class QRScannerConfigParams {
  final bool enableFlash;
  final bool enableCameraSwitch;
  final bool enableManualInput;
  final double scanAreaSize;

  const QRScannerConfigParams({
    this.enableFlash = true,
    this.enableCameraSwitch = true,
    this.enableManualInput = true,
    this.scanAreaSize = 0.7,
  });
}

@riverpod
QRScannerConfig qrScannerConfig(Ref ref, QRScannerConfigParams params) {
  return QRScannerConfig(
    enableFlash: params.enableFlash,
    enableCameraSwitch: params.enableCameraSwitch,
    enableManualInput: params.enableManualInput,
    scanAreaSize: params.scanAreaSize,
  );
}

@riverpod
Future<bool> qrScannerPermission(Ref ref) async {
  try {
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  } catch (e) {
    return false;
  }
}

