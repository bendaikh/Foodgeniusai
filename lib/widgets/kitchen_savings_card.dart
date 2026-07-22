import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import '../theme/app_theme.dart';

/// Compact entry point for the Kitchen Savings feature.
class KitchenSavingsCard extends StatelessWidget {
  final VoidCallback onTap;

  const KitchenSavingsCard({super.key, required this.onTap});

  static const double _progress = 0.20;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    const borderRadius = BorderRadius.all(Radius.circular(20));

    return Semantics(
      button: true,
      label:
          kKitchenSavingsFreeForTesting
              ? 'View savings details'
              : 'Unlock smart savings tracking',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide(
              color: AppTheme.primaryGreen.withValues(alpha: 0.28),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            splashColor: AppTheme.primaryGreen.withValues(alpha: 0.10),
            highlightColor: AppTheme.primaryGreen.withValues(alpha: 0.05),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 20,
                isMobile ? 11 : 15,
                isMobile ? 16 : 20,
                isMobile ? 8 : 9,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          size: 20,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'KITCHEN SAVINGS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.15,
                          ),
                        ),
                      ),
                      if (!kKitchenSavingsFreeForTesting) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(
                              alpha: 0.09,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withValues(
                                alpha: 0.24,
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                size: 11,
                                color: AppTheme.primaryGreen,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Premium',
                                style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Estimated saved this month',
                    style: TextStyle(
                      color: AppTheme.greyText,
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '\$0',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 5,
                            backgroundColor: AppTheme.darkBackground.withValues(
                              alpha: 0.85,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '20%',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Keep using Kitchen Treasures to save more 🌱',
                    style: TextStyle(
                      color: AppTheme.greyText,
                      fontSize: 11,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Divider(
                    height: 1,
                    color: AppTheme.primaryGreen.withValues(alpha: 0.14),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        if (!kKitchenSavingsFreeForTesting) ...[
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 16,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Expanded(
                          child: Text(
                            kKitchenSavingsFreeForTesting
                                ? 'View savings details'
                                : 'Unlock smart savings tracking',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppTheme.primaryGreen,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
