import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'session_screen.dart';

class CustomScreen extends StatelessWidget {
  const CustomScreen({super.key});

  void _create(BuildContext context) => Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(fullscreenDialog: true, builder: (_) => const CreateExerciseScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final list = app.customs.reversed.toList();
    return GodScreen(
      title: 'My Exercises',
      trailing: Semantics(label: 'New exercise', child: NavPlusButton(onTap: () => _create(context))),
      slivers: [
        if (list.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: EmptyState(
                emoji: '📜',
                title: 'Create your own trial',
                text: 'Name an exercise, describe the technique and attach a photo. It will appear in Today.',
                action: CtaButton(label: 'New exercise', icon: CupertinoIcons.add, onTap: () => _create(context)),
              ),
            ),
          )
        else ...[
          const SliverToBoxAdapter(child: SectionHeader('Swipe left to delete')),
          SliverList.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final e = list[i];
              return Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => confirmDestructive(context,
                    title: 'Delete “${e.name}”?', message: 'Your workout history will be kept.', action: 'Delete'),
                onDismissed: (_) => app.deleteCustom(e),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 32),
                  child: const Icon(CupertinoIcons.trash, color: Olymp.danger),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExerciseCard(exercise: e, done: app.doneToday(e.id), onTap: () => openSession(context, e)),
                    if (e.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
                        child: Text(e.description, style: OT.subhead, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class CreateExerciseScreen extends StatefulWidget {
  const CreateExerciseScreen({super.key});

  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _load = TextEditingController();
  String? _photoPath;
  String _emoji = '💪';
  ExerciseKind _kind = ExerciseKind.reps;
  int _target = 12;
  int _sets = 3;
  bool _onlyMine = false;
  bool _saving = false;

  static const _emojis = ['💪', '🏋️', '🤸', '🏃', '🧘', '🥊', '🚴', '🏊', '⚡', '🔥', '🗡️', '🛡️'];

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _load.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final src = await pickPhotoSource(context);
    if (src == null) return;
    try {
      final x = await ImagePicker().pickImage(
        source: src == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (x != null) setState(() => _photoPath = x.path);
    } on PlatformException {
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('No access'),
          content: const Text('Allow camera and photo access for Solmora in Settings to attach photos.'),
          actions: [CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    final app = AppScope.read(context);
    String? photo;
    if (_photoPath != null) photo = await app.storePhoto(_photoPath!);
    app.addCustom(Exercise(
      id: 'c_${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      description: _desc.text.trim(),
      emoji: _emoji,
      side: _onlyMine ? app.side : null,
      kind: _kind,
      target: _target,
      sets: _sets,
      loadNote: _load.text.trim().isEmpty ? null : _load.text.trim(),
      photo: photo,
      custom: true,
    ));
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pal = app.palette;
    final canSave = _name.text.trim().isNotEmpty && !_saving;
    final reps = _kind == ExerciseKind.reps;

    return CupertinoPageScaffold(
      backgroundColor: Olymp.bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Olymp.bar,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        middle: const Text('New Exercise'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: canSave ? _save : null,
          child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(hPad(context, 16), 12, hPad(context, 16), 32),
          children: [
            Semantics(
              button: true,
              label: _photoPath == null ? 'Add a photo' : 'Change photo',
              child: Pressable(
                onTap: _pickPhoto,
                child: Container(
                  height: 190,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [pal.primary.withOpacity(0.35), pal.deep.withOpacity(0.8)],
                    ),
                    border: Border.all(color: Olymp.stroke),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: _photoPath != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(File(_photoPath!), fit: BoxFit.cover),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: CircleIconButton(
                                icon: CupertinoIcons.xmark,
                                size: 36,
                                onTap: () => setState(() => _photoPath = null),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_emoji, style: const TextStyle(fontSize: 54)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.camera_fill, size: 18, color: Olymp.textPrimary),
                                const SizedBox(width: 6),
                                Text('Add a photo', style: OT.headline.copyWith(fontSize: 15)),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ),
            if (_photoPath == null) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _emojis.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final sel = _emojis[i] == _emoji;
                    return Pressable(
                      onTap: () => setState(() => _emoji = _emojis[i]),
                      scale: 0.9,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: sel ? pal.primary.withOpacity(0.25) : Olymp.surface,
                          border: Border.all(color: sel ? pal.primary : Olymp.stroke),
                        ),
                        child: Center(child: Text(_emojis[i], style: const TextStyle(fontSize: 24))),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SectionHeader('Name'),
            _Field(controller: _name, placeholder: 'e.g. Atlas Lift'),
            const SectionHeader('Description & technique'),
            _Field(controller: _desc, placeholder: 'How to do it, what to watch for', minLines: 3, maxLines: 7),
            const SectionHeader('Type'),
            CupertinoSlidingSegmentedControl<ExerciseKind>(
              groupValue: _kind,
              thumbColor: pal.primary.withOpacity(0.55),
              backgroundColor: Olymp.surface,
              children: const {
                ExerciseKind.reps: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Reps')),
                ExerciseKind.time: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Timed')),
              },
              onValueChanged: (v) => setState(() {
                _kind = v ?? _kind;
                _target = _kind == ExerciseKind.reps ? 12 : 60;
              }),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  _StepperRow(
                    label: reps ? 'Reps per set' : 'Seconds per set',
                    value: reps ? '$_target' : fmtSec(_target),
                    onMinus: () => setState(() => _target = (_target - (reps ? 1 : 5)).clamp(1, 600).toInt()),
                    onPlus: () => setState(() => _target = (_target + (reps ? 1 : 5)).clamp(1, 600).toInt()),
                  ),
                  Container(height: 0.5, color: Olymp.stroke),
                  _StepperRow(
                    label: 'Sets',
                    value: '$_sets',
                    onMinus: () => setState(() => _sets = (_sets - 1).clamp(1, 12).toInt()),
                    onPlus: () => setState(() => _sets = (_sets + 1).clamp(1, 12).toInt()),
                  ),
                ],
              ),
            ),
            const SectionHeader('Load (optional)'),
            _Field(controller: _load, placeholder: 'e.g. 24 kg kettlebell'),
            const SectionHeader('Who it’s for'),
            CupertinoSlidingSegmentedControl<bool>(
              groupValue: _onlyMine,
              thumbColor: pal.primary.withOpacity(0.55),
              backgroundColor: Olymp.surface,
              children: {
                false: const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Both gods')),
                true: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Only ${pal.god}')),
              },
              onValueChanged: (v) => setState(() => _onlyMine = v ?? false),
            ),
            const SizedBox(height: 28),
            CtaButton(label: 'Save exercise', onTap: canSave ? _save : null),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.placeholder, this.minLines, this.maxLines = 1});
  final TextEditingController controller;
  final String placeholder;
  final int? minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) => CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        minLines: minLines,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        padding: const EdgeInsets.all(14),
        style: OT.headline.copyWith(fontWeight: FontWeight.w400),
        placeholderStyle: OT.body.copyWith(color: Olymp.textTertiary),
        decoration: BoxDecoration(
          color: Olymp.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Olymp.stroke),
        ),
      );
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({required this.label, required this.value, required this.onMinus, required this.onPlus});
  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label, style: OT.headline.copyWith(fontWeight: FontWeight.w500))),
            Semantics(label: 'Decrease', child: CircleIconButton(icon: CupertinoIcons.minus, size: 36, onTap: onMinus)),
            SizedBox(width: 64, child: Text(value, textAlign: TextAlign.center, style: OT.display(22))),
            Semantics(label: 'Increase', child: CircleIconButton(icon: CupertinoIcons.plus, size: 36, onTap: onPlus)),
          ],
        ),
      );
}
