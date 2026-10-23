import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../data/exercises.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/god_background.dart';

/// Step 2 of onboarding (and "Calibration" in Profile).
/// Hades: body weight + best squat → every weight is scaled to the user.
/// Zeus: a fitness level that scales reps and durations.
/// Both: a short health acknowledgement before training starts.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.side, this.editing = false});

  final GodSide side;

  /// true when opened from Profile: saves settings, keeps the current god.
  final bool editing;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _bw = TextEditingController();
  final _sq = TextEditingController();
  Units _units = Units.metric;
  int _level = 1;
  bool _ack = false;

  bool get _hades => widget.side == GodSide.hades;

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    _units = app.units;
    _level = app.zeusLevel;
    _ack = widget.editing || app.healthAck;
    if (app.bodyweightKg != null) _bw.text = fmtNum(toDisplay(app.bodyweightKg!, true, _units));
    if (app.squat1rmKg != null) _sq.text = fmtNum(toDisplay(app.squat1rmKg!, true, _units));
    _bw.addListener(() => setState(() {}));
    _sq.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _bw.dispose();
    _sq.dispose();
    super.dispose();
  }

  double? _parseKg(TextEditingController c) {
    final v = double.tryParse(c.text.replaceAll(',', '.').trim());
    if (v == null || v <= 0 || v > 1000) return null;
    return fromDisplay(v, true, _units);
  }

  void _switchUnits(Units u) {
    if (u == _units) return;
    final bw = _parseKg(_bw), sq = _parseKg(_sq);
    setState(() {
      _units = u;
      if (bw != null) _bw.text = fmtNum(toDisplay(bw, true, u).roundToDouble());
      if (sq != null) _sq.text = fmtNum(toDisplay(sq, true, u).roundToDouble());
    });
  }

  void _finish() {
    if (!_ack) return;
    final app = AppScope.read(context);
    HapticFeedback.heavyImpact();
    if (widget.editing) {
      app.units = _units;
      final bw = _parseKg(_bw);
      if (bw != null) app.bodyweightKg = bw;
      if (_hades) app.squat1rmKg = _parseKg(_sq);
      app.zeusLevel = _level;
      app.setUnits(_units); // commits & notifies
      Navigator.of(context).pop();
      return;
    }
    // Leave onboarding first; the app root then switches to the tabs.
    Navigator.of(context).popUntil((r) => r.isFirst);
    app.completeSetup(
      chosen: widget.side,
      units: _units,
      bodyweightKg: _parseKg(_bw),
      squat1rmKg: _hades ? _parseKg(_sq) : null,
      zeusLevel: _hades ? null : _level,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = GodPalette.of(widget.side);
    final pad = MediaQuery.paddingOf(context);
    final factor = AppState.factorFrom(_parseKg(_sq), _parseKg(_bw));
    final firstKg = roundPlate(200 * factor);
    final zeusRope = (120 * zeusLevelFactor[_level] / 5).round() * 5;

    return CupertinoPageScaffold(
      backgroundColor: Olymp.bg,
      child: Stack(
        children: [
          Positioned.fill(child: GodBackground(side: widget.side, intensity: 0.8)),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x5909080F), Color(0xE609080F)],
                ),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: pad.top + 6),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad(context, 12)),
                child: Row(
                  children: [
                    CircleIconButton(
                      icon: widget.editing ? CupertinoIcons.xmark : CupertinoIcons.chevron_left,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(hPad(context, 20), 12, hPad(context, 20), 20),
                  children: [
                    Text(
                      widget.editing ? 'CALIBRATION' : 'STEP 2 OF 2 · PATH OF ${pal.god.toUpperCase()}',
                      style: OT.caption.copyWith(color: pal.glow),
                    ),
                    const SizedBox(height: 8),
                    Text(_hades ? 'Forge your strength' : 'Find your rhythm', style: OT.display(34)),
                    const SizedBox(height: 10),
                    Text(
                      _hades
                          ? 'Mora sets every weight from your real strength. The gods’ numbers are the summit — you climb toward them.'
                          : 'Sol scales reps and durations to your level. You can change it any time in Profile.',
                      style: OT.body,
                    ),
                    const SizedBox(height: 18),
                    CupertinoSlidingSegmentedControl<Units>(
                      groupValue: _units,
                      thumbColor: pal.primary.withOpacity(0.55),
                      backgroundColor: Olymp.surface,
                      children: const {
                        Units.metric: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('kg · cm')),
                        Units.imperial: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('lb · in')),
                      },
                      onValueChanged: (v) => _switchUnits(v ?? _units),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        children: [
                          _NumberRow(label: 'Body weight', controller: _bw, unit: weightUnit(_units)),
                          if (_hades) ...[
                            Container(height: 0.5, color: Olymp.stroke),
                            _NumberRow(label: 'Best squat, 1 rep', controller: _sq, unit: weightUnit(_units)),
                          ],
                        ],
                      ),
                    ),
                    if (_hades)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(4, 8, 4, 0),
                        child: Text('Not sure? Leave it empty — we’ll estimate from body weight and start light.',
                            style: OT.subhead),
                      ),
                    if (!_hades) ...[
                      const SizedBox(height: 18),
                      const Text('YOUR LEVEL', style: OT.caption),
                      const SizedBox(height: 8),
                      CupertinoSlidingSegmentedControl<int>(
                        groupValue: _level,
                        thumbColor: pal.primary.withOpacity(0.55),
                        backgroundColor: Olymp.surface,
                        children: {
                          for (var i = 0; i < zeusLevels.length; i++)
                            i: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(zeusLevels[i])),
                        },
                        onValueChanged: (v) => setState(() => _level = v ?? _level),
                      ),
                    ],
                    const SizedBox(height: 16),
                    GlassCard(
                      tint: pal.primary,
                      borderColor: pal.primary.withOpacity(0.4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('YOUR FIRST TRIAL', style: OT.caption.copyWith(color: pal.glow)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(_hades ? 'Barbell squat 5 × 5' : 'Jump rope 3 rounds', style: OT.headline),
                              ),
                              Text(_hades ? fmtWeight(firstKg, _units) : fmtSec(zeusRope), style: OT.display(24)),
                            ],
                          ),
                          if (_hades) ...[
                            const SizedBox(height: 10),
                            LinearBar(value: firstKg / 200, color: pal.primary),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Expanded(child: Text('You today', style: OT.subhead)),
                                Text('God target ${fmtWeight(200, _units)}', style: OT.subhead),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => setState(() => _ack = !_ack),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CupertinoCheckbox(
                            value: _ack,
                            activeColor: pal.primary,
                            onChanged: (v) => setState(() => _ack = v ?? false),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                _hades
                                    ? 'I’m healthy enough for heavy training and will use a spotter or safety bars.'
                                    : 'I’m healthy enough for moderate exercise and will stop if anything hurts.',
                                style: OT.body.copyWith(color: Olymp.textPrimary.withOpacity(0.9)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Not medical advice. Talk to a doctor before starting a new training program.',
                      style: OT.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(hPad(context, 20), 4, hPad(context, 20), pad.bottom + 16),
                child: CtaButton(
                  label: widget.editing ? 'Save' : (_hades ? 'Descend with Mora' : 'Rise with Sol'),
                  onTap: _ack ? _finish : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({required this.label, required this.controller, required this.unit});
  final String label;
  final TextEditingController controller;
  final String unit;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 58,
        child: Row(
          children: [
            Expanded(child: Text(label, style: OT.headline.copyWith(fontWeight: FontWeight.w500))),
            SizedBox(
              width: 88,
              child: CupertinoTextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                placeholder: '—',
                style: OT.display(20),
                placeholderStyle: OT.display(20, color: Olymp.textTertiary),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Olymp.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Olymp.stroke),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 22, child: Text(unit, style: OT.subhead)),
          ],
        ),
      );
}
