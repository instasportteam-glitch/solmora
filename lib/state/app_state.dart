import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/exercises.dart';
import '../models.dart';
import '../theme.dart';

/// All data stays on the device (shared_preferences + the app's Documents
/// folder). Nothing is sent anywhere — see the privacy note in Profile.
class AppState extends ChangeNotifier {
  AppState._(this._prefs, this.docsPath);

  static const _key = 'olympus_state_v1';

  /// A god's one-rep-max squat. The user's share of the god-level weights is
  /// their own 1RM divided by this, so a god's 5×5 at 200 kg becomes ~80% of
  /// the user's real max.
  static const godSquat1rm = 250.0;

  final SharedPreferences _prefs;
  final String docsPath;

  GodSide? side;
  String name = 'Mortal';
  DateTime startedAt = DateTime.now();
  final Map<GodSide, int> ladder = {GodSide.zeus: 0, GodSide.hades: 0};
  List<Exercise> customs = [];
  List<WorkoutLog> logs = [];
  List<Measurement> measurements = [];

  // settings
  Units units = Units.metric;
  double? bodyweightKg;
  double? squat1rmKg;
  int zeusLevel = 1;
  int restSeconds = 90;
  bool healthAck = false;

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final dir = await getApplicationDocumentsDirectory();
    await Directory('${dir.path}/photos').create(recursive: true);
    final s = AppState._(prefs, dir.path);
    s._read();
    return s;
  }

  void _read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      side = j['side'] == null ? null : GodSide.values.byName(j['side'] as String);
      name = (j['name'] as String?) ?? name;
      startedAt = DateTime.tryParse((j['startedAt'] as String?) ?? '') ?? startedAt;
      final l = (j['ladder'] as Map<String, dynamic>?) ?? {};
      for (final s in GodSide.values) {
        ladder[s] = (l[s.name] as num?)?.toInt() ?? 0;
      }
      customs = ((j['customs'] as List?) ?? []).map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList();
      logs = ((j['logs'] as List?) ?? []).map((e) => WorkoutLog.fromJson(e as Map<String, dynamic>)).toList();
      measurements =
          ((j['measurements'] as List?) ?? []).map((e) => Measurement.fromJson(e as Map<String, dynamic>)).toList();
      units = Units.values.byName((j['units'] as String?) ?? 'metric');
      bodyweightKg = (j['bodyweightKg'] as num?)?.toDouble();
      squat1rmKg = (j['squat1rmKg'] as num?)?.toDouble();
      zeusLevel = (j['zeusLevel'] as num?)?.toInt() ?? 1;
      restSeconds = (j['restSeconds'] as num?)?.toInt() ?? 90;
      healthAck = (j['healthAck'] as bool?) ?? false;
    } catch (_) {
      // Corrupted data: start clean rather than crash.
    }
  }

  Future<void> _save() => _prefs.setString(
        _key,
        jsonEncode({
          'side': side?.name,
          'name': name,
          'startedAt': startedAt.toIso8601String(),
          'ladder': {for (final e in ladder.entries) e.key.name: e.value},
          'customs': customs.map((e) => e.toJson()).toList(),
          'logs': logs.map((e) => e.toJson()).toList(),
          'measurements': measurements.map((e) => e.toJson()).toList(),
          'units': units.name,
          'bodyweightKg': bodyweightKg,
          'squat1rmKg': squat1rmKg,
          'zeusLevel': zeusLevel,
          'restSeconds': restSeconds,
          'healthAck': healthAck,
        }),
      );

  void _commit() {
    notifyListeners();
    _save();
  }

  // ---------- photos ----------

  /// Only the file name is stored: the app container path on iOS changes
  /// between updates, so the absolute path is rebuilt at runtime.
  File photoFile(String name) => File('$docsPath/photos/$name');

  Future<String> storePhoto(String sourcePath) async {
    final name = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File(sourcePath).copy(photoFile(name).path);
    return name;
  }

  void _deletePhoto(String? name) {
    if (name == null) return;
    final f = photoFile(name);
    if (f.existsSync()) f.deleteSync();
  }

  // ---------- side & setup ----------

  GodPalette get palette => GodPalette.of(side ?? GodSide.zeus);

  void completeSetup({
    required GodSide chosen,
    required Units units,
    double? bodyweightKg,
    double? squat1rmKg,
    int? zeusLevel,
  }) {
    this.units = units;
    if (bodyweightKg != null) this.bodyweightKg = bodyweightKg;
    if (chosen == GodSide.hades) {
      this.squat1rmKg = squat1rmKg;
      restSeconds = max(restSeconds, 90);
    }
    if (zeusLevel != null) this.zeusLevel = zeusLevel;
    healthAck = true;
    side = chosen;
    _commit();
  }

  void leaveSide() {
    side = null;
    _commit();
  }

  void rename(String n) {
    final t = n.trim();
    if (t.isEmpty) return;
    name = t.length > 24 ? t.substring(0, 24) : t;
    _commit();
  }

  void setUnits(Units u) {
    units = u;
    _commit();
  }

  void setRest(int s) {
    restSeconds = s.clamp(15, 300).toInt();
    _commit();
  }

  // ---------- scaling ----------

  /// Share of god-level weights the user lifts (0.25 … 1.0).
  double get strengthFactor => factorFrom(squat1rmKg, bodyweightKg);

  static double factorFrom(double? squat1rm, double? bodyweight) {
    if (squat1rm != null && squat1rm > 0) return (squat1rm / godSquat1rm).clamp(0.25, 1.0).toDouble();
    // Unknown max: assume a conservative squat of ~0.8 × body weight.
    if (bodyweight != null && bodyweight > 0) return (bodyweight * 0.8 / godSquat1rm).clamp(0.2, 0.45).toDouble();
    return 0.25;
  }

  int targetFor(Exercise e) {
    if (e.custom || e.side != GodSide.zeus) return e.target;
    final f = zeusLevelFactor[zeusLevel.clamp(0, 2).toInt()];
    if (e.kind == ExerciseKind.reps) return max(1, (e.target * f).round());
    return max(10, ((e.target * f) / 5).round() * 5);
  }

  double? kgFor(Exercise e) {
    final g = e.godKg;
    if (g == null) return null;
    return max(2.5, roundPlate(g * strengthFactor));
  }

  String targetLabel(Exercise e) {
    final t = targetFor(e);
    return e.kind == ExerciseKind.reps ? '${e.sets} × $t reps' : '${e.sets} × ${fmtSec(t)}';
  }

  /// "112.5 kg" (yours) — short form for cards.
  String? loadShort(Exercise e) {
    final kg = kgFor(e);
    if (kg != null) return '${e.loadPrefix}${fmtWeight(kg, units)}';
    return e.loadNote;
  }

  /// "God 200 kg" — the summit.
  String? godLoad(Exercise e) =>
      e.godKg == null ? null : 'God ${e.loadPrefix}${fmtWeight(e.godKg!, units)}';

  // ---------- workouts ----------

  List<Exercise> todayPlan() {
    final s = side ?? GodSide.zeus;
    final pool = [...poolFor(s)];
    pool.shuffle(Random(dayKey(DateTime.now()) + s.index * 7919));
    return pool.take(5).toList();
  }

  List<Exercise> get myCustoms => customs.where((e) => e.side == null || e.side == side).toList();

  bool doneToday(String exerciseId) {
    final k = dayKey(DateTime.now());
    return logs.any((l) => l.exerciseId == exerciseId && dayKey(l.at) == k);
  }

  List<WorkoutLog> get todayLogs {
    final k = dayKey(DateTime.now());
    return logs.where((l) => dayKey(l.at) == k).toList();
  }

  void addLog(WorkoutLog log) {
    logs.add(log);
    _commit();
  }

  void deleteLog(WorkoutLog log) {
    logs.remove(log);
    _commit();
  }

  void addCustom(Exercise e) {
    customs.add(e);
    _commit();
  }

  void deleteCustom(Exercise e) {
    customs.removeWhere((c) => c.id == e.id);
    _deletePhoto(e.photo);
    _commit();
  }

  // ---------- ladder ----------

  int get ladderStep => ladder[side ?? GodSide.zeus] ?? 0;

  List<Exercise> get ladderList => ladderFor(side ?? GodSide.zeus);

  bool get isGod => ladderStep >= 30;

  String get tier => tierFor(ladderStep);

  bool completeLadderStep(int step) {
    final s = side ?? GodSide.zeus;
    if (step != (ladder[s] ?? 0)) return false;
    ladder[s] = step + 1;
    _commit();
    return true;
  }

  // ---------- progress ----------

  int get xp => logs.fold(0, (a, l) => a + l.xp);

  int get level => 1 + sqrt(xp / 40).floor();

  int xpForLevel(int lvl) => 40 * (lvl - 1) * (lvl - 1);

  int get streak {
    if (logs.isEmpty) return 0;
    final days = logs.map((l) => dayKey(l.at)).toSet();
    var d = dayStart(DateTime.now());
    if (!days.contains(dayKey(d))) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (days.contains(dayKey(d))) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }

  int get bestStreak {
    if (logs.isEmpty) return 0;
    final days = logs.map((l) => dayStart(l.at)).toSet().toList()..sort();
    var best = 1, cur = 1;
    for (var i = 1; i < days.length; i++) {
      final prev = days[i - 1];
      final expected = DateTime(prev.year, prev.month, prev.day + 1);
      cur = days[i] == expected ? cur + 1 : 1;
      best = max(best, cur);
    }
    return best;
  }

  int get daysWithUs => DateTime.now().difference(dayStart(startedAt)).inDays + 1;

  // ---------- measurements ----------

  void addMeasurement(Measurement m) {
    measurements.add(m);
    measurements.sort((a, b) => a.at.compareTo(b.at));
    if (m.part == 'weight') bodyweightKg = m.value;
    _commit();
  }

  void deleteMeasurement(Measurement m) {
    measurements.removeWhere((x) => x.id == m.id);
    _deletePhoto(m.photo);
    _commit();
  }

  List<Measurement> historyOf(String part) => measurements.where((m) => m.part == part).toList();

  List<Measurement> get photoMeasurements => measurements.where((m) => m.photo != null).toList().reversed.toList();

  String fmtMeasure(double metric, BodyPart p) =>
      '${fmtNum(toDisplay(metric, p.isWeight, units))} ${p.isWeight ? weightUnit(units) : lengthUnit(units)}';

  // ---------- reset ----------

  void resetAll() {
    for (final c in customs) {
      _deletePhoto(c.photo);
    }
    for (final m in measurements) {
      _deletePhoto(m.photo);
    }
    side = null;
    name = 'Mortal';
    startedAt = DateTime.now();
    ladder.updateAll((_, __) => 0);
    customs = [];
    logs = [];
    measurements = [];
    bodyweightKg = null;
    squat1rmKg = null;
    zeusLevel = 1;
    restSeconds = 90;
    healthAck = false;
    _commit();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState super.notifier, required super.child});

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
