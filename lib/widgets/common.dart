import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'god_background.dart';

/// Widest a column of content gets on iPad; backgrounds still fill the screen.
const double kContentMaxWidth = 720;

/// iPad (or any large window): the shorter side is at least 600 points.
bool isTablet(BuildContext context) => MediaQuery.sizeOf(context).shortestSide >= 600;

/// Extra horizontal inset on each side that centers a column of at most
/// [max] points within [width]. Zero on iPhone.
double sideInset(double width, {double max = kContentMaxWidth}) => width > max ? (width - max) / 2 : 0;

/// [base] horizontal padding plus the centering inset for the current screen width.
double hPad(BuildContext context, double base) => base + sideInset(MediaQuery.sizeOf(context).width);

/// Press feedback starts on pointer-down and runs on a spring from the current
/// value, so it can be interrupted and reversed at any moment.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: 1.0);

  void _to(double target) {
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = target;
      return;
    }
    _c.animateWith(SpringSimulation(appleSpring(response: 0.3), _c.value, target, _c.velocity));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return Listener(
      onPointerDown: enabled ? (_) => _to(widget.scale) : null,
      onPointerUp: enabled ? (_) => _to(1.0) : null,
      onPointerCancel: enabled ? (_) => _to(1.0) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                widget.onLongPress!();
              },
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) => Transform.scale(scale: _c.value, child: child),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Translucent "glass" card. Blur is enabled only where a moving background
/// actually sits underneath.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.tint,
    this.blur = false,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final bool blur;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (tint ?? const Color(0xFFFFFFFF)).withOpacity(0.10),
            (tint ?? const Color(0xFFFFFFFF)).withOpacity(0.04),
          ],
        ),
        border: Border.all(color: borderColor ?? Olymp.stroke, width: 0.8),
      ),
      child: child,
    );
    if (!blur) return box;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: box),
    );
  }
}

/// Primary button — fiery orange gradient.
class CtaButton extends StatelessWidget {
  const CtaButton({super.key, required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Pressable(
      onTap: onTap,
      haptic: false,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.4,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: Olymp.cta,
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [BoxShadow(color: const Color(0xFFF2702A).withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 8))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: const Color(0xFFFFFFFF), size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onTap, this.icon, this.color});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Olymp.textPrimary;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Olymp.surfaceStrong,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Olymp.stroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, color: c, size: 20), const SizedBox(width: 8)],
            Text(label, style: OT.headline.copyWith(color: c)),
          ],
        ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({super.key, required this.icon, required this.onTap, this.size = 40, this.color});

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        scale: 0.9,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Olymp.surfaceStrong,
            border: Border.all(color: Olymp.stroke),
          ),
          child: Icon(icon, size: size * 0.48, color: color ?? Olymp.textPrimary),
        ),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
        child: Row(
          children: [
            Expanded(child: Text(text.toUpperCase(), style: OT.caption)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// Progress ring; eases to the new value, or jumps with Reduce Motion on.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.color,
    this.size = 88,
    this.stroke = 9,
    this.child,
  });

  final double value;
  final Color color;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0.0, 1.0).toDouble()),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v, color, stroke),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.color, this.stroke);
  final double v;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = const Color(0x1FFFFFFF),
    );
    if (v <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * v,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: [color.withOpacity(0.6), color, Olymp.gold],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.v != v || old.color != color;
}

class LinearBar extends StatelessWidget {
  const LinearBar({super.key, required this.value, required this.color, this.height = 8});
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: const Color(0x1FFFFFFF),
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0.0, 1.0).toDouble()),
          duration: reduce ? Duration.zero : const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => FractionallySizedBox(
            widthFactor: v,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, Olymp.gold]),
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Exercise thumbnail: the photo if there is one, else the emoji on the god's gradient.
class ExerciseThumb extends StatelessWidget {
  const ExerciseThumb({super.key, required this.exercise, this.size = 56});
  final Exercise exercise;
  final double size;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pal = GodPalette.of(exercise.side ?? app.side ?? GodSide.zeus);
    final photo = exercise.photo;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: SizedBox(
        width: size,
        height: size,
        child: photo != null && app.photoFile(photo).existsSync()
            ? Image.file(app.photoFile(photo), fit: BoxFit.cover, cacheWidth: (size * 3).round())
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [pal.primary.withOpacity(0.55), pal.deep.withOpacity(0.9)],
                  ),
                ),
                child: Center(child: Text(exercise.emoji, style: TextStyle(fontSize: size * 0.48))),
              ),
      ),
    );
  }
}

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({super.key, required this.exercise, required this.onTap, this.done = false});

  final Exercise exercise;
  final VoidCallback onTap;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pal = app.palette;
    final load = app.loadShort(exercise);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Pressable(
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          borderColor: done ? Olymp.gold.withOpacity(0.45) : null,
          child: Row(
            children: [
              ExerciseThumb(exercise: exercise),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: OT.headline, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      [app.targetLabel(exercise), if (load != null) load].join(' · '),
                      style: OT.subhead.copyWith(color: pal.primary.withOpacity(0.9)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              done
                  ? Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: Olymp.goldGradient),
                      child: const Icon(CupertinoIcons.checkmark_alt, size: 18, color: Color(0xFF2A1A05)),
                    )
                  : const Icon(CupertinoIcons.chevron_right, size: 18, color: Olymp.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab scaffold: the god's living background, a legibility scrim, and a
/// translucent large-title nav bar with content scrolling underneath.
class GodScreen extends StatelessWidget {
  const GodScreen({super.key, required this.title, required this.slivers, this.trailing, this.intensity = 0.55});

  final String title;
  final List<Widget> slivers;
  final Widget? trailing;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final inset = sideInset(MediaQuery.sizeOf(context).width);
    return CupertinoPageScaffold(
      backgroundColor: Olymp.bg,
      child: Stack(
        children: [
          Positioned.fill(child: GodBackground(side: app.side ?? GodSide.zeus, intensity: intensity)),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x6609080F), Color(0xD909080F)],
                ),
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: Text(title),
                trailing: trailing,
                backgroundColor: Olymp.bar,
                border: null,
                stretch: true,
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: inset),
                sliver: SliverMainAxisGroup(slivers: slivers),
              ),
              SliverToBoxAdapter(child: SizedBox(height: bottom + 28)),
            ],
          ),
        ],
      ),
    );
  }
}

class NavPlusButton extends StatelessWidget {
  const NavPlusButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = AppScope.of(context).palette;
    return Pressable(
      onTap: onTap,
      scale: 0.88,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: Olymp.cta, boxShadow: [
          BoxShadow(color: pal.primary.withOpacity(0.3), blurRadius: 12),
        ]),
        child: const Icon(CupertinoIcons.add, color: Color(0xFFFFFFFF), size: 20),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.emoji, required this.title, required this.text, this.action});
  final String emoji;
  final String title;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(title, style: OT.title, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(text, style: OT.body, textAlign: TextAlign.center),
              if (action != null) ...[const SizedBox(height: 18), action!],
            ],
          ),
        ),
      );
}

/// Photo source picker: camera or library, as a native action sheet.
Future<String?> pickPhotoSource(BuildContext context) => showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Add a photo'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 'camera'),
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 'gallery'),
            child: const Text('Choose from Library'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );

Future<bool> confirmDestructive(BuildContext context,
        {required String title, required String message, required String action}) async =>
    (await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
        ],
      ),
    )) ??
    false;
