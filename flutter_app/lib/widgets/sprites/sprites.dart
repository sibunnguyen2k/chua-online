import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bộ nhân vật & vật thể vẽ bằng vector. Mọi hàm `draw*` vẽ trong hệ toạ độ
/// 100x100 (gốc ở góc trên trái); widget [Sprite] tự co giãn theo kích thước.
/// Tham số `t` (0..1, lặp) điều khiển hoạt ảnh nhẹ (thở, chập chờn, chớp mắt).

const _skin = Color(0xFFFFD7B5);
const _skinDark = Color(0xFFE8B88A);
const _saffron = Color(0xFFF4A300);
const _saffronDark = Color(0xFFD98200);
const _brown = Color(0xFF8B3A1A);
const _gold = Color(0xFFE7B53A);
const _goldDark = Color(0xFFB8860B);
const _bronze = Color(0xFF9C6B2E);

Paint _f(Color c) => Paint()..color = c;
Paint _s(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;
Paint _g(Gradient g, Rect r) => Paint()..shader = g.createShader(r);

/// Cánh sen hướng lên, gốc tại [base], xoay [angle] rad (chiều kim đồng hồ).
void _petal(
    Canvas c, Offset base, double len, double w, double angle, Paint fill,
    [Paint? edge]) {
  c.save();
  c.translate(base.dx, base.dy);
  c.rotate(angle);
  final p = Path()
    ..quadraticBezierTo(w, -len * 0.45, 0, -len)
    ..quadraticBezierTo(-w, -len * 0.45, 0, 0)
    ..close();
  c.drawPath(p, fill);
  if (edge != null) c.drawPath(p, edge);
  c.restore();
}

void _limb(Canvas c, Offset a, Offset b, double w, Color color) =>
    c.drawLine(a, b, _s(color, w));

// ───────────────────────── Nhân vật ─────────────────────────

/// Tượng Phật ngồi thiền trên toà sen, có hào quang thở nhẹ.
void drawBuddha(Canvas c, {double t = 0}) {
  final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
  const head = Offset(50, 36);

  c.drawCircle(
      const Offset(50, 36),
      36,
      _g(
          RadialGradient(colors: [
            const Color(0xFFFFE082).withValues(alpha: 0.5 + 0.3 * pulse),
            Colors.transparent
          ]),
          Rect.fromCircle(center: const Offset(50, 36), radius: 36)));
  c.drawCircle(const Offset(50, 36), 25,
      _s(const Color(0xFFFFD54F).withValues(alpha: 0.55 + 0.3 * pulse), 1.4));

  // Toà sen
  for (final i in [-3, 3, -2, 2, -1, 1, 0]) {
    _petal(
        c,
        Offset(50 + i * 10.5, 95 - i.abs() * 1.2),
        16,
        8,
        i * 0.3,
        _f(i.isEven ? const Color(0xFFFF9EBB) : const Color(0xFFFFC1D5)),
        _s(const Color(0xFFE57399), 0.6));
  }

  // Thân (y phục)
  final body = Path()
    ..moveTo(25, 88)
    ..cubicTo(25, 68, 29, 54, 38, 51)
    ..quadraticBezierTo(50, 47, 62, 51)
    ..cubicTo(71, 54, 75, 68, 75, 88)
    ..quadraticBezierTo(50, 94, 25, 88)
    ..close();
  c.drawPath(
      body,
      _g(
          const LinearGradient(
              colors: [_saffron, _saffronDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
          const Rect.fromLTWH(25, 47, 50, 47)));
  c.drawPath(
      Path()
        ..moveTo(40, 52)
        ..quadraticBezierTo(50, 78, 66, 54),
      _s(_brown, 1.3));
  c.drawOval(const Rect.fromLTWH(24, 76, 52, 13), _f(_saffronDark));
  c.drawOval(const Rect.fromLTWH(41, 74, 18, 9), _f(_skin));
  c.drawLine(const Offset(46, 78), const Offset(54, 78), _s(_skinDark, 0.8));

  // Cổ, tai, đầu
  c.drawRect(const Rect.fromLTWH(46, 46, 8, 6), _f(_skinDark));
  c.drawOval(
      Rect.fromCenter(center: const Offset(36.5, 40), width: 5, height: 13),
      _f(_skin));
  c.drawOval(
      Rect.fromCenter(center: const Offset(63.5, 40), width: 5, height: 13),
      _f(_skin));
  c.drawCircle(head, 13, _f(_skin));

  // Tóc xoắn + nhục kế
  final hair = _f(const Color(0xFF2E3A6B));
  c.drawArc(Rect.fromCircle(center: head, radius: 13), math.pi * 1.04,
      math.pi * 0.92, true, hair);
  c.drawCircle(const Offset(50, 22), 5.5, hair);
  for (final dx in [-7.0, -2.5, 2.5, 7.0]) {
    c.drawCircle(Offset(50 + dx, 26.5 - (dx.abs() > 5 ? -1 : 0.5)), 1.8, hair);
  }

  // Gương mặt
  final eye = _s(const Color(0xFF5A3A22), 1.1);
  c.drawPath(
      Path()
        ..moveTo(42, 37)
        ..quadraticBezierTo(45, 39.5, 48, 37),
      eye);
  c.drawPath(
      Path()
        ..moveTo(52, 37)
        ..quadraticBezierTo(55, 39.5, 58, 37),
      eye);
  c.drawCircle(const Offset(50, 32), 1.2, _f(const Color(0xFFD32F2F)));
  c.drawPath(
      Path()
        ..moveTo(46.5, 43)
        ..quadraticBezierTo(50, 45.8, 53.5, 43),
      _s(const Color(0xFFB5523B), 1.1));
}

enum MonkPose { idle, praying, tapping }

/// Chú tiểu (mascot). [strike] 0..1 dùng cho pose gõ mõ.
void drawMonk(Canvas c,
    {MonkPose pose = MonkPose.idle,
    double t = 0,
    double strike = 0,
    bool mallet = true}) {
  final bob = math.sin(t * 2 * math.pi) * 1.2;
  c.save();
  c.translate(0, bob);

  // Áo
  final robe = RRect.fromRectAndRadius(
      const Rect.fromLTWH(25, 56, 50, 38), const Radius.circular(17));
  c.drawRRect(
      robe,
      _g(
          const LinearGradient(
              colors: [_saffron, _saffronDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
          robe.outerRect));
  c.drawPath(
      Path()
        ..moveTo(29, 59)
        ..lineTo(43, 57)
        ..lineTo(70, 90)
        ..lineTo(57, 93)
        ..close(),
      _f(_brown));

  // Tay
  switch (pose) {
    case MonkPose.idle:
      _limb(c, const Offset(30, 64), const Offset(27, 84), 9, _saffronDark);
      _limb(c, const Offset(70, 64), const Offset(73, 84), 9, _saffronDark);
      c.drawCircle(const Offset(27, 87), 4.2, _f(_skin));
      c.drawCircle(const Offset(73, 87), 4.2, _f(_skin));
    case MonkPose.praying:
      _limb(c, const Offset(30, 64), const Offset(46, 73), 9, _saffronDark);
      _limb(c, const Offset(70, 64), const Offset(54, 73), 9, _saffronDark);
      c.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(45.5, 64, 9, 15), const Radius.circular(4.5)),
          _f(_skin));
      c.drawLine(
          const Offset(50, 66), const Offset(50, 78), _s(_skinDark, 0.8));
    case MonkPose.tapping:
      _limb(c, const Offset(30, 64), const Offset(27, 84), 9, _saffronDark);
      c.drawCircle(const Offset(27, 87), 4.2, _f(_skin));
      final hand = Offset(80, 50 + 12 * strike);
      _limb(c, const Offset(70, 64), hand, 9, _saffronDark);
      c.drawCircle(hand, 4.2, _f(_skin));
  }

  // Đầu
  const head = Offset(50, 38);
  c.drawCircle(const Offset(31, 40), 4.5, _f(_skin));
  c.drawCircle(const Offset(69, 40), 4.5, _f(_skin));
  c.drawCircle(
      head,
      21,
      _g(
          const RadialGradient(
              center: Alignment(-0.3, -0.4),
              colors: [Color(0xFFFFE6CC), _skin]),
          Rect.fromCircle(center: head, radius: 21)));
  // Chấm giới ba
  for (final p in const [Offset(46, 22), Offset(50, 20.5), Offset(54, 22)]) {
    c.drawCircle(p, 0.9, _f(_skinDark));
  }
  // Má hồng
  c.drawCircle(const Offset(39, 45), 3.6,
      _f(const Color(0xFFFF9E9E).withValues(alpha: 0.55)));
  c.drawCircle(const Offset(61, 45), 3.6,
      _f(const Color(0xFFFF9E9E).withValues(alpha: 0.55)));
  // Mắt (chớp định kỳ)
  final phase = t % 1;
  final blink = phase > 0.93 && phase < 0.97;
  final ink = _f(const Color(0xFF3B2A1A));
  for (final x in [42.0, 58.0]) {
    if (blink || pose == MonkPose.praying) {
      c.drawPath(
          Path()
            ..moveTo(x - 3, 38.5)
            ..quadraticBezierTo(x, 41, x + 3, 38.5),
          _s(const Color(0xFF3B2A1A), 1.3));
    } else {
      c.drawOval(
          Rect.fromCenter(center: Offset(x, 38.5), width: 4.4, height: 5.4),
          ink);
      c.drawCircle(Offset(x + 0.9, 37.2), 0.9, _f(Colors.white));
    }
  }
  c.drawPath(
      Path()
        ..moveTo(46, 48)
        ..quadraticBezierTo(50, 51.5, 54, 48),
      _s(const Color(0xFFB5523B), 1.3));
  if (pose == MonkPose.tapping && mallet) _drawMallet(c, strike);
  c.restore();
}

// ───────────────────────── Vật thể ─────────────────────────

void _drawMallet(Canvas c, double strike) {
  // Giơ lên-trái khi strike=0, hạ xuống-trái chạm mõ khi strike=1.
  final hand = Offset(80, 50 + 12 * strike);
  final ang = -2.2 - 1.58 * strike;
  final tip = hand + Offset(math.cos(ang), math.sin(ang)) * 34;
  _limb(c, hand, tip, 2.6, _bronze);
  c.drawCircle(tip, 4.5, _f(_brown));
  c.drawCircle(tip.translate(-1.2, -1.2), 1.4, _f(Colors.white30));
}

/// Lớp dùi của chú tiểu (cùng toạ độ/nhịp bồng bềnh với [drawMonk]) để vẽ đè lên mõ.
void drawMonkMallet(Canvas c, {double t = 0, double strike = 0}) {
  c.save();
  c.translate(0, math.sin(t * 2 * math.pi) * 1.2);
  _drawMallet(c, strike);
  c.restore();
}

/// Mõ (cá gỗ) cùng dùi. [strike] 0..1: 0 giơ dùi, 1 chạm mõ.
void drawWoodenFish(Canvas c, {double strike = 0, bool mallet = true}) {
  const ctr = Offset(46, 60);
  c.drawOval(
      Rect.fromCenter(center: const Offset(46, 94), width: 66, height: 8),
      _f(Colors.black12));

  // Thân mõ: oval rộng, có khe và vân gỗ
  final body = Rect.fromCenter(center: ctr, width: 80, height: 62);
  c.drawOval(
      body,
      _g(
          const RadialGradient(center: Alignment(-0.35, -0.45), colors: [
            Color(0xFFE0A044),
            Color(0xFF9C5A17),
            Color(0xFF5E3410)
          ]),
          body));
  for (var i = 1; i <= 3; i++) {
    c.drawArc(
        Rect.fromCenter(
            center: ctr.translate(-4, -4),
            width: 22 + i * 14,
            height: 16 + i * 10),
        math.pi * 1.1,
        math.pi * 0.6,
        false,
        _s(Colors.white24, 1));
  }
  c.drawPath(
      Path()
        ..moveTo(18, 64)
        ..quadraticBezierTo(46, 80, 74, 64),
      _s(const Color(0xFF2E1A08), 5.5));
  // Đuôi cá nhỏ bên trái
  c.drawPath(
      Path()
        ..moveTo(8, 60)
        ..lineTo(0, 50)
        ..lineTo(0, 70)
        ..close(),
      _f(const Color(0xFF7A4515)));

  if (!mallet) return;
  // Dùi
  const pivot = Offset(90, 22);
  final angle = 3.55 + (2.55 - 3.55) * strike;
  final head = pivot + Offset(math.cos(angle), math.sin(angle)) * 34;
  c.drawLine(pivot, head, _s(_bronze, 3.4));
  c.drawCircle(head, 6, _f(_brown));
  c.drawCircle(head.translate(-1.5, -1.5), 2, _f(Colors.white24));
}

/// Lư hương đồng với tối đa 5 nén hương và làn khói.
void drawIncenseBurner(Canvas c, {double t = 0, int sticks = 0}) {
  final n = sticks.clamp(0, 5);
  for (var i = 0; i < n; i++) {
    final x = 50 + (i - (n - 1) / 2) * 7;
    c.drawLine(Offset(x, 66), Offset(x, 30), _s(const Color(0xFF8D6E63), 1.8));
    c.drawCircle(Offset(x, 30), 1.8, _f(const Color(0xFFFF5252)));
    final smoke = Path()..moveTo(x, 28);
    for (var y = 1; y <= 8; y++) {
      smoke.lineTo(
          x + math.sin(y / 1.8 + t * 2 * math.pi + i) * (1.5 + y * 0.9),
          28 - y * 3.1);
    }
    c.drawPath(smoke, _s(Colors.white.withValues(alpha: 0.5), 1.6));
  }
  // Chân
  for (final x in [30.0, 70.0]) {
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, 88), width: 7, height: 10),
            const Radius.circular(3)),
        _f(_goldDark));
  }
  // Thân lư
  final bowl = Path()
    ..moveTo(18, 66)
    ..quadraticBezierTo(20, 92, 50, 92)
    ..quadraticBezierTo(80, 92, 82, 66)
    ..close();
  c.drawPath(
      bowl,
      _g(
          const LinearGradient(
              colors: [Color(0xFFE7B53A), _bronze],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
          const Rect.fromLTWH(18, 66, 64, 26)));
  c.drawOval(const Rect.fromLTWH(16, 62, 68, 10), _f(_goldDark));
  c.drawOval(const Rect.fromLTWH(22, 64, 56, 6), _f(const Color(0xFF6D5B4B)));
  c.drawPath(
      Path()
        ..moveTo(30, 78)
        ..quadraticBezierTo(50, 84, 70, 78),
      _s(Colors.white30, 1.2));
}

void _flame(Canvas c, Offset base, double h, double t, double seed) {
  final flick = 0.88 + 0.12 * math.sin((t + seed) * 2 * math.pi * 3);
  final hh = h * flick;
  final glow =
      Rect.fromCircle(center: base.translate(0, -hh * 0.5), radius: hh * 1.1);
  c.drawCircle(
      glow.center,
      glow.width / 2,
      _g(
          RadialGradient(colors: [
            const Color(0xFFFFB74D).withValues(alpha: 0.5),
            Colors.transparent
          ]),
          glow));
  final p = Path()
    ..moveTo(base.dx, base.dy)
    ..cubicTo(base.dx + hh * 0.42, base.dy - hh * 0.2, base.dx + hh * 0.18,
        base.dy - hh * 0.7, base.dx, base.dy - hh)
    ..cubicTo(base.dx - hh * 0.18, base.dy - hh * 0.7, base.dx - hh * 0.42,
        base.dy - hh * 0.2, base.dx, base.dy);
  c.drawPath(p, _f(const Color(0xFFFFA726)));
  c.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(base.dx + hh * 0.2, base.dy - hh * 0.2, base.dx,
            base.dy - hh * 0.55)
        ..quadraticBezierTo(
            base.dx - hh * 0.2, base.dy - hh * 0.2, base.dx, base.dy),
      _f(const Color(0xFFFFF59D)));
}

/// Nến đỏ.
void drawCandle(Canvas c, {double t = 0}) {
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(38, 42, 24, 50), const Radius.circular(4)),
      _g(const LinearGradient(colors: [Color(0xFFEF5350), Color(0xFFC62828)]),
          const Rect.fromLTWH(38, 42, 24, 50)));
  c.drawOval(const Rect.fromLTWH(38, 39, 24, 7), _f(const Color(0xFFFF8A80)));
  c.drawLine(
      const Offset(50, 42), const Offset(50, 36), _s(Colors.black87, 1.2));
  _flame(c, const Offset(50, 37), 24, t, 0);
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(30, 90, 40, 6), const Radius.circular(3)),
      _f(_goldDark));
}

/// Đèn dầu.
void drawOilLamp(Canvas c, {double t = 0}) {
  final bowl = Path()
    ..moveTo(22, 66)
    ..quadraticBezierTo(50, 96, 78, 66)
    ..close();
  c.drawPath(
      bowl,
      _g(
          const LinearGradient(
              colors: [_gold, _bronze],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
          const Rect.fromLTWH(22, 66, 56, 30)));
  c.drawOval(const Rect.fromLTWH(20, 62, 60, 10), _f(_goldDark));
  c.drawOval(const Rect.fromLTWH(26, 64, 48, 6), _f(const Color(0xFFFFE082)));
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(38, 92, 24, 5), const Radius.circular(2)),
      _f(_goldDark));
  _flame(c, const Offset(50, 65), 30, t, 0.3);
}

/// Hoa sen nở.
void drawLotus(Canvas c, {double t = 0}) {
  final open = 1 + 0.04 * math.sin(t * 2 * math.pi);
  // Lá
  c.drawOval(const Rect.fromLTWH(4, 78, 44, 14), _f(const Color(0xFF66BB6A)));
  c.drawOval(const Rect.fromLTWH(52, 80, 44, 13), _f(const Color(0xFF43A047)));
  final base = const Offset(50, 84);
  final edge = _s(const Color(0xFFE57399), 0.7);
  for (final a in [-1.15, -0.7, 0.7, 1.15]) {
    _petal(c, base, 44 * open, 21, a, _f(const Color(0xFFFFB3C9)), edge);
  }
  for (final a in [-0.45, 0.45]) {
    _petal(c, base, 50 * open, 20, a, _f(const Color(0xFFFF8FB1)), edge);
  }
  _petal(c, base, 54 * open, 19, 0, _f(const Color(0xFFFFD1DF)), edge);
  c.drawCircle(const Offset(50, 60), 3.5, _f(const Color(0xFFFFEB3B)));
}

/// Bình hoa.
void drawFlowerVase(Canvas c, {double t = 0}) {
  final sway = math.sin(t * 2 * math.pi) * 1.2;
  final stems = [
    (const Offset(42, 60), Offset(30 + sway, 30), const Color(0xFFFF8FB1)),
    (const Offset(50, 60), Offset(50 + sway, 18), const Color(0xFFFFFFFF)),
    (const Offset(58, 60), Offset(70 + sway, 32), const Color(0xFFFFCA28)),
  ];
  for (final s in stems) {
    c.drawLine(s.$1, s.$2, _s(const Color(0xFF43A047), 1.8));
  }
  for (final s in stems) {
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      c.drawCircle(s.$2 + Offset(math.cos(a), math.sin(a)) * 5, 4.2, _f(s.$3));
    }
    c.drawCircle(s.$2, 3, _f(const Color(0xFFFFA000)));
  }
  final vase = Path()
    ..moveTo(36, 58)
    ..lineTo(64, 58)
    ..quadraticBezierTo(70, 78, 62, 94)
    ..lineTo(38, 94)
    ..quadraticBezierTo(30, 78, 36, 58)
    ..close();
  c.drawPath(
      vase,
      _g(
          const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFF90CAF9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          const Rect.fromLTWH(30, 58, 40, 36)));
  c.drawPath(
      Path()
        ..moveTo(34, 70)
        ..quadraticBezierTo(50, 78, 66, 70),
      _s(const Color(0xFF1E88E5), 1.4));
}

/// Mâm trái cây.
void drawFruitPlate(Canvas c, {double t = 0}) {
  c.drawOval(const Rect.fromLTWH(8, 74, 84, 18), _f(_goldDark));
  c.drawOval(const Rect.fromLTWH(12, 72, 76, 14), _f(const Color(0xFFFFE082)));
  void fruit(Offset p, double r, Color a, Color b) {
    c.drawCircle(
        p,
        r,
        _g(RadialGradient(center: const Alignment(-0.4, -0.4), colors: [a, b]),
            Rect.fromCircle(center: p, radius: r)));
    c.drawCircle(p.translate(-r * 0.35, -r * 0.4), r * 0.2, _f(Colors.white38));
  }

  fruit(const Offset(34, 62), 14, const Color(0xFFFF8A80),
      const Color(0xFFC62828)); // táo
  fruit(const Offset(66, 62), 14, const Color(0xFFFFCC80),
      const Color(0xFFEF6C00)); // cam
  fruit(const Offset(50, 48), 14, const Color(0xFFFFF59D),
      const Color(0xFFF9A825)); // lê
  c.drawLine(const Offset(50, 36), const Offset(52, 31),
      _s(const Color(0xFF5D4037), 1.6));
  _petal(c, const Offset(52, 32), 8, 3, 1.0, _f(const Color(0xFF66BB6A)));
}

/// Bát cơm chay.
void drawRiceBowl(Canvas c, {double t = 0}) {
  // Cơm
  c.drawPath(
      Path()
        ..moveTo(22, 60)
        ..quadraticBezierTo(50, 20, 78, 60)
        ..close(),
      _f(Colors.white));
  for (final p in const [
    Offset(40, 46),
    Offset(52, 40),
    Offset(60, 50),
    Offset(46, 54)
  ]) {
    c.drawOval(Rect.fromCenter(center: p, width: 5, height: 2.4),
        _f(const Color(0xFFE0E0E0)));
  }
  // Bát
  final bowl = Path()
    ..moveTo(16, 58)
    ..lineTo(84, 58)
    ..quadraticBezierTo(80, 92, 50, 92)
    ..quadraticBezierTo(20, 92, 16, 58)
    ..close();
  c.drawPath(
      bowl,
      _g(
          const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFF64B5F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          const Rect.fromLTWH(16, 58, 68, 34)));
  c.drawPath(
      Path()
        ..moveTo(20, 66)
        ..quadraticBezierTo(50, 74, 80, 66),
      _s(const Color(0xFF1E88E5), 1.6));
  // Đũa
  c.drawLine(const Offset(58, 38), const Offset(86, 8),
      _s(const Color(0xFF8D6E63), 2));
  c.drawLine(const Offset(64, 40), const Offset(90, 14),
      _s(const Color(0xFF6D4C41), 2));
}

/// Chuông đồng.
void drawBell(Canvas c, {double t = 0}) {
  final swing = math.sin(t * 2 * math.pi) * 0.08;
  c.drawArc(const Rect.fromLTWH(40, 4, 20, 20), math.pi, math.pi, false,
      _s(_goldDark, 3));
  c.save();
  c.translate(50, 22);
  c.rotate(swing);
  c.translate(-50, -22);
  final bell = Path()
    ..moveTo(40, 26)
    ..quadraticBezierTo(60, 20, 60, 26)
    ..cubicTo(62, 52, 76, 62, 80, 82)
    ..quadraticBezierTo(50, 92, 20, 82)
    ..cubicTo(24, 62, 38, 52, 40, 26)
    ..close();
  c.drawPath(
      bell,
      _g(const LinearGradient(colors: [Color(0xFFFFE082), _gold, _bronze]),
          const Rect.fromLTWH(20, 20, 60, 72)));
  c.drawLine(const Offset(24, 76), const Offset(76, 76), _s(_goldDark, 1.6));
  c.drawLine(const Offset(30, 56), const Offset(70, 56), _s(_goldDark, 1));
  c.drawCircle(const Offset(50, 90), 5, _f(_brown));
  c.restore();
}

/// Hoa đăng hình đài sen, phát sáng.
void drawLantern(Canvas c, {double t = 0}) {
  final glow = 0.6 + 0.4 * math.sin(t * 2 * math.pi);
  c.drawCircle(
      const Offset(50, 50),
      46,
      _g(
          RadialGradient(colors: [
            const Color(0xFFFFB74D).withValues(alpha: 0.55 * glow + 0.2),
            Colors.transparent
          ]),
          Rect.fromCircle(center: const Offset(50, 50), radius: 46)));
  const base = Offset(50, 80);
  final edge = _s(const Color(0xFFE57399), 0.7);
  for (final a in [-1.0, 1.0]) {
    _petal(c, base, 40, 18, a, _f(const Color(0xFFFFB3C9)), edge);
  }
  for (final a in [-0.5, 0.5]) {
    _petal(c, base, 46, 17, a, _f(const Color(0xFFFF8FB1)), edge);
  }
  _petal(c, base, 50, 16, 0, _f(const Color(0xFFFFD1DF)), edge);
  _flame(c, const Offset(50, 76), 22, t, 0.6);
  c.drawOval(const Rect.fromLTWH(24, 78, 52, 10), _f(const Color(0xFF8D6E63)));
}

/// Chuỗi hạt 108 (vẽ rút gọn 27 hạt) có tua.
void drawPrayerBeads(Canvas c, {double t = 0}) {
  const n = 27;
  for (var i = 0; i < n; i++) {
    final a = -math.pi / 2 + i * 2 * math.pi / n;
    final p = Offset(50 + math.cos(a) * 34, 44 + math.sin(a) * 34);
    c.drawCircle(
        p,
        5,
        _g(
            const RadialGradient(
                center: Alignment(-0.4, -0.4),
                colors: [Color(0xFFA1887F), Color(0xFF4E342E)]),
            Rect.fromCircle(center: p, radius: 5)));
  }
  c.drawCircle(const Offset(50, 80), 6, _f(const Color(0xFFB71C1C)));
  c.drawLine(const Offset(50, 86), const Offset(50, 98),
      _s(const Color(0xFFB71C1C), 3));
  c.drawLine(const Offset(46, 86), const Offset(44, 97),
      _s(const Color(0xFFD32F2F), 1.6));
  c.drawLine(const Offset(54, 86), const Offset(56, 97),
      _s(const Color(0xFFD32F2F), 1.6));
}
