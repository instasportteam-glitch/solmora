import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/god_background.dart';
import 'session_screen.dart';

/// 30 steps climbing from the bottom (step 1) to the crown at the top.
class LadderScreen extends StatefulWidget {
  const LadderScreen({super.key});

  @override
  State<LadderScreen> createState() => _LadderScreenState();
}

class _LadderScreenState extends State<LadderScreen> with SingleTickerProviderStateMixin {
  static const _rowH = 104.0;
  final _scroll = ScrollController();
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent(animated: false));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
      _pulse.value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _scrollToCurrent({bool animated = true}) {
    if (!_scroll.hasClients) return;
    final step = AppScope.read(context).ladderStep.clamp(0, 30).toInt();
    final viewport = _scroll.position.viewportDimension;
    final target =
        (step * _rowH + _rowH / 2 - viewport / 2 + 120).clamp(0.0, _scroll.position.maxScrollExtent).toDouble();
    if (animated && !MediaQuery.of(context).disableAnimations) {
      _scroll.animateTo(target, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    } else {
      _scroll.jumpTo(target);
    }
  }

  Future<void> _open(int i) async {
    final app = AppScope.read(context);
    final step = app.ladderStep;
    final e = app.ladderList[i];
    if (i > step) {
      HapticFeedback.lightImpact();
      return;
    }
    if (i < step) {
      // Already climbed: train it again without changing the ladder.
      await openSession(context, e);
      return;
    }
    await openSession(context, e, ladderStep: i);
    if (!mounted) return;
    if (app.ladderStep > step) {
      _scrollToCurrent();
      if (app.isGod) _celebrate();
    }
  }

  void _celebrate() {
    final pal = AppScope.read(context).palette;
    HapticFeedback.heavyImpact();
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('👑 You became a God'),
        content: Text('All 30 trials complete. You now rule ${pal.realm}.'),
        actions: [CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.pop(ctx), child: const Text('Glory'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pal = app.palette;
    final list = app.ladderList;
    final step = app.ladderStep;
    final pad = MediaQuery.paddingOf(context);
    const headerH = 104.0;

    return CupertinoPageScaffold(
      backgroundColor: Olymp.bg,
      child: Stack(
        children: [
          Positioned.fill(child: GodBackground(side: pal.side, intensity: 0.6)),
          const Positioned.fill(child: ColoredBox(color: Color(0x7309080F))),
          LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth > kContentMaxWidth ? kContentMaxWidth : box.maxWidth;
              double xOf(int i) => w / 2 + math.sin(i * 0.9) * w * 0.24;
              return ListView.builder(
                controller: _scroll,
                reverse: true,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.only(top: pad.top + headerH + 24, bottom: pad.bottom + 24),
                itemCount: 31,
                itemBuilder: (context, i) {
                  if (i == 30) return _Crown(achieved: app.isGod, realm: pal.realm, height: _rowH + 40);
                  final x = xOf(i);
                  final nextX = i < 29 ? xOf(i + 1) : w / 2;
                  final state = i < step ? _NodeState.done : (i == step ? _NodeState.current : _NodeState.locked);
                  return Center(
                    child: SizedBox(
                    width: w,
                    height: _rowH,
                    child: CustomPaint(
                      painter: _LinkPainter(
                        from: Offset(x, _rowH / 2),
                        to: Offset(nextX, i < 29 ? -_rowH / 2 : -_rowH / 2 - 10),
                        done: i + 1 <= step,
                        color: pal.primary,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: x - 36,
                            top: _rowH / 2 - 36,
                            child: _Node(
                              index: i,
                              state: state,
                              pal: pal,
                              pulse: _pulse,
                              onTap: () => _open(i),
                            ),
                          ),
                          Positioned(
                            top: _rowH / 2 - 32,
                            left: x < w / 2 ? x + 46 : 16,
                            right: x < w / 2 ? 16 : w - x + 46,
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: state == _NodeState.locked ? 0.6 : 1,
                                child: _Label(
                                  index: i,
                                  exercise: list[i],
                                  alignRight: x >= w / 2,
                                  highlight: state == _NodeState.current ? pal.primary : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  );
                },
              );
            },
          ),
          // Header: translucent material, content scrolls under it.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: Olymp.bar,
                  padding: EdgeInsets.fromLTRB(hPad(context, 20), pad.top + 10, hPad(context, 20), 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ladder', style: OT.display(34)),
                            const SizedBox(height: 6),
                            Text('RANK: ${app.tier.toUpperCase()} · PATH OF ${pal.god.toUpperCase()}',
                                style: OT.caption.copyWith(color: pal.glow)),
                            const SizedBox(height: 10),
                            LinearBar(value: step / 30, color: pal.primary),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Semantics(
                        label: '$step of 30 steps',
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(text: '$step', style: OT.display(30)),
                            TextSpan(text: '/30', style: OT.display(16, color: Olymp.textSecondary)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _NodeState { done, current, locked }

class _Node extends StatelessWidget {
  const _Node({required this.index, required this.state, required this.pal, required this.pulse, required this.onTap});
  final int index;
  final _NodeState state;
  final GodPalette pal;
  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final milestone = (index + 1) % 10 == 0;
    final size = state == _NodeState.current ? 72.0 : (milestone ? 66.0 : 60.0);
    final label = switch (state) {
      _NodeState.done => 'Step ${index + 1}, completed. Train again',
      _NodeState.current => 'Step ${index + 1}, current trial. Start',
      _NodeState.locked => 'Step ${index + 1}, locked',
    };
    Widget circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: switch (state) {
          _NodeState.done => Olymp.goldGradient,
          _NodeState.current => LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [pal.glow, pal.primary, pal.deep]),
          _NodeState.locked => null,
        },
        color: state == _NodeState.locked ? const Color(0xE6140C0E) : null,
        border: Border.all(
          color: state == _NodeState.current
              ? Olymp.gold
              : (state == _NodeState.locked ? const Color(0x2EFFFFFF) : const Color(0x00000000)),
          width: state == _NodeState.current ? 2 : 1,
        ),
      ),
      child: Center(
        child: switch (state) {
          _NodeState.done => const Icon(CupertinoIcons.checkmark_alt, color: Color(0xFF2A1A05), size: 28),
          _NodeState.current => Text('${index + 1}', style: OT.display(26, color: const Color(0xFFFFFFFF))),
          _NodeState.locked => Icon(milestone ? CupertinoIcons.star : CupertinoIcons.lock_fill,
              color: Olymp.textTertiary, size: 22),
        },
      ),
    );
    if (state == _NodeState.current) {
      circle = AnimatedBuilder(
        animation: pulse,
        builder: (_, child) => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: pal.primary.withOpacity(0.35 + 0.35 * pulse.value), blurRadius: 18 + 18 * pulse.value)],
          ),
          child: child,
        ),
        child: circle,
      );
    }
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: 72,
        height: 72,
        child: Center(child: Pressable(onTap: onTap, scale: 0.92, child: circle)),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.index, required this.exercise, required this.alignRight, this.highlight});
  final int index;
  final Exercise exercise;
  final bool alignRight;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final load = app.loadShort(exercise);
    final align = alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final ta = alignRight ? TextAlign.right : TextAlign.left;
    return Column(
      crossAxisAlignment: align,
      children: [
        Text('STEP ${index + 1}', style: OT.caption, textAlign: ta),
        const SizedBox(height: 2),
        Text(exercise.name, style: OT.headline.copyWith(fontSize: 15), textAlign: ta, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(
          [app.targetLabel(exercise), if (load != null) load].join(' · '),
          style: OT.subhead.copyWith(fontSize: 13, color: highlight ?? Olymp.textSecondary),
          textAlign: ta,
          maxLines: 2,
        ),
      ],
    );
  }
}

class _LinkPainter extends CustomPainter {
  _LinkPainter({required this.from, required this.to, required this.done, required this.color});
  final Offset from, to;
  final bool done;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (done) {
      canvas.drawLine(
        from,
        to,
        Paint()
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(colors: [Olymp.gold, Olymp.goldDeep]).createShader(Rect.fromPoints(from, to)),
      );
      return;
    }
    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x38FFFFFF);
    final d = to - from;
    final len = d.distance;
    if (len == 0) return;
    final dir = d / len;
    for (double t = 0; t < len; t += 14) {
      canvas.drawLine(from + dir * t, from + dir * math.min(t + 6, len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinkPainter old) =>
      old.from != from || old.to != to || old.done != done || old.color != color;
}

class _Crown extends StatelessWidget {
  const _Crown({required this.achieved, required this.realm, required this.height});
  final bool achieved;
  final String realm;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: achieved ? Olymp.goldGradient : null,
                color: achieved ? null : const Color(0x0FFFFFFF),
                border: Border.all(color: Olymp.gold.withOpacity(achieved ? 1 : 0.5), width: 1.5),
                boxShadow: achieved ? [BoxShadow(color: Olymp.gold.withOpacity(0.6), blurRadius: 36)] : null,
              ),
              child: const Center(child: Text('👑', style: TextStyle(fontSize: 40))),
            ),
            const SizedBox(height: 8),
            Text('God of $realm', style: OT.display(20, color: Olymp.gold)),
          ],
        ),
      );
}
