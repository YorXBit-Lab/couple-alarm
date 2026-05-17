import 'package:couple_note/features/auth/presentation/provider/auth_provider.dart';
import 'package:couple_note/features/connect/presentation/provider/scanner_provider.dart';
import 'package:couple_note/features/invitation/domain/entities/invitation.dart';
import 'package:couple_note/features/invitation/domain/usecases/create_invitation_usecase.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scanner_notifier.g.dart';

class QRScannerState {
  final bool isScanned;
  final bool isFlashOn;
  final bool isFrontCamera;
  final bool isLoading;
  final String? errorMessage;
  final String? scannedCode;
  final bool isCameraReady;
  final bool isProcessing;

  const QRScannerState({
    this.isScanned = false,
    this.isFlashOn = false,
    this.isFrontCamera = false,
    this.isLoading = false,
    this.errorMessage,
    this.scannedCode,
    this.isCameraReady = false,
    this.isProcessing = false,
  });

  QRScannerState copyWith({
    bool? isScanned,
    bool? isFlashOn,
    bool? isFrontCamera,
    bool? isLoading,
    String? errorMessage,
    String? scannedCode,
    bool? isCameraReady,
    bool? isProcessing,
    bool clearError = false,
    bool clearScannedCode = false,
  }) {
    return QRScannerState(
      isScanned: isScanned ?? this.isScanned,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      scannedCode: clearScannedCode ? null : (scannedCode ?? this.scannedCode),
      isCameraReady: isCameraReady ?? this.isCameraReady,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

@riverpod
class QrScannerNotifier extends _$QrScannerNotifier {
  late CreateInvitationUseCase _createInvitationUseCase;
  String? currentUserId;

  MobileScannerController? _controller;
  bool _isDisposed = false;
  bool _isInitializing = false;

  MobileScannerController? get controller => _controller;

  @override
  QRScannerState build() {
    _createInvitationUseCase = ref.read(createInvitationUseCaseProvider);
    currentUserId = ref.read(currentUserProvider)?.uid;

    ref.onDispose(() {
      _isDisposed = true;
      _safeDisposeController();
    });

    _createController();
    return const QRScannerState();
  }

  void _createController() {
    if (_isDisposed) return;

    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
        returnImage: false,
        formats: [BarcodeFormat.qrCode],
        autoStart: false,
      );

      if (!_isDisposed) {
        state = state.copyWith(clearError: true);
      }
    } catch (e) {
      print('Controller creation error: $e');
      if (!_isDisposed) {
        state = state.copyWith(
          errorMessage: _getCameraErrorMessage(e),
          isCameraReady: false,
        );
      }
    }
  }

  Future<void> startCamera() async {
    if (_isDisposed || _isInitializing || _controller == null) return;

    _isInitializing = true;

    try {
      await _controller!.start();

      await Future.delayed(const Duration(milliseconds: 500));

      if (!_isDisposed) {
        state = state.copyWith(isCameraReady: true, clearError: true);
      }
    } catch (e) {
      print('Camera start error: $e');
      if (!_isDisposed) {
        state = state.copyWith(
          errorMessage: _getCameraErrorMessage(e),
          isCameraReady: false,
        );
      }
    } finally {
      _isInitializing = false;
    }
  }

  String _getCameraErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('permission')) {
      return 'Vui lòng cấp quyền camera để sử dụng tính năng quét mã QR.';
    } else if (errorStr.contains('camera')) {
      return 'Không thể truy cập camera. Vui lòng thử lại.';
    } else {
      return 'Lỗi khởi tạo camera. Vui lòng khởi động lại ứng dụng.';
    }
  }

  Future<void> _safeDisposeController() async {
    try {
      if (_controller != null) {
        await _controller!.stop();
        _controller!.dispose();
        _controller = null;
      }
    } catch (e) {
      print('Error disposing controller: $e');
    }
  }

  void onDetect(BarcodeCapture capture) {
    if (state.isScanned || state.isProcessing || _isDisposed) return;

    if (capture.barcodes.isNotEmpty) {
      final String? code = capture.barcodes.first.rawValue;
      if (code != null && code.isNotEmpty && !_isDisposed) {
        _controller?.stop();

        state = state.copyWith(isScanned: true, scannedCode: code);

        HapticFeedback.mediumImpact();
        _processScannedCode(code);
      }
    }
  }

  Future<void> _processScannedCode(String code) async {
    try {
      if (_isDisposed) return;

      state = state.copyWith(isProcessing: true);

      String? toUserId = _extractUserIdFromCode(code);

      if (currentUserId != null && toUserId == currentUserId) {
        throw Exception('Không thể kết nối với chính mình');
      }

      if (toUserId == null || toUserId.isEmpty) {
        throw Exception('Mã QR không hợp lệ');
      }

      await _createInvitationUseCase.call(
        InvitationEntity(
          fromUserId: currentUserId!,
          toUserId: toUserId,
          createdAt: DateTime.now(),
        ),
      );

      if (!_isDisposed) {
        state = state.copyWith(isProcessing: false, isLoading: false);
      }
    } catch (e) {
      if (!_isDisposed) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');

        state = state.copyWith(
          errorMessage: errorMessage,
          isProcessing: false,
          isScanned: false,
          clearScannedCode: true,
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isDisposed) {
            _restartCamera();
          }
        });
      }
    }
  }

  String? _extractUserIdFromCode(String code) {
    try {
      code = code.trim();

      if (code.startsWith('http://') || code.startsWith('https://')) {
        Uri uri = Uri.parse(code);

        if (uri.queryParameters.containsKey('userId')) {
          return uri.queryParameters['userId']!;
        }

        if (uri.pathSegments.isNotEmpty) {
          String lastSegment = uri.pathSegments.last;
          if (lastSegment.isNotEmpty && lastSegment != 'invite') {
            return lastSegment;
          }
        }

        throw Exception('URL không chứa thông tin người dùng hợp lệ');
      }

      if (_isValidUserId(code)) {
        return code;
      }

      return null;
    } catch (e) {
      throw Exception('Không thể phân tích mã QR');
    }
  }

  bool _isValidUserId(String userId) {
    if (userId.isEmpty) return false;

    if (userId.length == 28 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(userId)) {
      return true;
    }

    if (RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    ).hasMatch(userId.toLowerCase())) {
      return true;
    }

    if (userId.length >= 6 &&
        userId.length <= 50 &&
        RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(userId)) {
      return true;
    }

    return false;
  }

  Future<void> toggleFlash() async {
    try {
      if (_controller == null || _isDisposed) return;

      await _controller!.toggleTorch();
      if (!_isDisposed) {
        state = state.copyWith(isFlashOn: !state.isFlashOn);
      }

      HapticFeedback.lightImpact();
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(errorMessage: 'Không thể bật/tắt đèn flash');
      }
    }
  }

  Future<void> switchCamera() async {
    try {
      if (_controller == null || _isDisposed) return;

      await _controller!.switchCamera();
      if (!_isDisposed) {
        state = state.copyWith(isFrontCamera: !state.isFrontCamera);
      }

      HapticFeedback.lightImpact();
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(errorMessage: 'Không thể chuyển camera');
      }
    }
  }

  Future<void> processManualInput(String code) async {
    if (code.trim().isEmpty) {
      if (!_isDisposed) {
        state = state.copyWith(errorMessage: 'Vui lòng nhập mã hợp lệ');
      }
      return;
    }

    if (!_isDisposed) {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        scannedCode: code.trim(),
        isScanned: true,
        isProcessing: true,
      );
    }

    try {
      await _processScannedCode(code.trim());
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(
          errorMessage:
              'Lỗi xử lý mã: ${e.toString().replaceAll('Exception: ', '')}',
          isLoading: false,
          isScanned: false,
          isProcessing: false,
          clearScannedCode: true,
        );
      }
    }
  }

  Future<void> _restartCamera() async {
    if (_isDisposed || _isInitializing) return;

    try {
      if (_controller != null) {
        await _controller!.start();

        if (!_isDisposed) {
          state = state.copyWith(
            isCameraReady: true,
            isScanned: false,
            isProcessing: false,
            clearError: true,
            clearScannedCode: true,
          );
        }
      } else {
        _createController();
      }
    } catch (e) {
      print('Error restarting camera: $e');
      if (!_isDisposed) {
        state = state.copyWith(
          errorMessage: 'Không thể khởi động lại camera',
          isCameraReady: false,
        );
      }
    }
  }

  Future<void> resetScanner() async {
    if (_isDisposed) return;

    if (!_isDisposed) {
      state = const QRScannerState();
    }

    await _safeDisposeController();
    _createController();
  }

  void clearError() {
    if (!_isDisposed) {
      state = state.copyWith(clearError: true);

      if (!state.isCameraReady && !state.isProcessing) {
        _restartCamera();
      }
    }
  }

  String? get scannedResult => state.scannedCode;
  bool get isScannerReady =>
      state.isCameraReady && !state.isScanned && !_isDisposed;

  Future<void> initializeCameraAfterBuild() async {
    await startCamera();
  }
}
