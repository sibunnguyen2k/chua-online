import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../widgets/sprites/offering_sprites.dart';
import '../widgets/sprites/sprite.dart';
import '../widgets/sprites/sprites.dart';
import '../widgets/ui_helpers.dart';
import 'temples_screen.dart';

class ShrineScreen extends StatefulWidget {
  const ShrineScreen({super.key});

  @override
  State<ShrineScreen> createState() => _ShrineScreenState();
}

class _ShrineScreenState extends State<ShrineScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat();
  final Map<String, int> _offered = {}; // vật phẩm đã dâng trong phiên
  String? _busyItem;

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    app.loadCatalog().catchError((_) {});
    if (app.temples.isEmpty) app.loadTemples().catchError((_) {});
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _offer(String id, String label) async {
    final app = AppScope.read(context);
    setState(() => _busyItem = id);
    final merit = await guarded(context, () => app.makeOffering(id));
    if (!mounted) return;
    setState(() {
      _busyItem = null;
      if (merit != null) _offered.update(id, (v) => v + 1, ifAbsent: () => 1);
    });
    if (merit != null) showMeritSnack(context, merit, label);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điện thờ'),
        actions: [
          if (app.me != null)
            Padding(
                padding: const EdgeInsets.only(right: 12),
                child: MeritPill(merit: app.me!.totalMerit))
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TempleChip(
              name: app.selectedTemple?.name,
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const TemplesScreen(pickMode: true))),
            ),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => CustomPaint(
                  painter:
                      _AltarPainter(t: _anim.value, offered: Map.of(_offered)),
                ),
              ),
            ),
          ),
          const SectionTitle('Dâng lễ'),
          if (app.catalog.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final o in app.catalog)
                  SizedBox(
                    width: (MediaQuery.sizeOf(context).width - 32 - 20) / 3,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _busyItem == null
                            ? () => _offer(o.id, o.label)
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 6),
                          child: Column(
                            children: [
                              _busyItem == o.id
                                  ? const SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : Sprite(draw: offeringDraw(o.id), size: 44),
                              const SizedBox(height: 6),
                              Text(o.label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text('+${o.merit}',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AltarPainter extends CustomPainter {
  _AltarPainter({required this.t, required this.offered});

  final double t;
  final Map<String, int> offered;

  @override
  void paint(Canvas canvas, Size s) {
    final u = s.width / 100;
    Rect box(double x, double y, double w) =>
        Rect.fromLTWH(x * u, y * u, w * u, w * u);

    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
                colors: [Color(0xFF3B0D0D), Color(0xFF7B1E1E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter)
            .createShader(Offset.zero & s),
    );

    placeSprite(canvas, box(17, 0, 66), (c) => drawBuddha(c, t: t));

    // Bàn thờ: mặt bàn + khăn trải
    canvas.drawRect(Rect.fromLTWH(0, 72 * u, s.width, 28 * u),
        Paint()..color = const Color(0xFF8B1A1A));
    canvas.drawRect(Rect.fromLTWH(0, 72 * u, s.width, 3 * u),
        Paint()..color = const Color(0xFFE7B53A));
    canvas.drawRect(Rect.fromLTWH(0, 69 * u, s.width, 3 * u),
        Paint()..color = const Color(0xFF4E2A10));

    // Vật thờ cố định + vật phẩm đã dâng
    placeSprite(canvas, box(3, 51, 21), (c) => drawCandle(c, t: t));
    placeSprite(canvas, box(76, 51, 21), (c) => drawCandle(c, t: t + 0.4));
    if ((offered['flower'] ?? 0) > 0)
      placeSprite(canvas, box(22, 51, 21), (c) => drawFlowerVase(c, t: t));
    if ((offered['lamp'] ?? 0) > 0)
      placeSprite(canvas, box(57, 51, 21), (c) => drawOilLamp(c, t: t));
    if ((offered['fruit'] ?? 0) > 0)
      placeSprite(canvas, box(12, 72, 26), (c) => drawFruitPlate(c));
    if ((offered['meal'] ?? 0) > 0)
      placeSprite(canvas, box(62, 72, 26), (c) => drawRiceBowl(c));
    placeSprite(canvas, box(34, 43, 32),
        (c) => drawIncenseBurner(c, t: t, sticks: offered['incense'] ?? 0));
  }

  @override
  bool shouldRepaint(covariant _AltarPainter old) =>
      old.t != t || !mapEquals(old.offered, offered);
}
