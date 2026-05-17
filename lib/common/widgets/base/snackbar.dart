import 'package:flutter/material.dart';

class CustomSnackBar {
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFFE8F5E9),
      borderColor: const Color(0xFF4CAF50),
      icon: Icons.check_circle_outline,
      iconColor: const Color(0xFF2E7D32),
      textColor: const Color(0xFF1B5E20),
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFFFFF3E0),
      borderColor: const Color(0xFFFF9800),
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFE65100),
      textColor: const Color(0xFFE65100),
      duration: duration,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFFFFEBEE),
      borderColor: const Color(0xFFEF5350),
      icon: Icons.error_outline,
      iconColor: const Color(0xFFC62828),
      textColor: const Color(0xFFB71C1C),
      duration: duration,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    required Duration duration,
  }) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Color? borderColor,
    IconData? icon,
    Color? iconColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: backgroundColor ?? const Color(0xFFE8F5E9),
      borderColor: borderColor ?? const Color(0xFF4CAF50),
      icon: icon ?? Icons.info_outline,
      iconColor: iconColor ?? const Color(0xFF2E7D32),
      textColor: textColor ?? const Color(0xFF1B5E20),
      duration: duration,
    );
  }
}
