import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class BodyScreen extends StatelessWidget {
  const BodyScreen({super.key});

  void _add(BuildContext context, {String? part}) => Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(fullscreenDialog: true, builder: (_) => AddMeasurementScreen(initialPart: part)),
      );

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pal = app.palette;
    final photos = app.photoMeasurements;
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));

    return GodScreen(
      title: 'Body',
      trailing: Semantics(label: 'Add measurement', child: NavPlusButton(onTap: () => _add(context))),
      slivers: [
        if (photos.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionHeader('Progress photos')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 150,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final m = photos[i];
                  final p = partByKey(m.part);
                  return Pressable(
                    onTap: () => Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => PhotoViewer(measurement: m),
                    )),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 108,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(app.photoFile(m.photo!), fit: BoxFit.cover, cacheWidth: 330,
                                errorBuilder: (_, __, ___) => const ColoredBox(color: Olymp.surface)),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0x00000000), Color(0xB3000000)],
                                  stops: [0.5, 1],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 8,
                              right: 8,
                              bottom: 8,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.title, style: OT.subhead.copyWith(fontSize: 12, color: Olymp.textPrimary, fontWeight: FontWeight.w600)),
                                  Text('${fmtDate(m.at)} · ${app.fmtMeasure(m.value, p)}', style: OT.subhead.copyWith(fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        if (app.measurements.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: EmptyState(
                emoji: '📏',
                title: 'Measure your progress',
                text: 'Log your arms, chest, waist and legs, and add a photo to see how your body changes over time.',
                action: CtaButton(label: 'Add measurement', icon: CupertinoIcons.add, onTap: () => _add(context)),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SectionHeader('Measurements')),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              for (final p in bodyParts)
                Builder(builder: (context) {
                  final hist = app.historyOf(p.key);
                  final last = hist.isEmpty ? null : hist.last;
                  Measurement? base;
                  for (final m in hist) {
                    if (!m.at.isAfter(monthAgo) || base == null) base = m;
                  }
                  final delta = (last != null && base != null && base != last)
                      ? toDisplay(last.value, p.isWeight, app.units) - toDisplay(base.value, p.isWeight, app.units)
                      : null;
                  return Pressable(
                    onTap: () => hist.isEmpty
                        ? _add(context, part: p.key)
                        : Navigator.of(context).push(CupertinoPageRoute(builder: (_) => PartHistoryScreen(part: p))),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${p.emoji}  ${p.title}', style: OT.subhead.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(last == null ? '—' : fmtNum(toDisplay(last.value, p.isWeight, app.units)), style: OT.display(26)),
                              const SizedBox(width: 4),
                              Text(p.isWeight ? weightUnit(app.units) : lengthUnit(app.units), style: OT.subhead.copyWith(fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            last == null
                                ? 'tap to add'
                                : delta == null || delta.abs() < 0.05
                                    ? 'no change'
                                    : '${delta > 0 ? '▲ +' : '▼ '}${fmtNum(delta.abs())} since ${fmtDate(base!.at)}',
                            style: OT.caption.copyWith(
                              fontSize: 11,
                              letterSpacing: 0.2,
                              color: last == null || delta == null || delta.abs() < 0.05
                                  ? Olymp.textTertiary
                                  : (delta > 0 ? Olymp.success : pal.glow),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class AddMeasurementScreen extends StatefulWidget {
  const AddMeasurementScreen({super.key, this.initialPart});
  final String? initialPart;

  @override
  State<AddMeasurementScreen> createState() => _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends State<AddMeasurementScreen> {
  late String _part = widget.initialPart ?? 'biceps_r';
  final _value = TextEditingController();
  String? _photoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _value.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  double? get _parsed {
    final v = double.tryParse(_value.text.replaceAll(',', '.').trim());
    if (v == null || v <= 0 || v >= 1000) return null;
    return v;
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
    final v = _parsed;
    if (v == null || _saving) return;
    setState(() => _saving = true);
    final app = AppScope.read(context);
    final p = partByKey(_part);
    String? photo;
    if (_photoPath != null) photo = await app.storePhoto(_photoPath!);
    app.addMeasurement(Measurement(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}',
      part: _part,
      value: fromDisplay(v, p.isWeight, app.units),
      at: DateTime.now(),
      photo: photo,
    ));
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pal = app.palette;
    final p = partByKey(_part);
    final unit = p.isWeight ? weightUnit(app.units) : lengthUnit(app.units);
    final canSave = _parsed != null && !_saving;

    return CupertinoPageScaffold(
      backgroundColor: Olymp.bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Olymp.bar,
        border: null,
        leading: CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        middle: const Text('New Measurement'),
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
          padding: EdgeInsets.fromLTRB(hPad(context, 16), 8, hPad(context, 16), 32),
          children: [
            const SectionHeader('Body part'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in bodyParts)
                  Pressable(
                    onTap: () => setState(() => _part = b.key),
                    scale: 0.94,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: b.key == _part ? pal.primary.withOpacity(0.25) : Olymp.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: b.key == _part ? pal.primary : Olymp.stroke),
                      ),
                      child: Text('${b.emoji} ${b.title}', style: OT.subhead.copyWith(color: Olymp.textPrimary)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(
                    width: 170,
                    child: CupertinoTextField(
                      controller: _value,
                      autofocus: widget.initialPart != null,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      placeholder: '0.0',
                      style: OT.display(56),
                      placeholderStyle: OT.display(56, color: Olymp.textTertiary),
                      decoration: const BoxDecoration(),
                    ),
                  ),
                  Text(unit, style: OT.display(24, color: Olymp.textSecondary)),
                ],
              ),
            ),
            Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 60), color: Olymp.stroke),
            const SizedBox(height: 24),
            Semantics(
              button: true,
              label: _photoPath == null ? 'Add a progress photo' : 'Change photo',
              child: Pressable(
                onTap: _pickPhoto,
                child: Container(
                  height: 160,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Olymp.stroke),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [pal.primary.withOpacity(0.25), pal.deep.withOpacity(0.7)],
                    ),
                  ),
                  child: _photoPath != null
                      ? Image.file(File(_photoPath!), fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.camera_fill, color: Olymp.textPrimary, size: 30),
                            const SizedBox(height: 8),
                            Text('Add a progress photo (optional)', style: OT.headline.copyWith(fontSize: 15)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            CtaButton(label: 'Save measurement', onTap: canSave ? _save : null),
          ],
        ),
      ),
    );
  }
}

class PartHistoryScreen extends StatelessWidget {
  const PartHistoryScreen({super.key, required this.part});
  final BodyPart part;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pal = app.palette;
    final hist = app.historyOf(part.key);
    final values = hist.map((m) => toDisplay(m.value, part.isWeight, app.units)).toList();

    return GodScreen(
      title: part.title,
      trailing: NavPlusButton(
        onTap: () => Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (_) => AddMeasurementScreen(initialPart: part.key),
        )),
      ),
      slivers: [
        if (values.length >= 2)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${fmtNum(values.first)} → ${fmtNum(values.last)} ${part.isWeight ? weightUnit(app.units) : lengthUnit(app.units)}',
                        style: OT.headline),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: Semantics(
                        label: 'Trend from ${fmtNum(values.first)} to ${fmtNum(values.last)}',
                        child: CustomPaint(size: Size.infinite, painter: _Spark(values, pal.primary)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SectionHeader('History · swipe to delete')),
        SliverList.builder(
          itemCount: hist.length,
          itemBuilder: (context, i) {
            final m = hist[hist.length - 1 - i];
            return Dismissible(
              key: ValueKey(m.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => confirmDestructive(context,
                  title: 'Delete this measurement?', message: 'Its photo will be deleted too.', action: 'Delete'),
              onDismissed: (_) => app.deleteMeasurement(m),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 32),
                child: const Icon(CupertinoIcons.trash, color: Olymp.danger),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (m.photo != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(app.photoFile(m.photo!), width: 44, height: 44, fit: BoxFit.cover, cacheWidth: 132,
                              errorBuilder: (_, __, ___) => const SizedBox(width: 44, height: 44)),
                        )
                      else
                        Text(part.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(fmtDateLong(m.at), style: OT.headline.copyWith(fontSize: 15))),
                      Text(app.fmtMeasure(m.value, part), style: OT.display(20)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Spark extends CustomPainter {
  _Spark(this.v, this.color);
  final List<double> v;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final lo = v.reduce(math.min), hi = v.reduce(math.max);
    final span = (hi - lo).abs() < 0.001 ? 1.0 : hi - lo;
    Offset at(int i) => Offset(
          v.length == 1 ? size.width / 2 : i * size.width / (v.length - 1),
          size.height - 8 - (v[i] - lo) / span * (size.height - 16),
        );
    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < v.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.35), color.withOpacity(0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.drawCircle(at(v.length - 1), 4.5, Paint()..color = Olymp.gold);
  }

  @override
  bool shouldRepaint(covariant _Spark old) => old.v != v || old.color != color;
}

class PhotoViewer extends StatelessWidget {
  const PhotoViewer({super.key, required this.measurement});
  final Measurement measurement;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = partByKey(measurement.part);
    final pad = MediaQuery.paddingOf(context);
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 4,
              child: Center(child: Image.file(app.photoFile(measurement.photo!), fit: BoxFit.contain)),
            ),
          ),
          Positioned(
            top: pad.top + 8,
            left: 16,
            child: Semantics(
              label: 'Close',
              child: CircleIconButton(icon: CupertinoIcons.xmark, onTap: () => Navigator.of(context).pop()),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: pad.bottom + 20,
            child: Text(
              '${p.title} · ${app.fmtMeasure(measurement.value, p)} · ${fmtDateLong(measurement.at)}',
              style: OT.headline,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
