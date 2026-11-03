import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../core/app_scope.dart';
import '../data/content.dart';
import '../widgets/merit_format.dart';
import '../widgets/sprites/sprite.dart';
import '../widgets/sprites/sprites.dart';
import '../widgets/ui_helpers.dart';
import 'scriptures_screen.dart';

/// Niệm Phật bằng chuỗi 108 hạt. Số lần niệm được gom và gửi lên máy chủ theo lô.
class ChantScreen extends StatefulWidget {
  const ChantScreen({super.key});

  @override
  State<ChantScreen> createState() => _ChantScreenState();
}

class _ChantScreenState extends State<ChantScreen> {
  static const _beads = 108;
  static const _flushEvery = 27;
  static const _maxPerCall = 1080;

  late final AppController _app = AppScope.read(context);
  int _mantra = 0;
  int _count = 0; // tổng số lần trong phiên
  int _pending = 0; // chưa gửi
  bool _flushing = false;

  @override
  void dispose() {
    // Gửi nốt phần còn lại; bỏ qua lỗi vì màn hình đã đóng.
    if (_pending > 0)
      unawaited(_app
          .chant(math.min(_pending, _maxPerCall))
          .then((_) {}, onError: (_) {}));
    super.dispose();
  }

  void _tap() {
    tapFeedback();
    setState(() {
      _count++;
      _pending++;
    });
    if (_pending >= _flushEvery) _flush();
  }

  Future<void> _flush({bool toast = false}) async {
    if (_flushing || _pending == 0) return;
    _flushing = true;
    final n = math.min(_pending, _maxPerCall);
    _pending -= n;
    final merit = await guarded(context, () => _app.chant(n));
    _flushing = false;
    if (merit == null) {
      _pending += n; // thử lại ở lần sau
    } else if (toast && mounted) {
      showMeritSnack(context, merit, 'Niệm Phật');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = mantras[_mantra];
    final inRound = _count % _beads;
    final rounds = _count ~/ _beads;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Niệm Phật'),
        actions: [
          IconButton(
            tooltip: 'Tụng kinh',
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const ScripturesScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: mantras.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ChoiceChip(
                  label: Text(mantras[i].text.replaceFirst('Nam mô ', '')),
                  selected: i == _mantra,
                  onSelected: (_) => setState(() => _mantra = i),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _tap,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: CustomPaint(
                        painter: _BeadsPainter(
                            filled: inRound,
                            total: _beads,
                            color: theme.colorScheme.primary,
                            empty: theme.colorScheme.outlineVariant),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(56),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Sprite(
                                    draw: (c) =>
                                        drawMonk(c, pose: MonkPose.praying),
                                    size: 64),
                                Text(m.text,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                Text(m.hint,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall),
                                const SizedBox(height: 14),
                                Text(formatMerit(_count),
                                    style: theme.textTheme.displaySmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w900)),
                                Text('$inRound/$_beads hạt • $rounds vòng'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _count == 0
                          ? null
                          : () => setState(() {
                                _count = 0;
                              }),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Đặt lại chuỗi'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _pending == 0 ? null : () => _flush(toast: true),
                      icon: const Icon(Icons.volunteer_activism_rounded),
                      label: Text('Hồi hướng ($_pending)'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeadsPainter extends CustomPainter {
  _BeadsPainter(
      {required this.filled,
      required this.total,
      required this.color,
      required this.empty});

  final int filled, total;
  final Color color, empty;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final radius = size.width / 2 - 8;
    final paintOn = Paint()..color = color;
    final paintOff = Paint()..color = empty;
    for (var i = 0; i < total; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / total;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * radius,
          i < filled ? 5.5 : 4, i < filled ? paintOn : paintOff);
    }
  }

  @override
  bool shouldRepaint(covariant _BeadsPainter old) =>
      old.filled != filled || old.color != color;
}
