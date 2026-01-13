import 'dart:io';
import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/services/lib/core/services/cloudfare_r2_service.dart';
import 'package:couple_note/presentation/widgets/base/snackbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AvatarUploadService {
  final R2StorageService _r2Service;

  AvatarUploadService(this._r2Service);

  Future<String?> uploadAndUpdateAvatar({
    required String userId,
    required Future<void> Function(String newAvatarUrl) onUpdate,
    required BuildContext context,
    required ImageSource source,
  }) async {
    final ImagePicker picker = ImagePicker();
    bool isDialogShowing = false;

    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      if (!context.mounted) return null;
      await Future.delayed(Duration.zero);
      if (!context.mounted) return null;

      _showLoadingDialog(context);
      isDialogShowing = true;

      final File imageFile = File(pickedFile.path);
      final String? newAvatarUrl = await _r2Service.uploadAvatar(
        userId: userId,
        imageFile: imageFile,
      );

      if (isDialogShowing && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        isDialogShowing = false;
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (!context.mounted) return null;

      if (newAvatarUrl == null) {
        CustomSnackBar.showError(
          context,
          message: TransKeys.an_error_occurred.tr(),
        );
        return null;
      }

      await onUpdate(newAvatarUrl);

      return newAvatarUrl;
    } catch (e) {
      if (isDialogShowing && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        isDialogShowing = false;
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (context.mounted) {
        CustomSnackBar.showError(
          context,
          message: TransKeys.an_error_occurred.tr(),
        );
      }

      print('Error uploading avatar: $e');
      return null;
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
                ),
                const SizedBox(height: 16),
                Text(
                  TransKeys.uploading.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
