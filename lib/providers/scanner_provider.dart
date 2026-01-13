import 'package:couple_note/di/dependency_injection.dart';
import 'package:couple_note/domain/usecases/invitation/create_invitation_usecase.dart';
import 'package:couple_note/domain/usecases/invitation/get_pending_invitation.dart';
import 'package:couple_note/domain/usecases/invitation/update_invitation_status_usecase.dart';
import 'package:couple_note/presentation/viewmodels/scanner_viewmodel.dart';
import 'package:couple_note/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

final createInvitationUseCaseProvider = Provider<CreateInvitationUseCase>((
  ref,
) {
  final invitationRepository = ref.read(invitationRepositoryProvider);
  return CreateInvitationUseCase(invitationRepository);
});

final getPendingInvitationsUseCaseProvider =
    Provider<GetPendingInvitationsUseCase>((ref) {
      final invitationRepository = ref.read(invitationRepositoryProvider);
      return GetPendingInvitationsUseCase(invitationRepository);
    });

final updateInvitationStatusProvider = Provider<UpdateInvitationStatusUseCase>((
  ref,
) {
  final invitationRepository = ref.read(invitationRepositoryProvider);
  return UpdateInvitationStatusUseCase(invitationRepository);
});
final qrScannerViewModelProvider =
    StateNotifierProvider.autoDispose<QRScannerViewModel, QRScannerState>((
      ref,
    ) {
      final createInvitationUseCase = ref.read(createInvitationUseCaseProvider);
      final currentUser = ref.read(currentUserProvider);

      return QRScannerViewModel(
        createInvitationUseCase: createInvitationUseCase,
        ref: ref,
        currentUserId: currentUser?.uid,
      );
    });
final qrScannerStateProvider = Provider.autoDispose<QRScannerState>((ref) {
  return ref.watch(qrScannerViewModelProvider);
});

final qrScannerActionsProvider = Provider.autoDispose<QRScannerViewModel>((
  ref,
) {
  return ref.read(qrScannerViewModelProvider.notifier);
});

final mobileScannerControllerProvider =
    Provider.autoDispose<MobileScannerController?>((ref) {
      return ref.watch(qrScannerViewModelProvider.notifier).controller;
    });

final isQRScannerLoadingProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(
    qrScannerViewModelProvider.select((state) => state.isLoading),
  );
});

final qrScannerErrorProvider = Provider.autoDispose<String?>((ref) {
  return ref.watch(
    qrScannerViewModelProvider.select((state) => state.errorMessage),
  );
});

final isFlashOnProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(
    qrScannerViewModelProvider.select((state) => state.isFlashOn),
  );
});

final isFrontCameraProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(
    qrScannerViewModelProvider.select((state) => state.isFrontCamera),
  );
});

final isProcessingQRProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(
    qrScannerViewModelProvider.select((state) => state.isProcessing),
  );
});

final scannedCodeProvider = Provider.autoDispose<String?>((ref) {
  return ref.watch(
    qrScannerViewModelProvider.select((state) => state.scannedCode),
  );
});

final isCameraReadyProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(
    qrScannerViewModelProvider.select((state) => state.isCameraReady),
  );
});

final cameraStatusTextProvider = Provider.autoDispose<String>((ref) {
  final state = ref.watch(qrScannerViewModelProvider);

  if (state.isProcessing) {
    return 'Đang xử lý...';
  } else if (state.isScanned) {
    return 'Đã quét thành công';
  } else if (state.isCameraReady) {
    return 'Camera đã sẵn sàng';
  } else {
    return 'Đang khởi tạo camera...';
  }
});

// Provider for camera status color
final cameraStatusColorProvider = Provider.autoDispose<Color>((ref) {
  final state = ref.watch(qrScannerViewModelProvider);

  if (state.errorMessage != null) {
    return const Color(0xFFEF4444); // Red
  } else if (state.isProcessing) {
    return const Color(0xFFF59E0B); // Yellow
  } else if (state.isScanned) {
    return const Color(0xFF10B981); // Green
  } else if (state.isCameraReady) {
    return const Color(0xFF10B981); // Green
  } else {
    return const Color(0xFF6B7280); // Gray
  }
});

final qrScannerConfigProvider = Provider.autoDispose
    .family<QRScannerConfig, QRScannerConfigParams>((ref, params) {
      return QRScannerConfig(
        enableFlash: params.enableFlash,
        enableCameraSwitch: params.enableCameraSwitch,
        enableManualInput: params.enableManualInput,
        scanAreaSize: params.scanAreaSize,
      );
    });

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

final qrScannerPermissionProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  try {
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  } catch (e) {
    print('Permission check error: $e');
    return false;
  }
});
