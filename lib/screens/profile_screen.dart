import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../data/exercises.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'setup_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _rename(BuildContext context) async {
    final app = AppScope.read(context);
    final c = TextEditingController(text: app.name);
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Your name'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(controller: c, autofocus: true, maxLength: 24, textCapitalization: TextCapitalization.words),
        ),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) app.rename(c.text);
  }

  Future<void> _pickRest(BuildContext context) async {
    final app = AppScope.read(context);
    const options = [30, 45, 60, 90, 120, 180];
    final v = await showCupertinoModalPopup<int>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Rest between sets'),
        actions: [
          for (final o in options)
            CupertinoActionSheetAction(
              isDefaultAction: o == app.restSeconds,
              onPressed: () => Navigator.pop(ctx, o),
              child: Text(fmtSec(o)),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      ),
    );
    if (v != null) app.setRest(v);
  }

  Future<void> _switchGod(BuildContext context) async {
    final app = AppScope.read(context);
    final ok = await confirmDestructive(
      context,
      title: 'Switch god?',
      message: 'Each god keeps their own ladder progress. Your history, exercises and measurements stay.',
      action: 'Switch',
    );
    if (ok) app.leaveSide();
  }

  Future<void> _reset(BuildContext context) async {
    final app = AppScope.read(context);
    final ok = await confirmDestructive(
      context,
      title: 'Reset everything?',
      message: 'This deletes all workouts, custom exercises, measurements and photos from this iPhone. It can’t be undone.',
      action: 'Reset',
    );
    if (ok) {
      HapticFeedback.heavyImpact();
      app.resetAll();
    }
  }

  void _privacy(BuildContext context) => showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Your data'),
          content: const Text(
            'Solmora has no account and no servers. Workouts, measurements and photos are stored only on this iPhone and are never sent anywhere. Deleting the app deletes them.',
          ),
          actions: [CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pal = app.palette;
    final lvl = app.level;
    final lo = app.xpForLevel(lvl), hi = app.xpForLevel(lvl + 1);

    final achievements = <({String title, String icon, bool earned})>[
      (title: 'First blood', icon: '🩸', earned: app.logs.isNotEmpty),
      (title: 'Week of fire', icon: '🔥', earned: app.bestStreak >= 7),
      (title: 'Hero', icon: '🛡️', earned: app.ladder.values.any((v) => v >= 10)),
      (title: 'Demigod', icon: '⚔️', earned: app.ladder.values.any((v) => v >= 20)),
      (title: 'God', icon: '👑', earned: app.ladder.values.any((v) => v >= 30)),
      (title: 'Creator', icon: '📜', earned: app.customs.isNotEmpty),
      (title: 'Sculptor', icon: '📏', earned: app.measurements.length >= 10),
      (title: 'Centurion', icon: '🏛️', earned: app.logs.length >= 100),
    ];

    return GodScreen(
      title: 'Profile',
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 4),
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [pal.glow.withOpacity(0.45), pal.deep.withOpacity(0.4)]),
                  border: Border.all(color: Olymp.gold, width: 2.5),
                  boxShadow: [BoxShadow(color: pal.primary.withOpacity(0.6), blurRadius: 44)],
                ),
                child: Center(child: Text(app.isGod ? '👑' : pal.emoji, style: const TextStyle(fontSize: 48))),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(app.name, style: OT.display(30), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Semantics(
                    label: 'Edit name',
                    child: CircleIconButton(icon: CupertinoIcons.pencil, size: 34, onTap: () => _rename(context)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('${app.tier} · ${pal.title}'.toUpperCase(), style: OT.caption.copyWith(color: pal.glow, letterSpacing: 1.2)),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text('Level $lvl', style: OT.display(22))),
                    Text('${fmtInt(app.xp)} / ${fmtInt(hi)} XP', style: OT.subhead),
                  ]),
                  const SizedBox(height: 8),
                  LinearBar(value: hi == lo ? 1 : (app.xp - lo) / (hi - lo), color: pal.primary),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: Text('${pal.god} ladder', style: OT.headline.copyWith(fontSize: 15))),
                    Text('${app.ladderStep} of 30 steps', style: OT.subhead),
                  ]),
                  const SizedBox(height: 8),
                  LinearBar(value: app.ladderStep / 30, color: pal.primary),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Expanded(child: _Stat(value: '${app.daysWithUs}', label: 'DAYS IN')),
                const SizedBox(width: 10),
                Expanded(child: _Stat(value: fmtInt(app.logs.length), label: 'WORKOUTS')),
                const SizedBox(width: 10),
                Expanded(child: _Stat(value: '${app.bestStreak}', label: 'BEST STREAK')),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SectionHeader('Awards')),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.count(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 8,
            childAspectRatio: 0.78,
            children: [
              for (final a in achievements)
                Semantics(
                  label: '${a.title}, ${a.earned ? 'earned' : 'locked'}',
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: a.earned ? Olymp.goldGradient : null,
                          color: a.earned ? null : const Color(0x0FFFFFFF),
                          border: a.earned ? null : Border.all(color: const Color(0x40FFFFFF)),
                          boxShadow: a.earned ? [BoxShadow(color: Olymp.gold.withOpacity(0.35), blurRadius: 16)] : null,
                        ),
                        child: Center(
                          child: Opacity(opacity: a.earned ? 1 : 0.35, child: Text(a.icon, style: const TextStyle(fontSize: 24))),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(a.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: OT.subhead.copyWith(fontSize: 11, color: a.earned ? Olymp.textPrimary : Olymp.textTertiary)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SectionHeader('Settings')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _Row(
                    label: pal.side == GodSide.hades ? 'Strength calibration' : 'Level & calibration',
                    value: pal.side == GodSide.hades
                        ? (app.squat1rmKg != null ? 'Squat ${fmtWeight(app.squat1rmKg!, app.units)}' : 'Estimated')
                        : zeusLevels[app.zeusLevel.clamp(0, 2).toInt()],
                    onTap: () => Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => SetupScreen(side: pal.side, editing: true),
                    )),
                  ),
                  const _Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text('Units', style: OT.headline.copyWith(fontWeight: FontWeight.w500, fontSize: 16))),
                        SizedBox(
                          width: 150,
                          child: CupertinoSlidingSegmentedControl<Units>(
                            groupValue: app.units,
                            thumbColor: pal.primary.withOpacity(0.55),
                            backgroundColor: Olymp.surface,
                            children: const {
                              Units.metric: Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('kg · cm')),
                              Units.imperial: Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('lb · in')),
                            },
                            onValueChanged: (v) => app.setUnits(v ?? app.units),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _Divider(),
                  _Row(label: 'Rest between sets', value: fmtSec(app.restSeconds), onTap: () => _pickRest(context)),
                  const _Divider(),
                  _Row(label: 'Switch god', value: 'Sol / Mora', onTap: () => _switchGod(context)),
                  const _Divider(),
                  _Row(label: 'Your data & privacy', value: 'On device', onTap: () => _privacy(context)),
                  const _Divider(),
                  _Row(label: 'Reset progress', color: Olymp.danger, onTap: () => _reset(context)),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 28, 0),
            child: Text(
              'Solmora is a training log, not medical advice. Talk to a doctor before starting a new program. Weights are guidance — lower the load if form breaks.',
              style: OT.caption,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) => GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(
          children: [
            Text(value, style: OT.display(22)),
            const SizedBox(height: 2),
            Text(label, style: OT.caption.copyWith(fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.label, this.value, this.color, required this.onTap});
  final String label;
  final String? value;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        scale: 0.99,
        child: SizedBox(
          height: 50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: OT.headline.copyWith(fontWeight: FontWeight.w500, fontSize: 16, color: color ?? Olymp.textPrimary)),
                ),
                if (value != null) Text(value!, style: OT.subhead),
                if (color == null) ...[
                  const SizedBox(width: 6),
                  const Icon(CupertinoIcons.chevron_right, size: 16, color: Olymp.textTertiary),
                ],
              ],
            ),
          ),
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Container(height: 0.5, margin: const EdgeInsets.only(left: 16), color: Olymp.stroke);
}
