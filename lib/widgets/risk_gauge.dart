import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phishcatch/models/scan_result.dart';
import 'package:phishcatch/theme/app_theme.dart';

class RiskGauge extends StatefulWidget {
  final int score;
  final ScanVerdict verdict;

  const RiskGauge({
    super.key,
    required this.score,
    required this.verdict,
  });

  @override
  State<RiskGauge> createState() => _RiskGaugeState();
}

class _RiskGaugeState extends State<RiskGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _buildAnimation();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant RiskGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _buildAnimation();
      _controller.forward(from: 0);
    }
  }

  void _buildAnimation() {
    final clampedScore = widget.score.clamp(0, 100);
    final targetSweep = (clampedScore / 100) * math.pi;
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ).drive(Tween<double>(begin: 0, end: targetSweep));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _verdictColor(widget.verdict);

    return SizedBox(
      width: 160,
      height: 100,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _RiskGaugePainter(
              sweepAngle: _animation.value,
              color: color,
              score: widget.score.clamp(0, 100),
              verdictLabel: _verdictLabel(widget.verdict),
            ),
            child: child,
          );
        },
        child: const SizedBox.expand(),
      ),
    );
  }

  Color _verdictColor(ScanVerdict verdict) {
    switch (verdict) {
      case ScanVerdict.safe:
        return AppColors.safe;
      case ScanVerdict.suspicious:
        return AppColors.suspicious;
      case ScanVerdict.dangerous:
        return AppColors.dangerous;
    }
  }

  String _verdictLabel(ScanVerdict verdict) {
    switch (verdict) {
      case ScanVerdict.safe:
        return 'Safe';
      case ScanVerdict.suspicious:
        return 'Suspicious';
      case ScanVerdict.dangerous:
        return 'Dangerous';
    }
  }
}

class _RiskGaugePainter extends CustomPainter {
  final double sweepAngle;
  final Color color;
  final int score;
  final String verdictLabel;

  const _RiskGaugePainter({
    required this.sweepAngle,
    required this.color,
    required this.score,
    required this.verdictLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    const radius = 70.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, backgroundPaint);
    canvas.drawArc(rect, math.pi, sweepAngle, false, foregroundPaint);

    final centerX = size.width / 2;
    final arcCenterY = size.height;
    final targetSweep = (score / 100) * math.pi;
    final progress = targetSweep > 0 ? (sweepAngle / targetSweep).clamp(0.0, 1.0) : 0.0;
    final animatedScore = (score * progress).round();

    final scoreTextPainter = TextPainter(
      text: TextSpan(
        text: '$animatedScore',
        style: TextStyle(
          fontSize: size.width * 0.14,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    scoreTextPainter.paint(
      canvas,
      Offset(
        centerX - scoreTextPainter.width / 2,
        arcCenterY - scoreTextPainter.height - 22,
      ),
    );

    final labelTextPainter = TextPainter(
      text: TextSpan(
        text: verdictLabel,
        style: TextStyle(
          fontSize: size.width * 0.075,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    labelTextPainter.paint(
      canvas,
      Offset(
        centerX - labelTextPainter.width / 2,
        arcCenterY - labelTextPainter.height - 4,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _RiskGaugePainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.color != color ||
        oldDelegate.score != score ||
        oldDelegate.verdictLabel != verdictLabel;
  }
}

