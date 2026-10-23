import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/god_background.dart';

/// Opens a workout above the tabs (slides up, dismisses back down).
/// Returns true if the workout was logged.
Future<bool?> openSession(BuildContext context, Exercise e, {int? ladderStep}) =>
    Navigator.of(context, rootNavigator: true).push<bool>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => SessionScreen(exercise: e, ladderStep: ladderStep),
      ),
    );

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.exercise, this.ladderStep});
  final Exercise exercise;
  final int? ladderStep;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final _total = Stopwatch();
  final _rest = Stopwatch();
  Timer? _ticker;
  Duration _setMark = Duration.zero;
  int _setsDone = 0;
  int _repsInSet = 0;
  int _totalReps = 0;
  late int _target;
  late int _restSeconds;
  double? _kg;

  Exercise get e => widget.exercise;
  bool get _isTime => e.kind == ExerciseKind.time;
  bool get _allSets => _setsDone >= e.sets;
  bool get _resting => _rest.isRunning;

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    _target = app.targetFor(e);
    _kg = app.kgFor(e);
    _restSeconds = app.restSeconds;
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    if (_resting && _rest.elapsed.inSeconds >= _restSeconds) {
      _endRest();
    }
    if (_total.isRunning && _isTime && !_allSets && !_resting) {
      final inSet = _total.elapsed - _setMark;
      if (inSet.inMilliseconds >= _target * 1000) _completeSet();
    }
    if (_total.isRunning || _resting) setState(() {});
  }

  void _startRest() {
    if (_allSets) return;
    _rest
      ..reset()
      ..start();
  }

  void _endRest() {
    HapticFeedback.heavyImpact();
    _rest
      ..stop()
      ..reset();
    _setMark = _total.elapsed;
    setState(() {});
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_resting) {
        _endRest();
        if (!_total.isRunning) _total.start();
        return;
      }
      _total.isRunning ? _total.stop() : _total.start();
    });
  }

  void _addRep() {
    if (_allSets) return;
    if (_resting) _endRest();
    if (!_total.isRunning) _total.start();
    HapticFeedback.selectionClick();
    setState(() {
      _repsInSet++;
      _totalReps++;
      if (_repsInSet >= _target) _completeSet();
    });
  }

  void _removeRep() {
    if (_repsInSet == 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      _repsInSet--;
      _totalReps--;
    });
  }

  void _completeSet() {
    if (_allSets) return;
    HapticFeedback.mediumImpact();
    _setsDone++;
    _repsInSet = 0;
    _setMark = _total.elapsed;
    if (!_allSets) _startRest();
    if (_allSets) _total.stop();
  }

  bool get _hasProgress => _setsDone > 0 || _totalReps > 0 || _total.elapsed.inSeconds >= 5;

  void _finish() {
    final app = AppScope.read(context);
    _total.stop();
    final reps = _isTime ? 0 : (_totalReps > 0 ? _totalReps : _setsDone * _target);
    final completedLadder = widget.ladderStep != null && _allSets;
    app.addLog(WorkoutLog(
      exerciseId: e.id,
      name: e.name,
      emoji: e.emoji,
      at: DateTime.now(),
      reps: reps,
      seconds: _total.elapsed.inSeconds,
      sets: _setsDone,
      side: app.side ?? GodSide.zeus,
      kg: _kg,
      ladderStep: completedLadder ? widget.ladderStep : null,
    ));
    if (completedLadder) app.completeLadderStep(widget.ladderStep!);
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop(true);
  }

  Future<void> _close() async {
    if (!_hasProgress) {
      Navigator.of(context).pop(false);
      return;
    }
    final leave = await confirmDestructive(context,
        title: 'Quit workout?', message: 'Progress from this workout won’t be saved.', action: 'Quit');
    if (leave && mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pal = app.palette;
    final pad = MediaQuery.paddingOf(context);
    final photo = e.photo;
    final load = app.loadShort(e);
    final god = app.godLoad(e);
    final targetLabel = _isTime ? '${e.sets} × ${fmtSec(_target)}' : '${e.sets} × $_target reps';

    return CupertinoPageScaffold(
      backgroundColor: Olymp.bg,
      child: Stack(
        children: [
          Positioned.fill(child: GodBackground(side: app.side ?? GodSide.zeus, intensity: 0.9)),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x4009080F), Color(0xCC09080F), Color(0xF209080F)],
                ),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: pad.top + 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad(context, 16)),
                child: Row(
                  children: [
                    Semantics(label: 'Close', child: CircleIconButton(icon: CupertinoIcons.xmark, onTap: _close)),
                    Expanded(
                      child: Text(
                        widget.ladderStep != null ? 'STEP ${widget.ladderStep! + 1} OF 30' : 'WORKOUT',
                        style: OT.caption,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Olymp.surfaceStrong, borderRadius: BorderRadius.circular(20)),
                      child: Text(fmtClock(_total.elapsed),
                          style: OT.headline.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(hPad(context, 20), 16, hPad(context, 20), 16),
                  children: [
                    if (photo != null && app.photoFile(photo).existsSync())
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.file(app.photoFile(photo), height: 200, fit: BoxFit.cover),
                      )
                    else
                      Center(child: Text(e.emoji, style: const TextStyle(fontSize: 60))),
                    const SizedBox(height: 14),
                    Text(e.name, style: OT.display(30), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(targetLabel, pal.primary),
                        if (load != null) _Chip(god == null ? load : '$load · $god', Olymp.gold),
                      ],
                    ),
                    if (e.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(e.description, style: OT.body, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 22),
                    Center(child: _isTime ? _timeDial(pal) : _repDial(pal)),
                    const SizedBox(height: 18),
                    _setDots(pal),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _resting ? _restBanner() : const SizedBox(height: 0, key: ValueKey('no-rest')),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GhostButton(
                            label: _resting
                                ? 'Skip rest'
                                : _total.isRunning
                                    ? 'Pause'
                                    : (_total.elapsed == Duration.zero ? 'Start' : 'Resume'),
                            icon: _resting
                                ? CupertinoIcons.forward_fill
                                : (_total.isRunning ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill),
                            onTap: _allSets ? null : _toggle,
                          ),
                        ),
                        if (!_isTime) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: GhostButton(
                              label: 'Set done',
                              icon: CupertinoIcons.checkmark_alt,
                              color: pal.primary,
                              onTap: _allSets ? null : () => setState(_completeSet),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (widget.ladderStep != null && !_allSets && _hasProgress) ...[
                      const SizedBox(height: 14),
                      Text('Finish every set to climb this step.',
                          style: OT.subhead.copyWith(color: Olymp.gold), textAlign: TextAlign.center),
                    ],
                    if (_kg != null) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Weights are scaled to your calibration. Lower the load if form breaks, and always train with a spotter or safety bars.',
                        style: OT.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(hPad(context, 20), 4, hPad(context, 20), pad.bottom + 16),
                child: CtaButton(
                  label: _allSets ? 'Complete' : 'Log result',
                  onTap: _hasProgress ? _finish : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _restBanner() {
    final left = _restSeconds - _rest.elapsed.inSeconds;
    return Container(
      key: const ValueKey('rest'),
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Olymp.gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Olymp.gold.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.timer, size: 16, color: Olymp.gold),
          const SizedBox(width: 8),
          Text(
            'Rest ${fmtClock(Duration(seconds: left.clamp(0, 999).toInt()))} · next set ${_setsDone + 1}',
            style: OT.subhead.copyWith(
                color: Olymp.gold, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }

  Widget _repDial(GodPalette pal) => Semantics(
        button: true,
        label: 'Add one rep. $_repsInSet of $_target',
        child: Pressable(
          onTap: _addRep,
          haptic: false,
          scale: 0.94,
          child: ProgressRing(
            value: _allSets ? 1 : _repsInSet / _target,
            color: pal.primary,
            size: 210,
            stroke: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_allSets ? '✓' : '$_repsInSet',
                    style: OT.display(72).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                Text(_allSets ? 'all sets done' : 'of $_target · tap +1', style: OT.subhead),
                const SizedBox(height: 6),
                if (!_allSets)
                  Semantics(
                    button: true,
                    label: 'Remove one rep',
                    child: GestureDetector(
                      onTap: _removeRep,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(CupertinoIcons.minus_circle, color: Olymp.textTertiary, size: 24),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _timeDial(GodPalette pal) {
    final inSet = (_allSets || _resting) ? Duration.zero : _total.elapsed - _setMark;
    final remaining = Duration(seconds: _target) - inSet;
    final left = remaining.isNegative ? Duration.zero : remaining;
    return ProgressRing(
      value: _allSets ? 1 : inSet.inMilliseconds / (_target * 1000),
      color: pal.primary,
      size: 210,
      stroke: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_allSets ? '✓' : fmtClock(left + const Duration(milliseconds: 999)),
              style: OT.display(56).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          Text(
            _allSets
                ? 'all sets done'
                : _resting
                    ? 'resting'
                    : (_total.isRunning ? 'hold on' : 'tap Start'),
            style: OT.subhead,
          ),
        ],
      ),
    );
  }

  Widget _setDots(GodPalette pal) => Column(
        children: [
          Text('SETS  $_setsDone / ${e.sets}', style: OT.caption),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: List.generate(e.sets, (i) {
              final done = i < _setsDone;
              final current = i == _setsDone;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: current ? 28 : 12,
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: done ? Olymp.goldGradient : null,
                  color: done ? null : (current ? pal.primary : const Color(0x33FFFFFF)),
                ),
              );
            }),
          ),
        ],
      );
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(text, style: OT.subhead.copyWith(color: color, fontWeight: FontWeight.w600)),
      );
}
