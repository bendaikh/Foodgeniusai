import 'package:flutter/material.dart';

import '../screens/kitchen_treasures_page.dart';
import '../theme/app_theme.dart';

/// Edge-attached bottom nav with a centered notch and elevated circular button.
class FloatingBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const double barHeight = 64;
  static const double centerButtonSize = 52;

  /// How far the center button rises above the flat top of the bar.
  static const double notchLift = 26;
  static const double bottomCornerRadius = 28;

  /// Extra height above [barHeight] so the protruding Scan button receives taps.
  /// Without this, Flutter clips hit-testing to the nav bar box and only the
  /// lower half of the circle is tappable.
  static const double centerButtonOverhang =
      centerButtonSize / 2 - 4 + 2; // matches Positioned bottom math + pad

  /// Layout height reserved above the system safe inset (flat top of the bar).
  /// Notch / center button overflow upward and are not part of this slot.
  static const double height = barHeight;

  /// Total widget height including the tappable overhang above the bar.
  static const double layoutHeight = barHeight + centerButtonOverhang;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _NavItemData(icon: Icons.home_rounded, label: 'Home'),
      _NavItemData(icon: Icons.restaurant_menu_rounded, label: 'My Recipes'),
      _NavItemData(icon: Icons.bookmark_rounded, label: 'Saved'),
      _NavItemData(icon: Icons.person_rounded, label: 'Profile'),
    ];

    final centerGap = centerButtonSize + 20;
    // Transparent material so Scaffold does not paint an extra strip above the bar.
    // Height includes overhang so the full circular Scan button is hit-testable.
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        height: layoutHeight,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Solid notched bar — overflows upward by [notchLift] only for the
            // painted notch shape (no opaque backdrop in that region).
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: barHeight + notchLift,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _NotchedNavBarPainter(
                    color: AppTheme.cardBackground,
                    cornerRadius: bottomCornerRadius,
                    notchRadius: centerButtonSize / 2 + 10,
                    flatTopY: notchLift,
                  ),
                ),
              ),
            ),

            // Tabs: two left, gap for center button, two right.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: barHeight,
              child: Row(
                children: [
                  Expanded(
                    child: _NavTab(
                      item: items[0],
                      selected: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                  ),
                  Expanded(
                    child: _NavTab(
                      item: items[1],
                      selected: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                  ),
                  SizedBox(width: centerGap),
                  Expanded(
                    child: _NavTab(
                      item: items[2],
                      selected: currentIndex == 2,
                      onTap: () => onTap(2),
                    ),
                  ),
                  Expanded(
                    child: _NavTab(
                      item: items[3],
                      selected: currentIndex == 3,
                      onTap: () => onTap(3),
                    ),
                  ),
                ],
              ),
            ),

            // Elevated circular center button seated in the notch.
            // Last in the Stack so it wins hit-testing over the full circle.
            Positioned(
              bottom: barHeight - (centerButtonSize / 2) + 4,
              child: const _CenterNavButton(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotchedNavBarPainter extends CustomPainter {
  final Color color;
  final double cornerRadius;
  final double notchRadius;
  final double flatTopY;

  _NotchedNavBarPainter({
    required this.color,
    required this.cornerRadius,
    required this.notchRadius,
    required this.flatTopY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final top = flatTopY;
    final r = notchRadius;

    final outerPath =
        Path()
          ..moveTo(0, top)
          ..lineTo(size.width, top)
          ..lineTo(size.width, size.height - cornerRadius)
          ..quadraticBezierTo(
            size.width,
            size.height,
            size.width - cornerRadius,
            size.height,
          )
          ..lineTo(cornerRadius, size.height)
          ..quadraticBezierTo(0, size.height, 0, size.height - cornerRadius)
          ..close();

    // Subtract the existing curved notch from the solid bar so the cutout
    // remains genuinely transparent.
    final notchPath =
        Path()
          ..moveTo(cx - r - 14, top)
          ..cubicTo(
            cx - r - 2,
            top,
            cx - r + 2,
            top + r * 0.15,
            cx - r + 6,
            top + r * 0.55,
          )
          ..arcToPoint(
            Offset(cx + r - 6, top + r * 0.55),
            radius: Radius.circular(r * 0.95),
            clockwise: false,
          )
          ..cubicTo(
            cx + r - 2,
            top + r * 0.15,
            cx + r + 2,
            top,
            cx + r + 14,
            top,
          )
          ..lineTo(cx - r - 14, top)
          ..close();

    final barPath = Path.combine(
      PathOperation.difference,
      outerPath,
      notchPath,
    );

    final fill =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    final clear = Paint()..blendMode = BlendMode.clear;

    // Draw and carve the notch in an isolated layer so the cutout is truly
    // transparent instead of appearing as a painted shape.
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawPath(outerPath, fill);
    canvas.drawPath(notchPath, clear);
    canvas.restore();

    final stroke =
        Paint()
          ..color = AppTheme.primaryGreen.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    canvas.drawPath(barPath, stroke);
  }

  @override
  bool shouldRepaint(covariant _NotchedNavBarPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.notchRadius != notchRadius ||
        oldDelegate.flatTopY != flatTopY;
  }
}

class _CenterNavButton extends StatefulWidget {
  const _CenterNavButton();

  @override
  State<_CenterNavButton> createState() => _CenterNavButtonState();
}

class _CenterNavButtonState extends State<_CenterNavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _openScanFridge() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const KitchenTreasuresPage(openScanFridge: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = _pulse.value;
        final scale = 1.0 + (t * 0.04);
        final glow = 0.14 + (t * 0.16);
        final borderAlpha = 0.35 + (t * 0.20);

        return Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.none,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _openScanFridge,
            splashColor: AppTheme.primaryGreen.withValues(alpha: 0.18),
            highlightColor: AppTheme.primaryGreen.withValues(alpha: 0.08),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: FloatingBottomNavBar.centerButtonSize,
                height: FloatingBottomNavBar.centerButtonSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.darkBackground,
                  border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: borderAlpha),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: glow),
                      blurRadius: 14,
                      spreadRadius: 0.5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({required this.icon, required this.label});
}

class _NavTab extends StatefulWidget {
  final _NavItemData item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? AppTheme.primaryGreen : AppTheme.greyText;
    final scale = _pressed ? 0.92 : (widget.selected ? 1.06 : 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        splashColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
        highlightColor: AppTheme.primaryGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow:
                        widget.selected
                            ? [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 10,
                                spreadRadius: 0.5,
                              ),
                            ]
                            : null,
                  ),
                  child: Icon(widget.item.icon, color: color, size: 22),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
                    height: 1.1,
                  ),
                  child: Text(
                    widget.item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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
