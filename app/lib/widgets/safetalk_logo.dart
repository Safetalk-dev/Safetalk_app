import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class SafeTalkLogo extends StatefulWidget {
  final double size;
  final bool animate;

  const SafeTalkLogo({
    super.key,
    this.size = 100.0,
    this.animate = true,
  });

  @override
  State<SafeTalkLogo> createState() => _SafeTalkLogoState();
}

class _SafeTalkLogoState extends State<SafeTalkLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutBack,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoWidget = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SafeTalkTheme.cardBg.withValues(alpha: 0.4),
        border: Border.all(
          color: SafeTalkTheme.brandSage.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: widget.size * 0.55,
          height: widget.size * 0.55,
          child: CustomPaint(
            painter: _SLogoPainter(
              color1: SafeTalkTheme.brandTerracotta,
              color2: SafeTalkTheme.brandSage,
            ),
          ),
        ),
      ),
    );

    if (!widget.animate) {
      return logoWidget;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: SafeTalkTheme.brandSage.withValues(alpha: _glowAnimation.value * 0.15),
                blurRadius: widget.size * 0.3,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: SafeTalkTheme.brandTerracotta.withValues(alpha: _glowAnimation.value * 0.08),
                blurRadius: widget.size * 0.5,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: logoWidget,
    );
  }
}

class _SLogoPainter extends CustomPainter {
  final Color color1;
  final Color color2;

  _SLogoPainter({required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Elegant gradient matching the branding
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.18
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [color1, color2],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    final Path path = Path();

    // Mathematically construct a beautiful flowing, organic 'S' path
    // Starts from top right, loops left, sweeps through center, loops right to bottom left
    path.moveTo(width * 0.76, height * 0.20);
    
    // Top Curve of 'S'
    path.cubicTo(
      width * 0.38, height * 0.05,  // Control Point 1
      width * 0.18, height * 0.32,  // Control Point 2
      width * 0.44, height * 0.48,  // End Point
    );

    // Bottom Curve of 'S'
    path.cubicTo(
      width * 0.78, height * 0.65,  // Control Point 1
      width * 0.62, height * 0.95,  // Control Point 2
      width * 0.24, height * 0.80,  // End Point
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
