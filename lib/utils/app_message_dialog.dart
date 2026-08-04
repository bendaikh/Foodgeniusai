import 'package:flutter/material.dart';

import '../exceptions/free_recipe_limit_exception.dart';
import '../exceptions/generation_limit_exception.dart';
import '../theme/app_theme.dart';

class AppMessageDialog {
  AppMessageDialog._();

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.info_outline_rounded,
    Color iconColor = AppTheme.primaryGreen,
    String confirmLabel = 'OK',
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: iconColor.withOpacity(0.25)),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColor.withOpacity(0.35)),
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.greyText,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            if (secondaryLabel != null)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onSecondary?.call();
                },
                child: Text(secondaryLabel),
              ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: AppTheme.darkBackground,
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showGenerationLimit({
    required BuildContext context,
    required String message,
    VoidCallback? onViewPlans,
  }) {
    return show(
      context: context,
      title: 'Monthly limit reached',
      message: message,
      icon: Icons.auto_awesome_outlined,
      iconColor: Colors.orangeAccent,
      confirmLabel: 'Got it',
      secondaryLabel: onViewPlans != null ? 'View plans' : null,
      onSecondary: onViewPlans,
    );
  }

  static Future<void> showFridgeScanLimit({
    required BuildContext context,
    required String message,
    VoidCallback? onViewPlans,
  }) {
    return show(
      context: context,
      title: 'Fridge Scan limit reached',
      message: message,
      icon: Icons.kitchen_outlined,
      iconColor: Colors.orangeAccent,
      confirmLabel: 'Got it',
      secondaryLabel: onViewPlans != null ? 'View plans' : null,
      onSecondary: onViewPlans,
    );
  }

  static Future<void> showError({
    required BuildContext context,
    required String message,
    String title = 'Something went wrong',
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      icon: Icons.error_outline_rounded,
      iconColor: Colors.orangeAccent,
    );
  }

  /// Destructive confirm. Returns `true` only when the user taps [confirmLabel].
  static Future<bool> confirmDestructive({
    required BuildContext context,
    required String title,
    required String message,
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Delete',
    IconData icon = Icons.delete_outline_rounded,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(icon, color: Colors.redAccent, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.greyText,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                cancelLabel,
                style: const TextStyle(color: AppTheme.greyText),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  static String cleanErrorMessage(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('GenerationLimitException: ', '')
        .replaceFirst('FridgeScanLimitException: ', '')
        .replaceFirst('FreeRecipeLimitException: ', '');
  }

  static bool isGenerationLimitError(Object error) {
    if (error is FreeRecipeLimitException) return false;
    if (error is FridgeScanLimitException) return false;
    return error is GenerationLimitException ||
        error.toString().contains('used all') &&
            error.toString().contains('generations');
  }

  static bool isFridgeScanLimitError(Object error) {
    return error is FridgeScanLimitException ||
        (error.toString().contains('used all') &&
            error.toString().contains('Fridge Scan'));
  }
}
