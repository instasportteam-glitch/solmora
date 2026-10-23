import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../models.dart';
import '../theme.dart';

/// Living background: lightning and clouds for Zeus, fire and embers for Hades.
/// One CustomPainter behind a RepaintBoundary; with Reduce Motion it freezes
/// on a static frame.
class GodBackground extends StatefulWidget {
  const GodBackground({super.key, required this.side, this.intensity = 1.0});

  final GodSide side;

  /// 1.0 = full strength (onboarding, workout); ~0.5 = behind content.
  final double intensity;

  @override
  State<GodBackground> createState() => _GodBackgroundState();
}

class _GodBackgroundState extends State<GodBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 10));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      _c.stop();
      _c.value = 0.12;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = GodPalette.of(widget.side);
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: widget.side == GodSide.zeus
            ? _ZeusPainter(_c, pal, widget.intensity)
            : _HadesPainter(_c, pal, widget.intensity),
      ),
    );
  }
}

Paint _radial(Offset c, double r, Color color) => Paint()
  ..shader = RadialGradient(colors: [color, color.withOpacity(0)])
      .createShader(Rect.fromCircle(center: c, radius: r));

class _ZeusPainter extends CustomPainter {
  _ZeusPainter(this.anim, this.pal, this.k) : super(repaint: anim);
  final Animation<double> anim;
  final GodPalette pal;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value * 10.0;
    final r = Offset.zero & size;
    final w = size.width, h = size.height;

    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16367A), Color(0xFF0B1638), Color(0xFF07070F)],
          stops: [0, 0.5, 1],
        ).createShader(r),
    );

    // Cloud glows drift slowly (whole cycles per 10 s, so the loop is seamless).
    final a = 2 * math.pi * t / 10;
    canvas.drawCircle(Offset(w * (0.2 + 0.05 * math.sin(a)), h * 0.18), w * 0.7,
        _radial(Offset(w * (0.2 + 0.05 * math.sin(a)), h * 0.18), w * 0.7, pal.primary.withOpacity(0.32 * k)));
    final c2 = Offset(w * (0.85 + 0.04 * math.cos(a)), h * 0.42);
    canvas.drawCircle(c2, w * 0.55, _radial(c2, w * 0.55, const Color(0xFF8FB8FF).withOpacity(0.18 * k)));
    final c3 = Offset(w * 0.5, h * (0.05 + 0.02 * math.sin(a * 2)));
    canvas.drawCircle(c3, w * 0.45, _radial(c3, w * 0.45, pal.glow.withOpacity(0.14 * k)));

    // Lightning: a short double flicker every 2.5 s.
    const period = 2.5;
    final idx = (t / period).floor();
    final ph = (t % period) / period;
    double flash = 0;
    if (ph < 0.08) {
      flash = 1 - ph / 0.08;
    } else if (ph > 0.11 && ph < 0.17) {
      flash = (1 - (ph - 0.11) / 0.06) * 0.6;
    }
    if (flash > 0) {
      canvas.drawRect(r, Paint()..color = pal.glow.withOpacity(0.05 * flash * k));
      final path = _bolt(math.Random(idx * 97 + 13), size);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = pal.primary.withOpacity(0.45 * flash * k)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFFFFFFFF).withOpacity(0.9 * flash * k),
      );
    }
  }

  Path _bolt(math.Random rnd, Size size) {
    final p = Path();
    var x = size.width * (0.1 + rnd.nextDouble() * 0.8);
    var y = 0.0;
    p.moveTo(x, y);
    final end = size.height * (0.35 + rnd.nextDouble() * 0.25);
    final branches = <Offset>[];
    while (y < end) {
      y += 16 + rnd.nextDouble() * 26;
      x += (rnd.nextDouble() - 0.5) * 48;
      p.lineTo(x, y);
      if (rnd.nextDouble() < 0.18) branches.add(Offset(x, y));
    }
    for (final b in branches) {
      var bx = b.dx, by = b.dy;
      final dir = rnd.nextBool() ? 1 : -1;
      p.moveTo(bx, by);
      for (var i = 0; i < 4 + rnd.nextInt(3); i++) {
        by += 10 + rnd.nextDouble() * 18;
        bx += dir * (6 + rnd.nextDouble() * 18);
        p.lineTo(bx, by);
      }
    }
    return p;
  }

  @override
  bool shouldRepaint(covariant _ZeusPainter old) => old.k != k || old.pal != pal;
}

class _HadesPainter extends CustomPainter {
  _HadesPainter(this.anim, this.pal, this.k) : super(repaint: anim);
  final Animation<double> anim;
  final GodPalette pal;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value * 10.0;
    final r = Offset.zero & size;
    final w = size.width, h = size.height;

    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E0508), Color(0xFF230A07), Color(0xFF3D1306)],
          stops: [0, 0.55, 1],
        ).createShader(r),
    );

    // The fire breathes; frequencies are multiples of 0.1 Hz so the loop is seamless.
    final flicker = 0.85 + 0.09 * math.sin(2 * math.pi * 0.6 * t) + 0.06 * math.sin(2 * math.pi * 1.3 * t);
    final fc = Offset(w * 0.5, h * 1.02);
    canvas.drawCircle(fc, w * 1.05, _radial(fc, w * 1.05, pal.primary.withOpacity(0.42 * flicker * k)));
    final fc2 = Offset(w * 0.15, h * 0.95);
    canvas.drawCircle(fc2, w * 0.5, _radial(fc2, w * 0.5, const Color(0xFFFF3D1F).withOpacity(0.25 * flicker * k)));
    final fc3 = Offset(w * 0.9, h * 0.75);
    canvas.drawCircle(fc3, w * 0.4, _radial(fc3, w * 0.4, pal.glow.withOpacity(0.12 * k)));

    // Embers rise and fade.
    final glowPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final corePaint = Paint();
    for (var i = 0; i < 38; i++) {
      final rnd = math.Random(i * 31 + 7);
      final x0 = rnd.nextDouble() * w;
      final cycles = 1 + rnd.nextInt(3);
      final phase = rnd.nextDouble();
      final p = ((t / 10) * cycles + phase) % 1.0;
      final y = h * (1.05 - p * 1.1);
      final x = x0 + math.sin(2 * math.pi * (p * 2 + phase)) * 18;
      final radius = 1.0 + rnd.nextDouble() * 2.0;
      final alpha = ((1 - p) * k).clamp(0.0, 1.0).toDouble();
      glowPaint.color = pal.primary.withOpacity(0.7 * alpha);
      canvas.drawCircle(Offset(x, y), radius * 3, glowPaint);
      corePaint.color = pal.glow.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), radius, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HadesPainter old) => old.k != k || old.pal != pal;
}
