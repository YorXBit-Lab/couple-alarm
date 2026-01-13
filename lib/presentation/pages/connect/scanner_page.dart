import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/presentation/themes/app_colors.dart';
import 'package:couple_note/presentation/viewmodels/scanner_viewmodel.dart';
import 'package:couple_note/presentation/widgets/base/custom_dialog_widget.dart';
import 'package:couple_note/presentation/widgets/base/snackbar.dart';
import 'package:couple_note/providers/scanner_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends ConsumerStatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  ConsumerState<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends ConsumerState<QRScannerPage>
    with TickerProviderStateMixin {
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _initializeScanLineAnimation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }

  void _initializeScanLineAnimation() {
    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    final viewModel = ref.read(qrScannerActionsProvider);
    await viewModel.initializeCameraAfterBuild();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<QRScannerState>(qrScannerViewModelProvider, (previous, next) {
      _handleStateChanges(previous, next);
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: SafeArea(child: _buildBody()),
    );
  }

  void _handleStateChanges(QRScannerState? previous, QRScannerState next) {
    if (next.isScanned && !next.isProcessing) {
      _scanLineController.stop();
    } else if (!next.isScanned && (previous?.isScanned == true)) {
      _scanLineController.repeat();
    }

    // Hiển thị success snackbar và navigate về
    if (next.scannedCode != null &&
        !next.isProcessing &&
        next.errorMessage == null &&
        previous?.isProcessing == true) {
      CustomSnackBar.showSuccess(
        context,
        message: TransKeys.create_success.tr(),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context, next.scannedCode);
        }
      });
    }

    if (next.errorMessage != null &&
        previous?.errorMessage != next.errorMessage) {
      _showErrorDialog(next.errorMessage!);
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        TransKeys.scan_qr_code.tr(),
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
      ),
      backgroundColor: Colors.black.withValues(alpha: 0.3),
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_back, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        _buildFlashButton(),
        const SizedBox(width: 8),
        _buildCameraSwitchButton(),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildFlashButton() {
    return Consumer(
      builder: (context, ref, child) {
        final isFlashOn = ref.watch(isFlashOnProvider);

        return IconButton(
          onPressed: () => ref.read(qrScannerActionsProvider).toggleFlash(),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isFlashOn
                  ? const Color(0xFFFEF3C7)
                  : Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: isFlashOn ? const Color(0xFFF59E0B) : Colors.white,
              size: 20,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCameraSwitchButton() {
    return IconButton(
      onPressed: () => ref.read(qrScannerActionsProvider).switchCamera(),
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.flip_camera_ios, size: 20),
      ),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        _buildCameraView(),
        _buildScanOverlay(),
        _buildTopInfoPanel(),
        _buildBottomControlPanel(),
      ],
    );
  }

  Widget _buildCameraView() {
    return Consumer(
      builder: (context, ref, child) {
        final controller = ref.watch(mobileScannerControllerProvider);
        final viewModel = ref.read(qrScannerActionsProvider);

        if (controller == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return MobileScanner(
          controller: controller,
          onDetect: viewModel.onDetect,
        );
      },
    );
  }

  Widget _buildScanOverlay() {
    return AnimatedBuilder(
      animation: _scanLineAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: QRScannerOverlay(animationValue: _scanLineAnimation.value),
          child: Container(),
        );
      },
    );
  }

  Widget _buildTopInfoPanel() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.qr_code_scanner_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TransKeys.scan_qr_code_to_connect.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    TransKeys.point_the_camera_at.tr(),
                    style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControlPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.8),
              Colors.black.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIndicator(),
            const SizedBox(height: 24),
            _buildManualInputButton(),
            const SizedBox(height: 12),
            _buildHelpText(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Consumer(
      builder: (context, ref, child) {
        final statusText = ref.watch(cameraStatusTextProvider);
        final statusColor = ref.watch(cameraStatusColorProvider);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildManualInputButton() {
    return Consumer(
      builder: (context, ref, child) {
        final isProcessing = ref.watch(isProcessingQRProvider);

        return SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: isProcessing ? null : _showManualInput,
            icon: const Icon(Icons.keyboard_outlined, size: 18),
            label: Text(
              TransKeys.enter_the_code_manually.tr(),
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpText() {
    return Text(
      TransKeys.qr_code_will_be_scanned.tr(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: 12,
      ),
      textAlign: TextAlign.center,
    );
  }

  void _showErrorDialog(String errorMessage) {
    CustomDialog.showConfirmDialog(
      context: context,
      title: TransKeys.conneciton_failed.tr(),
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
      confirmText: TransKeys.close.tr(),
      primaryColor: const Color(0xFF64748B),
      isDanger: true,
    ).then((confirmed) {
      if (mounted) {
        ref.read(qrScannerActionsProvider).clearError();
      }
    });
  }

  void _showManualInput() async {
    final result = await CustomDialog.showInputDialog(
      context: context,
      title: TransKeys.enter_the_connection_code.tr(),
      hintText: TransKeys.paste_code_or_link_here.tr(),
      cancelText: TransKeys.cancel.tr(),
      confirmText: TransKeys.confirm.tr(),
      primaryColor: AppColors.primary,
    );

    if (result != null && result.isNotEmpty) {
      ref.read(qrScannerActionsProvider).processManualInput(result);
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }
}

class QRScannerOverlay extends CustomPainter {
  final double animationValue;

  QRScannerOverlay({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final Paint cornerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final Paint scanLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.primary.withValues(alpha: 0.8),
          AppColors.primary,
          AppColors.primary.withValues(alpha: 0.8),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2;

    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;
    final Rect scanArea = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Draw overlay with cutout
    Path overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, overlayPaint);

    // Draw animated scan line
    final double scanLineY = scanArea.top + (scanArea.height * animationValue);

    canvas.drawLine(
      Offset(scanArea.left + 20, scanLineY),
      Offset(scanArea.right - 20, scanLineY),
      scanLinePaint,
    );

    // Draw corner indicators with rounded style
    final double cornerLength = 25;
    final double cornerRadius = 3;

    // Top left
    Path topLeft = Path()
      ..moveTo(scanArea.left, scanArea.top + cornerLength)
      ..lineTo(scanArea.left, scanArea.top + cornerRadius)
      ..quadraticBezierTo(
        scanArea.left,
        scanArea.top,
        scanArea.left + cornerRadius,
        scanArea.top,
      )
      ..lineTo(scanArea.left + cornerLength, scanArea.top);
    canvas.drawPath(topLeft, cornerPaint);

    // Top right
    Path topRight = Path()
      ..moveTo(scanArea.right - cornerLength, scanArea.top)
      ..lineTo(scanArea.right - cornerRadius, scanArea.top)
      ..quadraticBezierTo(
        scanArea.right,
        scanArea.top,
        scanArea.right,
        scanArea.top + cornerRadius,
      )
      ..lineTo(scanArea.right, scanArea.top + cornerLength);
    canvas.drawPath(topRight, cornerPaint);

    // Bottom left
    Path bottomLeft = Path()
      ..moveTo(scanArea.left, scanArea.bottom - cornerLength)
      ..lineTo(scanArea.left, scanArea.bottom - cornerRadius)
      ..quadraticBezierTo(
        scanArea.left,
        scanArea.bottom,
        scanArea.left + cornerRadius,
        scanArea.bottom,
      )
      ..lineTo(scanArea.left + cornerLength, scanArea.bottom);
    canvas.drawPath(bottomLeft, cornerPaint);

    // Bottom right
    Path bottomRight = Path()
      ..moveTo(scanArea.right - cornerLength, scanArea.bottom)
      ..lineTo(scanArea.right - cornerRadius, scanArea.bottom)
      ..quadraticBezierTo(
        scanArea.right,
        scanArea.bottom,
        scanArea.right,
        scanArea.bottom - cornerRadius,
      )
      ..lineTo(scanArea.right, scanArea.bottom - cornerLength);
    canvas.drawPath(bottomRight, cornerPaint);
  }

  @override
  bool shouldRepaint(QRScannerOverlay oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
