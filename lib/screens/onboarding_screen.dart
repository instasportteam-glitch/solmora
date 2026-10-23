import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/god_background.dart';
import 'setup_screen.dart';

/// Choose a path: the screen is split into Olympus (top) and the Underworld
/// (bottom). The chosen half grows on a spring; the user can change their mind
/// mid-animation and the motion continues from where it is.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _split = AnimationController.unbounded(vsync: this, value: 0.5);
  GodSide? _sel;

  void _choose(GodSide s) {
    HapticFeedback.mediumImpact();
    setState(() => _sel = s);
    final target = s == GodSide.zeus ? 0.64 : 0.36;
    if (MediaQuery.of(context).disableAnimations) {
      _split.value = target;
    } else {
      _split.animateWith(SpringSimulation(appleSpring(response: 0.45), _split.value, target, _split.velocity));
    }
  }

  void _continue() {
    final s = _sel;
    if (s == null) return;
    HapticFeedback.heavyImpact();
    Navigator.of(context).push(CupertinoPageRoute(builder: (_) => SetupScreen(side: s)));
  }

  @override
  void dispose() {
    _split.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final reduce = MediaQuery.of(context).disableAnimations;
    final tablet = isTablet(context);
    return CupertinoPageScaffold(
      backgroundColor: Olymp.bg,
      child: LayoutBuilder(
        builder: (context, box) {
          final h = box.maxHeight;
          return AnimatedBuilder(
            animation: _split,
            builder: (context, _) {
              final topH = h * _split.value;
              return Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: topH,
                    child: _SideHalf(
                      side: GodSide.zeus,
                      selected: _sel == GodSide.zeus,
                      dimmed: _sel == GodSide.hades,
                      topInset: pad.top + (tablet ? 130 : 92),
                      bottomInset: 8,
                      onTap: () => _choose(GodSide.zeus),
                    ),
                  ),
                  Positioned(
                    top: topH,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _SideHalf(
                      side: GodSide.hades,
                      selected: _sel == GodSide.hades,
                      dimmed: _sel == GodSide.zeus,
                      topInset: 8,
                      bottomInset: pad.bottom + (_sel != null ? (tablet ? 110 : 96) : 24),
                      onTap: () => _choose(GodSide.hades),
                    ),
                  ),
                  Positioned(
                    top: topH - 1,
                    left: 0,
                    right: 0,
                    height: 2,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Color(0x005CC8FF),
                          Color(0xFF5CC8FF),
                          Color(0xFFF1C25B),
                          Color(0xFFFF8A2A),
                          Color(0x00FF8A2A),
                        ]),
                      ),
                    ),
                  ),
                  Positioned(
                    top: pad.top + 18,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (r) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFFB347), Color(0xFFE0531F)],
                            ).createShader(r),
                            child: Text('SOLMORA', style: OT.display(tablet ? 60 : 40, color: const Color(0xFFFFFFFF))),
                          ),
                          const SizedBox(height: 4),
                          const Text('CHOOSE YOUR GOD', style: OT.caption),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: hPad(context, 20) + (tablet ? sideInset(MediaQuery.sizeOf(context).width - 40, max: 480) : 0),
                    right: hPad(context, 20) + (tablet ? sideInset(MediaQuery.sizeOf(context).width - 40, max: 480) : 0),
                    bottom: pad.bottom + (tablet ? 32 : 20),
                    child: AnimatedSlide(
                      duration: reduce ? Duration.zero : const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      offset: _sel == null ? const Offset(0, 0.6) : Offset.zero,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        opacity: _sel == null ? 0 : 1,
                        child: IgnorePointer(
                          ignoring: _sel == null,
                          child: CtaButton(
                            label: _sel == GodSide.hades ? 'Descend with Mora' : 'Rise with Sol',
                            onTap: _continue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SideHalf extends StatelessWidget {
  const _SideHalf({
    required this.side,
    required this.selected,
    required this.dimmed,
    required this.topInset,
    required this.bottomInset,
    required this.onTap,
  });

  final GodSide side;
  final bool selected;
  final bool dimmed;
  final double topInset;
  final double bottomInset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = GodPalette.of(side);
    final zeus = side == GodSide.zeus;
    return Semantics(
      button: true,
      selected: selected,
      label: '${pal.god}, ${pal.title}, ${pal.path}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              GodBackground(side: side, intensity: 1),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 260),
                opacity: dimmed ? 0.55 : 0,
                child: const ColoredBox(color: Color(0xFF000000)),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, topInset, 24, bottomInset),
                // iPhone: shrink to fit. iPad: grow up to 1.6× while it still fits.
                child: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: isTablet(context) ? 544 : double.infinity), child: FittedBox(
                  fit: isTablet(context) ? BoxFit.contain : BoxFit.scaleDown,
                  child: SizedBox(
                    width: 340,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [pal.glow.withOpacity(0.5), pal.deep.withOpacity(0.2)]),
                            border: Border.all(
                                color: selected ? Olymp.gold : pal.primary.withOpacity(0.5), width: selected ? 2.5 : 1),
                            boxShadow: [
                              BoxShadow(color: pal.primary.withOpacity(selected ? 0.7 : 0.35), blurRadius: selected ? 36 : 20)
                            ],
                          ),
                          child: Center(child: Text(pal.emoji, style: const TextStyle(fontSize: 40))),
                        ),
                        const SizedBox(height: 14),
                        Text(pal.god.toUpperCase(), style: OT.display(40)),
                        const SizedBox(height: 6),
                        Text('${pal.title} · ${pal.path}'.toUpperCase(),
                            style: OT.caption.copyWith(color: pal.glow, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        Text(
                          zeus
                              ? 'Jump rope, planks, running and bodyweight. The bright path for those just starting.'
                              : 'Heavy squats, deadlifts, burpees until you drop. Weights scale to your real strength.',
                          style: OT.body.copyWith(color: Olymp.textPrimary.withOpacity(0.85)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: (zeus ? ['🪢 Jump rope', '🧱 Plank', '🏃 Cardio'] : ['🏋️ Barbell', '⛓️ Deadlift', '💀 Burpees'])
                              .map((t) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: pal.primary.withOpacity(0.16),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: pal.primary.withOpacity(0.35)),
                                    ),
                                    child: Text(t, style: OT.subhead.copyWith(color: Olymp.textPrimary)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
