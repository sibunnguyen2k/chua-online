import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../widgets/merit_format.dart';
import '../widgets/sprites/sprite.dart';
import '../widgets/sprites/sprites.dart';
import '../widgets/ui_helpers.dart';

class WoodenFishScreen extends StatefulWidget {
  const WoodenFishScreen({super.key});

  @override
  State<WoodenFishScreen> createState() => _WoodenFishScreenState();
}

class _WoodenFishScreenState extends State<WoodenFishScreen>
    with TickerProviderStateMixin {
  static const _maxFloating = 12;

  // Cú gõ: 0 -> 1 (dùi hạ xuống) rồi 1 -> 0 (nhấc lên).
  late final AnimationController _hit = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 90));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();
  late final Listenable _both = Listenable.merge([_hit, _idle]);
  final _rng = math.Random();
  final List<_Float> _floating = [];
  int _nextId = 0;
  int _session = 0;
  Timer? _auto;

  @override
  void dispose() {
    _auto?.cancel();
    _hit.dispose();
    _idle.dispose();
    super.dispose();
  }

  void _strike() {
    tapFeedback();
    AppScope.read(context).tap();
    _hit.forward(from: 0).then((_) {
      if (mounted) _hit.reverse();
    });
    setState(() {
      _session++;
      if (_floating.length >= _maxFloating) _floating.removeAt(0);
      _floating.add(_Float(_nextId++, (_rng.nextDouble() - 0.5) * 80));
    });
  }

  void _toggleAuto(bool on) {
    _auto?.cancel();
    _auto = on
        ? Timer.periodic(const Duration(milliseconds: 700), (_) => _strike())
        : null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gõ mõ tích công đức'),
        actions: [
          if (app.me != null)
            Padding(
                padding: const EdgeInsets.only(right: 12),
                child: MeritPill(merit: app.me!.totalMerit)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text('Phiên này: ${formatMerit(_session)} lần',
                style: theme.textTheme.titleMedium),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => _strike(),
                    child: Center(
                      // Chú tiểu ngồi sau mõ; dùi (lớp riêng) đập lên mặt mõ.
                      child: SizedBox(
                        width: 260,
                        height: 320,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 36,
                              top: -4,
                              child: Sprite(
                                size: 150,
                                animation: _idle,
                                draw: (c) => drawMonk(c,
                                    pose: MonkPose.tapping,
                                    t: _idle.value,
                                    mallet: false),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 40,
                              child: Sprite(
                                  size: 250,
                                  draw: (c) =>
                                      drawWoodenFish(c, mallet: false)),
                            ),
                            Positioned(
                              left: 36,
                              top: -4,
                              child: Sprite(
                                size: 150,
                                animation: _both,
                                draw: (c) => drawMonkMallet(c,
                                    t: _idle.value, strike: _hit.value),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  for (final f in _floating)
                    Positioned(
                      key: ValueKey(f.id),
                      top: 30,
                      child: _FloatingText(
                        dx: f.dx,
                        onDone: () {
                          if (mounted)
                            setState(() =>
                                _floating.removeWhere((e) => e.id == f.id));
                        },
                      ),
                    ),
                ],
              ),
            ),
            SwitchListTile(
              value: _auto != null,
              onChanged: _toggleAuto,
              title: const Text('Tự động gõ'),
              subtitle: const Text('Gõ đều đặn, chạm vào mõ để gõ thêm'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Float {
  const _Float(this.id, this.dx);
  final int id;
  final double dx;
}

class _FloatingText extends StatelessWidget {
  const _FloatingText({required this.dx, required this.onDone});
  final double dx;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      onEnd: onDone,
      builder: (_, t, __) => IgnorePointer(
        child: Opacity(
          opacity: 1 - t,
          child: Transform.translate(
            offset: Offset(dx, -90 * t),
            child: Text(
              '+1 công đức',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      ),
    );
  }
}
