import 'package:flutter/material.dart';

typedef SpriteDraw = void Function(Canvas canvas);

/// Hiển thị một sprite vẽ trong hệ toạ độ 100x100, tự co giãn theo [size].
/// Truyền [animation] để repaint theo hoạt ảnh (closure [draw] đọc giá trị t).
class Sprite extends StatelessWidget {
  const Sprite({super.key, required this.draw, this.size = 64, this.animation});

  final SpriteDraw draw;
  final double size;
  final Listenable? animation;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: _SpritePainter(draw, animation),
      ),
    );
  }
}

class _SpritePainter extends CustomPainter {
  _SpritePainter(this.draw, Listenable? repaint) : super(repaint: repaint);

  final SpriteDraw draw;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpritePainter old) => true;
}

/// Đặt một sprite vào hình chữ nhật [r] bên trong một CustomPainter khác.
void placeSprite(Canvas canvas, Rect r, SpriteDraw draw) {
  canvas.save();
  canvas.translate(r.left, r.top);
  canvas.scale(r.width / 100, r.height / 100);
  draw(canvas);
  canvas.restore();
}
