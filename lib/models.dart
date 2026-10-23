enum GodSide { zeus, hades }

enum ExerciseKind { reps, time }

enum Units { metric, imperial }

class Exercise {
  final String id;
  final String name;
  final String description;
  final String emoji;

  /// null — available to both gods.
  final GodSide? side;
  final ExerciseKind kind;

  /// Reps per set, or seconds per set.
  final int target;
  final int sets;

  /// The god-level weight in kg. The app scales it to the user's strength.
  final double? godKg;

  /// Shown before the weight: "+" for added weight, "2 × " for a pair.
  final String loadPrefix;

  /// Free-form load for custom exercises, e.g. "24 kg kettlebell".
  final String? loadNote;

  /// File name of a photo inside the app's documents folder.
  final String? photo;
  final bool custom;

  const Exercise({
    required this.id,
    required this.name,
    this.description = '',
    this.emoji = '💪',
    this.side,
    this.kind = ExerciseKind.reps,
    this.target = 10,
    this.sets = 3,
    this.godKg,
    this.loadPrefix = '',
    this.loadNote,
    this.photo,
    this.custom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'emoji': emoji,
        'side': side?.name,
        'kind': kind.name,
        'target': target,
        'sets': sets,
        'godKg': godKg,
        'loadPrefix': loadPrefix,
        'loadNote': loadNote,
        'photo': photo,
        'custom': custom,
      };

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        id: j['id'] as String,
        name: j['name'] as String,
        description: (j['description'] as String?) ?? '',
        emoji: (j['emoji'] as String?) ?? '💪',
        side: j['side'] == null ? null : GodSide.values.byName(j['side'] as String),
        kind: ExerciseKind.values.byName((j['kind'] as String?) ?? 'reps'),
        target: (j['target'] as num?)?.toInt() ?? 10,
        sets: (j['sets'] as num?)?.toInt() ?? 3,
        godKg: (j['godKg'] as num?)?.toDouble(),
        loadPrefix: (j['loadPrefix'] as String?) ?? '',
        loadNote: j['loadNote'] as String?,
        photo: j['photo'] as String?,
        custom: (j['custom'] as bool?) ?? true,
      );
}

class WorkoutLog {
  final String exerciseId;
  final String name;
  final String emoji;
  final DateTime at;
  final int reps;
  final int seconds;
  final int sets;
  final GodSide side;

  /// Weight actually used, kg (for Hades exercises).
  final double? kg;

  /// Ladder step index 0..29 if this was a ladder trial that was completed.
  final int? ladderStep;

  const WorkoutLog({
    required this.exerciseId,
    required this.name,
    required this.emoji,
    required this.at,
    required this.reps,
    required this.seconds,
    required this.sets,
    required this.side,
    this.kg,
    this.ladderStep,
  });

  int get xp => ladderStep != null ? 50 : (side == GodSide.hades ? 20 : 10);

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'name': name,
        'emoji': emoji,
        'at': at.toIso8601String(),
        'reps': reps,
        'seconds': seconds,
        'sets': sets,
        'side': side.name,
        'kg': kg,
        'ladderStep': ladderStep,
      };

  factory WorkoutLog.fromJson(Map<String, dynamic> j) => WorkoutLog(
        exerciseId: j['exerciseId'] as String,
        name: j['name'] as String,
        emoji: (j['emoji'] as String?) ?? '💪',
        at: DateTime.parse(j['at'] as String),
        reps: (j['reps'] as num?)?.toInt() ?? 0,
        seconds: (j['seconds'] as num?)?.toInt() ?? 0,
        sets: (j['sets'] as num?)?.toInt() ?? 0,
        side: GodSide.values.byName(j['side'] as String),
        kg: (j['kg'] as num?)?.toDouble(),
        ladderStep: (j['ladderStep'] as num?)?.toInt(),
      );
}

/// Stored in metric (kg / cm); converted only for display and input.
class Measurement {
  final String id;
  final String part;
  final double value;
  final DateTime at;
  final String? photo;

  const Measurement({required this.id, required this.part, required this.value, required this.at, this.photo});

  Map<String, dynamic> toJson() =>
      {'id': id, 'part': part, 'value': value, 'at': at.toIso8601String(), 'photo': photo};

  factory Measurement.fromJson(Map<String, dynamic> j) => Measurement(
        id: j['id'] as String,
        part: j['part'] as String,
        value: (j['value'] as num).toDouble(),
        at: DateTime.parse(j['at'] as String),
        photo: j['photo'] as String?,
      );
}

class BodyPart {
  final String key;
  final String title;
  final bool isWeight;
  final String emoji;
  const BodyPart(this.key, this.title, this.emoji, {this.isWeight = false});
}

const bodyParts = <BodyPart>[
  BodyPart('weight', 'Weight', '⚖️', isWeight: true),
  BodyPart('biceps_l', 'Left biceps', '💪'),
  BodyPart('biceps_r', 'Right biceps', '💪'),
  BodyPart('forearm', 'Forearm', '🦾'),
  BodyPart('shoulders', 'Shoulders', '🏛️'),
  BodyPart('chest', 'Chest', '🛡️'),
  BodyPart('waist', 'Waist', '⏳'),
  BodyPart('hips', 'Hips', '🔱'),
  BodyPart('thigh_l', 'Left thigh', '🦵'),
  BodyPart('thigh_r', 'Right thigh', '🦵'),
  BodyPart('calf', 'Calf', '🏺'),
  BodyPart('neck', 'Neck', '🗿'),
];

BodyPart partByKey(String key) => bodyParts.firstWhere((p) => p.key == key, orElse: () => bodyParts.first);

// ---------- units ----------

const kgPerLb = 0.45359237;
const cmPerIn = 2.54;

double roundPlate(double kg) => (kg / 2.5).round() * 2.5;

String fmtNum(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

String fmtWeight(double kg, Units u) {
  if (u == Units.imperial) {
    final lb = (kg / kgPerLb / 5).round() * 5;
    return '$lb lb';
  }
  return '${fmtNum(kg)} kg';
}

String weightUnit(Units u) => u == Units.imperial ? 'lb' : 'kg';
String lengthUnit(Units u) => u == Units.imperial ? 'in' : 'cm';

/// metric value → display value
double toDisplay(double metric, bool isWeight, Units u) {
  if (u == Units.metric) return metric;
  return isWeight ? metric / kgPerLb : metric / cmPerIn;
}

/// display value → metric value
double fromDisplay(double shown, bool isWeight, Units u) {
  if (u == Units.metric) return shown;
  return isWeight ? shown * kgPerLb : shown * cmPerIn;
}

// ---------- formatting ----------

String fmtSec(int s) {
  if (s < 60) return '$s s';
  final m = s ~/ 60;
  final r = s % 60;
  return r == 0 ? '$m min' : '$m:${r.toString().padLeft(2, '0')}';
}

String fmtClock(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String fmtDuration(int seconds) {
  if (seconds < 60) return '$seconds s';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h == 0) return '$m min';
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

String fmtInt(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _monthsFull = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];
const weekdaysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';
String fmtDateLong(DateTime d) => '${_monthsFull[d.month - 1]} ${d.day}';

int dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

DateTime dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
