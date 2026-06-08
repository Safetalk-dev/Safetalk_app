import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class BreathingPulse extends StatefulWidget {
  final double size;
  final String? subtitle;
  final bool showText;

  const BreathingPulse({
    super.key,
    this.size = 180.0,
    this.subtitle,
    this.showText = true,
  });

  @override
  State<BreathingPulse> createState() => _BreathingPulseState();
}

class _BreathingPulseState extends State<BreathingPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Value range between 0.85 and 1.2
        final scale = 0.85 + (_pulseAnimation.value * 0.35);
        final opacity = 0.1 + (_pulseAnimation.value * 0.25);

        // Breath state text helper
        String breathText = "Breathe in...";
        if (_controller.value > 0.6) {
          breathText = "Hold...";
        } else if (_controller.value < 0.4) {
          breathText = "Breathe out...";
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: widget.size * 1.4,
              width: widget.size * 1.4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow Ring 2
                  Transform.scale(
                    scale: scale * 1.3,
                    child: Container(
                      height: widget.size,
                      width: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SafeTalkTheme.brandSage.withValues(alpha: opacity * 0.4),
                      ),
                    ),
                  ),
                  // Outer Glow Ring 1
                  Transform.scale(
                    scale: scale * 1.15,
                    child: Container(
                      height: widget.size,
                      width: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SafeTalkTheme.brandTerracotta.withValues(alpha: opacity * 0.6),
                      ),
                    ),
                  ),
                  // Central Pulsing Orb with organic texture
                  Transform.scale(
                    scale: scale,
                    child: Transform.rotate(
                      angle: _rotateAnimation.value,
                      child: Container(
                        height: widget.size,
                        width: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              SafeTalkTheme.brandSage,
                              SafeTalkTheme.brandSageLight,
                              SafeTalkTheme.brandTerracotta,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: SafeTalkTheme.glowShadow(
                            SafeTalkTheme.brandSage,
                            opacity: 0.3,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            height: widget.size * 0.88,
                            width: widget.size * 0.88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: SafeTalkTheme.bgMidnight.withValues(alpha: 0.85),
                            ),
                            child: Center(
                              child: widget.showText
                                  ? Text(
                                      breathText,
                                      style: SafeTalkTheme.bodyStyle(
                                        color: SafeTalkTheme.textPrimary,
                                        bold: true,
                                      ).copyWith(fontSize: 16),
                                    )
                                  : Container(
                                      height: 12,
                                      width: 12,
                                      decoration: BoxDecoration(
                                        color: SafeTalkTheme.brandSageLight.withValues(alpha: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: SafeTalkTheme.bodyStyle(
                  color: SafeTalkTheme.textSecondary,
                ).copyWith(fontSize: 14),
              ),
            ],
          ],
        );
      },
    );
  }
}
