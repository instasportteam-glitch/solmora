import 'package:flutter/cupertino.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'session_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.onOpenLadder});

  final VoidCallback onOpenLadder;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pal = app.palette;
    final plan = app.todayPlan();
    final customs = app.myCustoms;
    final done = plan.where((e) => app.doneToday(e.id)).length;
    final todayLogs = app.todayLogs;
    final seconds = todayLogs.fold<int>(0, (a, l) => a + l.seconds);
    final xp = todayLogs.fold<int>(0, (a, l) => a + l.xp);
    final now = DateTime.now();

    return GodScreen(
      title: 'Today',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: GlassCard(
              blur: true,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${weekdaysShort[now.weekday - 1].toUpperCase()} · ${fmtDateLong(now).toUpperCase()}',
                            style: OT.caption.copyWith(color: pal.glow)),
                        const SizedBox(height: 6),
                        Text('${pal.god} awaits,\n${app.name}', style: OT.display(26)),
                        const SizedBox(height: 10),
                        Text(
                          done == plan.length
                              ? 'Daily trial complete. ${pal.emoji}'
                              : 'Daily trial: ${plan.length} exercises',
                          style: OT.subhead,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _MiniStat(icon: CupertinoIcons.timer, text: fmtDuration(seconds)),
                            const SizedBox(width: 14),
                            _MiniStat(icon: CupertinoIcons.star_fill, text: '+$xp XP'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    label: '$done of ${plan.length} done',
                    child: ProgressRing(
                      value: plan.isEmpty ? 0 : done / plan.length,
                      color: pal.primary,
                      size: 92,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$done/${plan.length}', style: OT.display(24)),
                          const Text('DONE', style: OT.caption),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SectionHeader('Daily trial')),
        SliverList.builder(
          itemCount: plan.length,
          itemBuilder: (context, i) => ExerciseCard(
            exercise: plan[i],
            done: app.doneToday(plan[i].id),
            onTap: () => openSession(context, plan[i]),
          ),
        ),
        if (customs.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionHeader('Your exercises')),
          SliverList.builder(
            itemCount: customs.length,
            itemBuilder: (context, i) => ExerciseCard(
              exercise: customs[i],
              done: app.doneToday(customs[i].id),
              onTap: () => openSession(context, customs[i]),
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Pressable(
              onTap: onOpenLadder,
              child: GlassCard(
                tint: pal.primary,
                child: Row(
                  children: [
                    Text(app.isGod ? '👑' : '🏛️', style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app.isGod ? 'You are the God of ${pal.realm}' : 'Ladder: step ${app.ladderStep + 1} of 30',
                              style: OT.headline),
                          const SizedBox(height: 6),
                          LinearBar(value: app.ladderStep / 30, color: pal.primary),
                          const SizedBox(height: 6),
                          Text('Rank: ${app.tier}', style: OT.subhead),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(CupertinoIcons.chevron_right, size: 18, color: Olymp.textTertiary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Olymp.gold),
          const SizedBox(width: 4),
          Text(text, style: OT.subhead.copyWith(color: Olymp.textPrimary)),
        ],
      );
}
