import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A realistic hardware-grade status pill button with optical jewel LED indicator.
class GlowingBadge extends StatefulWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool isPulsing;
  final VoidCallback? onTap;
  final String? tooltip;

  const GlowingBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.isPulsing = false,
    this.onTap,
    this.tooltip,
  });

  @override
  State<GlowingBadge> createState() => _GlowingBadgeState();
}

class _GlowingBadgeState extends State<GlowingBadge> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = widget.color;

    // Realistic chassis styling
    final backgroundColor = isDark
        ? (_isHovered ? const Color(0xFF1A2744) : const Color(0xFF111C32))
        : (_isHovered ? const Color(0xFFF1F5F9) : Colors.white);

    final borderColor = isDark
        ? (_isHovered ? c.withValues(alpha: 0.6) : const Color(0xFF223555))
        : (_isHovered ? c.withValues(alpha: 0.6) : const Color(0xFFCBD5E1));

    final textColor = isDark
        ? ForgeColors.textPrimary
        : ForgeLightColors.textPrimary;

    Widget badgeContent = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
        boxShadow: [
          // Ambient soft drop shadow
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0x120F172A),
            blurRadius: 5,
            offset: const Offset(0, 1.5),
          ),
          // Subtle colored aura when hovered or active
          if (widget.isPulsing || _isHovered)
            BoxShadow(
              color: c.withValues(alpha: isDark ? 0.25 : 0.15),
              blurRadius: 8,
              spreadRadius: 0.5,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _RealisticLedDot(
            color: c,
            isPulsing: widget.isPulsing,
          ),
          const SizedBox(width: 8),
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              size: 13,
              color: c,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            widget.label,
            style: TextStyle(
              color: textColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );

    if (widget.onTap != null) {
      badgeContent = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: badgeContent,
        ),
      );
    } else {
      badgeContent = MouseRegion(
        cursor: SystemMouseCursors.basic,
        child: badgeContent,
      );
    }

    if (widget.tooltip != null) {
      badgeContent = Tooltip(
        message: widget.tooltip!,
        child: badgeContent,
      );
    }

    return badgeContent;
  }
}

/// A realistic hardware LED indicator with outer diffused aura, dark bezel,
/// and concentric jewel core with specular highlight.
class _RealisticLedDot extends StatefulWidget {
  final Color color;
  final bool isPulsing;

  const _RealisticLedDot({
    required this.color,
    this.isPulsing = false,
  });

  @override
  State<_RealisticLedDot> createState() => _RealisticLedDotState();
}

class _RealisticLedDotState extends State<_RealisticLedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _glowAnimation = Tween<double>(begin: 0.35, end: 0.9).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.isPulsing) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _RealisticLedDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _pulseCtrl.repeat(reverse: true);
      } else {
        _pulseCtrl.stop();
        _pulseCtrl.value = 0.5;
      }
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        final glow = widget.isPulsing ? _glowAnimation.value : 0.6;

        return SizedBox(
          width: 13,
          height: 13,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer optical diffused aura
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.withValues(alpha: glow * 0.35),
                ),
              ),
              // Concentric LED bezel ring
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F172A),
                  border: Border.all(
                    color: c.withValues(alpha: 0.65),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.withValues(alpha: glow * 0.75),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.35, -0.35),
                        radius: 0.75,
                        colors: [
                          Colors.white,
                          c,
                          Color.lerp(c, Colors.black, 0.4)!,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
