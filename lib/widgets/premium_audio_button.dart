import 'package:flutter/material.dart';

import '../services/audio_settings_service.dart';
import '../theme/app_theme.dart';
import 'audio_settings_sheet.dart';

/// Premium circular audio control matching the center Scan button family.
class PremiumAudioButton extends StatelessWidget {
  final double size;
  final double iconSize;
  final bool pulse;

  const PremiumAudioButton({
    super.key,
    this.size = 40,
    this.iconSize = 20,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AudioSettingsService.instance,
      builder: (context, _) {
        final enabled = AudioSettingsService.instance.soundEnabled;
        final child = _PremiumAudioGlyph(
          size: size,
          iconSize: iconSize,
          enabled: enabled,
          animate: pulse,
          onTap: () => showAudioSettingsSheet(context),
        );
        return child;
      },
    );
  }
}

class _PremiumAudioGlyph extends StatefulWidget {
  final double size;
  final double iconSize;
  final bool enabled;
  final bool animate;
  final VoidCallback onTap;

  const _PremiumAudioGlyph({
    required this.size,
    required this.iconSize,
    required this.enabled,
    required this.animate,
    required this.onTap,
  });

  @override
  State<_PremiumAudioGlyph> createState() => _PremiumAudioGlyphState();
}

class _PremiumAudioGlyphState extends State<_PremiumAudioGlyph>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _pulse;
    if (controller == null) {
      return _buildButton(scale: 1, glow: 0.16, borderAlpha: 0.40);
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return _buildButton(
          scale: 1.0 + (t * 0.04),
          glow: 0.14 + (t * 0.16),
          borderAlpha: 0.35 + (t * 0.20),
        );
      },
    );
  }

  Widget _buildButton({
    required double scale,
    required double glow,
    required double borderAlpha,
  }) {
    return Tooltip(
      message: 'Audio Settings',
      child: GestureDetector(
        onTap: widget.onTap,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.darkBackground,
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(
                  alpha: widget.enabled ? borderAlpha : 0.22,
                ),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(
                    alpha: widget.enabled ? glow : 0.06,
                  ),
                  blurRadius: 12,
                  spreadRadius: 0.4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              widget.enabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: widget.enabled ? AppTheme.primaryGreen : AppTheme.greyText,
              size: widget.iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
