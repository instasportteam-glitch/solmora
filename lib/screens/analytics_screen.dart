import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

enum _Period { week, month, all }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _Period _period = _Period.week;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pal = app.palette;
    final now = DateTime.now();
    final today = dayStart(now);

    final from = switch (_period) {
      _Period.week => DateTime(today.year, today.month, today.day - 6),
      _Period.month => DateTime(today.year, today.month, today.day - 29),
      _Period.all => DateTime(2000),
    };
    final logs = app.logs.where((l) => !l.at.isBefore(from)).toList();
    final prevFrom = switch (_period) {
      _Period.week => DateTime(today.year, today.month, today.day - 13),
      _Period.month => DateTime(today.year, today.month, today.day - 59),
      _Period.all => DateTime(2000),
    };
    final prevCount = _period == _Period.all
        ? null
        : app.logs.where((l) => !l.at.isBefore(prevFrom) && l.at.isBefore(from)).length;

    final count = logs.length;
    final secs = logs.fold<int>(0, (a, l) => a + l.seconds);
    final reps = logs.fold<int>(0, (a, l) => a + l.reps);
    final volumeKg = logs.fold<double>(0, (a, l) => a + (l.kg ?? 0) * l.reps);

    // Bars: days for week/month, weeks for all time.
    final bars = <({String label, double value, bool highlight})>[];
    if (_period == _Period.all) {
      for (var w = 11; w >= 0; w--) {
        final start = DateTime(today.year, today.month, today.day - today.weekday + 1 - w * 7);
        final end = DateTime(start.year, start.month, start.day + 7);
        final m = app.logs.where((l) => !l.at.isBefore(start) && l.at.isBefore(end)).fold<int>(0, (a, l) => a + l.seconds);
        bars.add((label: w == 0 ? 'now' : (w % 3 == 0 ? '-${w}w' : ''), value: m / 60, highlight: w == 0));
      }
    } else {
      final days = _period == _Period.week ? 7 : 30;
      for (var i = days - 1; i >= 0; i--) {
        final d = DateTime(today.year, today.month, today.day - i);
        final k = dayKey(d);
        final m = app.logs.where((l) => dayKey(l.at) == k).fold<int>(0, (a, l) => a + l.seconds);
        final label = days == 7 ? weekdaysShort[d.weekday - 1] : (i % 7 == 0 ? '${d.day}' : '');
        bars.add((label: label, value: m / 60, highlight: i == 0));
      }
    }
    final avg = bars.isEmpty ? 0 : bars.fold<double>(0, (a, b) => a + b.value) / bars.length;

    // Most frequent exercises.
    final byName = <String, ({int times, int reps, int secs})>{};
    for (final l in logs) {
      final p = byName[l.name] ?? (times: 0, reps: 0, secs: 0);
      byName[l.name] = (times: p.times + 1, reps: p.reps + l.reps, secs: p.secs + l.seconds);
    }
    final top = byName.entries.toList()..sort((a, b) => b.value.times.compareTo(a.value.times));
    final topMax = top.isEmpty ? 1 : top.first.value.times;

    final zeusCount = logs.where((l) => l.side == GodSide.zeus).length;
    final recent = app.logs.reversed.take(12).toList();

    return GodScreen(
      title: 'Stats',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: CupertinoSlidingSegmentedControl<_Period>(
              groupValue: _period,
              thumbColor: pal.primary.withOpacity(0.55),
              backgroundColor: Olymp.surface,
              children: const {
                _Period.week: Padding(padding: EdgeInsets.symmetric(vertical: 7), child: Text('7 days')),
                _Period.month: Padding(padding: EdgeInsets.symmetric(vertical: 7), child: Text('30 days')),
                _Period.all: Padding(padding: EdgeInsets.symmetric(vertical: 7), child: Text('All time')),
              },
              onValueChanged: (v) => setState(() => _period = v ?? _period),
            ),
          ),
        ),
        if (app.logs.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 16),
              child: EmptyState(
                emoji: '📊',
                title: 'No workouts yet',
                text: 'Finish your first exercise in Today and your stats will appear here.',
              ),
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _Tile(
                  label: 'EXERCISES',
                  value: fmtInt(count),
                  sub: prevCount == null ? 'all time' : '${count - prevCount >= 0 ? '+' : ''}${count - prevCount} vs previous',
                  color: pal.primary,
                ),
                _Tile(label: 'TIME', value: fmtDuration(secs), sub: count == 0 ? '—' : 'avg ${fmtDuration(secs ~/ math.max(1, count))}', color: pal.primary),
                _Tile(
                  label: volumeKg > 0 ? 'VOLUME' : 'REPS',
                  value: volumeKg > 0 ? fmtWeight(volumeKg, app.units) : fmtInt(reps),
                  sub: volumeKg > 0 ? '${fmtInt(reps)} reps' : 'total reps',
                  color: pal.primary,
                ),
                _Tile(label: 'STREAK', value: '${app.streak} days', sub: 'best — ${app.bestStreak}', color: pal.primary),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(_period == _Period.all ? 'Minutes per week' : 'Minutes per day', style: OT.headline)),
                        Text('avg ${avg.toStringAsFixed(0)} min', style: OT.subhead),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Bars(bars: bars, color: pal.primary),
                  ],
                ),
              ),
            ),
          ),
          if (count > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PATHS WALKED', style: OT.caption),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          children: [
                            if (zeusCount > 0)
                              Expanded(flex: zeusCount, child: Container(height: 10, color: GodPalette.zeus.primary)),
                            if (count - zeusCount > 0)
                              Expanded(flex: count - zeusCount, child: Container(height: 10, color: GodPalette.hades.primary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('⚡ Sol $zeusCount   ·   🔥 Mora ${count - zeusCount}', style: OT.subhead),
                    ],
                  ),
                ),
              ),
            ),
          if (top.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SectionHeader('Most frequent')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    children: [
                      for (final t in top.take(5))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(t.key, style: OT.headline.copyWith(fontSize: 15))),
                                  Text(
                                    '${t.value.times}× · ${t.value.reps > 0 ? '${fmtInt(t.value.reps)} reps' : fmtDuration(t.value.secs)}',
                                    style: OT.subhead,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearBar(value: t.value.times / topMax, color: pal.primary, height: 6),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SectionHeader('History · swipe to delete')),
          SliverList.builder(
            itemCount: recent.length,
            itemBuilder: (context, i) {
              final l = recent[i];
              return Dismissible(
                key: ObjectKey(l),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => confirmDestructive(context,
                    title: 'Delete this entry?', message: 'It will be removed from your stats.', action: 'Delete'),
                onDismissed: (_) => app.deleteLog(l),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 32),
                  child: const Icon(CupertinoIcons.trash, color: Olymp.danger),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Text(l.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.name, style: OT.headline.copyWith(fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  '${l.sets} sets',
                                  if (l.reps > 0) '${l.reps} reps',
                                  if (l.kg != null) fmtWeight(l.kg!, app.units),
                                  fmtDuration(l.seconds),
                                ].join(' · '),
                                style: OT.subhead.copyWith(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(fmtDate(l.at), style: OT.subhead.copyWith(fontSize: 13)),
                            if (l.ladderStep != null)
                              Text('step ${l.ladderStep! + 1}', style: OT.caption.copyWith(color: Olymp.gold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, required this.sub, required this.color});
  final String label, value, sub;
  final Color color;

  @override
  Widget build(BuildContext context) => GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: OT.caption),
            const SizedBox(height: 6),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: OT.display(28))),
            const SizedBox(height: 4),
            Text(sub, style: OT.subhead.copyWith(fontSize: 12, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}

class _Bars extends StatelessWidget {
  const _Bars({required this.bars, required this.color});
  final List<({String label, double value, bool highlight})> bars;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxV = bars.fold<double>(1, (a, b) => math.max(a, b.value));
    final reduce = MediaQuery.of(context).disableAnimations;
    final dense = bars.length > 12;
    return Semantics(
      label: bars.map((b) => '${b.label} ${b.value.round()} minutes').join(', '),
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final b in bars)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: dense ? 1.5 : 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!dense)
                        Text(b.value > 0 ? b.value.round().toString() : '–',
                            style: OT.caption.copyWith(fontSize: 11, color: Olymp.textSecondary)),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: b.value / maxV),
                        duration: reduce ? Duration.zero : const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => Container(
                          height: math.max(4, v * 96),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(dense ? 3 : 6),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: b.highlight ? [Olymp.gold, color] : [color.withOpacity(0.9), color.withOpacity(0.45)],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 14,
                        child: Text(b.label,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            softWrap: false,
                            style: OT.caption.copyWith(fontSize: 10, color: b.highlight ? color : Olymp.textTertiary)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
