import 'package:flutter/material.dart';

import '../services/audio_settings_service.dart';
import '../theme/app_theme.dart';

/// Opens the existing Audio Settings bottom sheet.
Future<void> showAudioSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const AudioSettingsSheet(),
  );
}

/// Shared Audio Settings sheet (Sound Active / Inactive).
class AudioSettingsSheet extends StatelessWidget {
  const AudioSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Audio Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: AudioSettingsService.instance,
              builder: (context, _) {
                final enabled = AudioSettingsService.instance.soundEnabled;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        enabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color:
                            enabled ? AppTheme.primaryGreen : AppTheme.greyText,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Sound',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        enabled ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color:
                              enabled
                                  ? AppTheme.primaryGreen
                                  : AppTheme.greyText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        value: enabled,
                        activeTrackColor: AppTheme.primaryGreen.withValues(
                          alpha: 0.55,
                        ),
                        activeThumbColor: AppTheme.primaryGreen,
                        onChanged: (value) {
                          AudioSettingsService.instance.setSoundEnabled(value);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
