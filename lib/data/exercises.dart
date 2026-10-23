import '../models.dart';

// ─────────────────────────────────────────────────────────────
// ZEUS — God of Light. Easy path: cardio, bodyweight, mobility.
// Targets are for the "Regular" level and scale with the user's level.
// ─────────────────────────────────────────────────────────────
const zeusPool = <Exercise>[
  Exercise(id: 'z_rope', name: 'Jump rope', emoji: '🪢', side: GodSide.zeus, kind: ExerciseKind.time, target: 120, sets: 3,
      description: 'Easy rhythm. Land softly on the balls of your feet, elbows close to your body.'),
  Exercise(id: 'z_squat', name: 'Squats', emoji: '🦵', side: GodSide.zeus, target: 20, sets: 3,
      description: 'Feet shoulder-width apart, chest up. Sit down until thighs are parallel to the floor.'),
  Exercise(id: 'z_pushup_knee', name: 'Knee push-ups', emoji: '🙌', side: GodSide.zeus, target: 12, sets: 3,
      description: 'Body in a straight line from knees to head. Chest almost touches the floor.'),
  Exercise(id: 'z_plank', name: 'Plank', emoji: '🧱', side: GodSide.zeus, kind: ExerciseKind.time, target: 45, sets: 3,
      description: 'On your forearms, belly tight, hips level — no sagging.'),
  Exercise(id: 'z_lunge', name: 'Lunges', emoji: '🚶', side: GodSide.zeus, target: 12, sets: 3,
      description: 'Step forward, both knees at 90°. Alternate legs.'),
  Exercise(id: 'z_jj', name: 'Jumping jacks', emoji: '⭐', side: GodSide.zeus, target: 40, sets: 3,
      description: 'Jump feet out and arms overhead, then jump back to start.'),
  Exercise(id: 'z_bridge', name: 'Glute bridge', emoji: '🌉', side: GodSide.zeus, target: 20, sets: 3,
      description: 'On your back, drive hips up and squeeze your glutes at the top.'),
  Exercise(id: 'z_crunch', name: 'Crunches', emoji: '🌀', side: GodSide.zeus, target: 20, sets: 3,
      description: 'Lower back pressed to the floor, lift only your shoulder blades.'),
  Exercise(id: 'z_calf', name: 'Calf raises', emoji: '🩰', side: GodSide.zeus, target: 25, sets: 3,
      description: 'Rise slowly, pause at the top, lower slowly.'),
  Exercise(id: 'z_run', name: 'Running in place', emoji: '🏃', side: GodSide.zeus, kind: ExerciseKind.time, target: 90, sets: 2,
      description: 'Knees high, drive with your arms.'),
  Exercise(id: 'z_climber', name: 'Mountain climbers', emoji: '🧗', side: GodSide.zeus, target: 20, sets: 3,
      description: 'From a high plank, pull knees to chest one at a time.'),
  Exercise(id: 'z_stretch', name: 'Sun stretch', emoji: '🧘', side: GodSide.zeus, kind: ExerciseKind.time, target: 60, sets: 2,
      description: 'Forward folds, shoulder and hip stretches. Breathe evenly, no bouncing.'),
];

// ─────────────────────────────────────────────────────────────
// HADES — God of Darkness. Hard path: barbell, heavy loads, volume.
// godKg is the god-level target; the user lifts a share of it that
// matches their calibrated strength.
// ─────────────────────────────────────────────────────────────
const hadesPool = <Exercise>[
  Exercise(id: 'h_squat', name: 'Barbell back squat', emoji: '🏋️', side: GodSide.hades, target: 5, sets: 5, godKg: 200,
      description: 'Bar on your traps, brace hard, hit depth below parallel. Always use a spotter or safety bars.'),
  Exercise(id: 'h_deadlift', name: 'Deadlift', emoji: '⛓️', side: GodSide.hades, target: 3, sets: 5, godKg: 250,
      description: 'Bar over mid-foot, neutral spine, push the floor away.'),
  Exercise(id: 'h_bench', name: 'Bench press', emoji: '🔨', side: GodSide.hades, target: 5, sets: 5, godKg: 150,
      description: 'Shoulder blades pinned, feet planted, touch the lower chest. Use a spotter.'),
  Exercise(id: 'h_pullup', name: 'Weighted pull-ups', emoji: '🪝', side: GodSide.hades, target: 6, sets: 5, godKg: 40, loadPrefix: '+',
      description: 'Full range: dead hang to chin over the bar.'),
  Exercise(id: 'h_dips', name: 'Weighted dips', emoji: '🗡️', side: GodSide.hades, target: 8, sets: 4, godKg: 50, loadPrefix: '+',
      description: 'Lower until your upper arm is parallel to the floor.'),
  Exercise(id: 'h_burpee', name: 'Burpees', emoji: '💀', side: GodSide.hades, target: 50, sets: 2,
      description: 'Drop, push-up, jump with a clap overhead. No rest between reps.'),
  Exercise(id: 'h_farmer', name: 'Farmer’s walk', emoji: '🪨', side: GodSide.hades, kind: ExerciseKind.time, target: 60, sets: 4, godKg: 100, loadPrefix: '2 × ',
      description: 'Heavy handles in each hand, walk tall, shoulders back.'),
  Exercise(id: 'h_ohp', name: 'Overhead press', emoji: '🔱', side: GodSide.hades, target: 5, sets: 5, godKg: 100,
      description: 'Strict press, no leg drive.'),
  Exercise(id: 'h_sled', name: 'Sled push', emoji: '🛷', side: GodSide.hades, kind: ExerciseKind.time, target: 30, sets: 6, godKg: 300,
      description: 'Low angle, short powerful steps.'),
  Exercise(id: 'h_row', name: 'Barbell row', emoji: '⚒️', side: GodSide.hades, target: 6, sets: 5, godKg: 140,
      description: 'Torso almost parallel to the floor, pull to your belly button.'),
  Exercise(id: 'h_plank', name: 'Weighted plank', emoji: '🪦', side: GodSide.hades, kind: ExerciseKind.time, target: 180, sets: 3, godKg: 40,
      description: 'Plate on your back, body like stone.'),
  Exercise(id: 'h_rope', name: 'Rope climb', emoji: '🧶', side: GodSide.hades, target: 3, sets: 4,
      description: 'Arms only, no legs. Come down under control.'),
];

List<Exercise> poolFor(GodSide side) => side == GodSide.zeus ? zeusPool : hadesPool;

// ─────────────────────────────────────────────────────────────
// LADDER: 30 steps per god
// ─────────────────────────────────────────────────────────────
class _Rung {
  final String name, emoji, desc;
  final ExerciseKind kind;
  final int base, perStep, sets;
  final double? kg, kgStep;
  final String prefix;
  const _Rung(this.name, this.emoji, this.desc,
      {this.kind = ExerciseKind.reps, required this.base, required this.perStep, this.sets = 3, this.kg, this.kgStep, this.prefix = ''});
}

const _zeusRungs = <_Rung>[
  _Rung('Jump rope', '🪢', 'Steady rhythm, soft landings.', kind: ExerciseKind.time, base: 60, perStep: 6),
  _Rung('Squats', '🦵', 'Deep and controlled.', base: 15, perStep: 1),
  _Rung('Push-ups', '🙌', 'Straight body, full range.', base: 8, perStep: 1),
  _Rung('Plank', '🧱', 'Belly tight.', kind: ExerciseKind.time, base: 30, perStep: 3),
  _Rung('Lunges', '🚶', 'Both knees at 90°.', base: 10, perStep: 1),
  _Rung('Jumping jacks', '⭐', 'Light and fast.', base: 30, perStep: 2),
  _Rung('Glute bridge', '🌉', 'Pause at the top.', base: 15, perStep: 1),
  _Rung('Mountain climbers', '🧗', 'Knees to chest.', base: 20, perStep: 1),
  _Rung('Calf raises', '🩰', 'Slow on the way down.', base: 20, perStep: 1),
  _Rung('Running in place', '🏃', 'Knees higher.', kind: ExerciseKind.time, base: 60, perStep: 5),
];

const _hadesRungs = <_Rung>[
  _Rung('Barbell squat', '🏋️', 'Always with a spotter or safety bars.', base: 5, perStep: 0, sets: 5, kg: 120, kgStep: 3),
  _Rung('Deadlift', '⛓️', 'Neutral spine.', base: 3, perStep: 0, sets: 5, kg: 140, kgStep: 4),
  _Rung('Bench press', '🔨', 'Shoulder blades pinned. Use a spotter.', base: 5, perStep: 0, sets: 5, kg: 80, kgStep: 3),
  _Rung('Weighted pull-ups', '🪝', 'Full range.', base: 6, perStep: 0, sets: 5, kg: 10, kgStep: 1, prefix: '+'),
  _Rung('Weighted dips', '🗡️', 'Upper arm parallel to the floor.', base: 8, perStep: 0, sets: 4, kg: 15, kgStep: 1, prefix: '+'),
  _Rung('Burpees', '💀', 'No rest between reps.', base: 30, perStep: 1, sets: 2),
  _Rung('Farmer’s walk', '🪨', 'Shoulders back.', kind: ExerciseKind.time, base: 45, perStep: 1, sets: 4, kg: 60, kgStep: 2, prefix: '2 × '),
  _Rung('Overhead press', '🔱', 'No leg drive.', base: 5, perStep: 0, sets: 5, kg: 50, kgStep: 2),
  _Rung('Sled push', '🛷', 'Short powerful steps.', kind: ExerciseKind.time, base: 25, perStep: 0, sets: 6, kg: 150, kgStep: 6),
  _Rung('Weighted plank', '🪦', 'Body like stone.', kind: ExerciseKind.time, base: 90, perStep: 4, kg: 20, kgStep: 1),
];

const _zeusFinal = Exercise(
  id: 'L_zeus_29',
  name: 'Wrath of Sol',
  emoji: '👑',
  side: GodSide.zeus,
  target: 50,
  sets: 3,
  loadNote: '3 min jump rope + 30 push-ups per round',
  description: 'The final trial of the Sun. Three rounds: 3 minutes of jump rope, 30 push-ups and 50 squats. Count the squats.',
);

const _hadesFinal = Exercise(
  id: 'L_hades_29',
  name: 'Throne of Mora',
  emoji: '👑',
  side: GodSide.hades,
  target: 3,
  sets: 5,
  godKg: 220,
  description: 'The final trial of the Night. Barbell squat, 5 sets of 3. A spotter or safety bars are mandatory.',
);

Exercise _rungAt(GodSide side, int i) {
  if (i == 29) return side == GodSide.zeus ? _zeusFinal : _hadesFinal;
  final rungs = side == GodSide.zeus ? _zeusRungs : _hadesRungs;
  final r = rungs[i % rungs.length];
  return Exercise(
    id: 'L_${side.name}_$i',
    name: r.name,
    emoji: r.emoji,
    side: side,
    kind: r.kind,
    target: r.base + r.perStep * i,
    sets: r.sets,
    godKg: r.kg == null ? null : r.kg! + (r.kgStep ?? 0) * i,
    loadPrefix: r.prefix,
    description: r.desc,
  );
}

final Map<GodSide, List<Exercise>> _ladderCache = {};

List<Exercise> ladderFor(GodSide side) => _ladderCache.putIfAbsent(side, () => List.generate(30, (i) => _rungAt(side, i)));

String tierFor(int stepsDone) {
  if (stepsDone >= 30) return 'God';
  if (stepsDone >= 20) return 'Demigod';
  if (stepsDone >= 10) return 'Hero';
  return 'Mortal';
}

const zeusLevels = ['Beginner', 'Regular', 'Athlete'];
const zeusLevelFactor = [0.7, 1.0, 1.3];
