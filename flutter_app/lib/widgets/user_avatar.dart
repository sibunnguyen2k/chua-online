import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    required this.url,
    required this.size,
  });

  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial =
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: scheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );

    final u = url;
    if (u == null || u.isEmpty) return ClipOval(child: fallback);

    // cacheWidth: giải mã ảnh đúng kích thước hiển thị để tiết kiệm RAM.
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipOval(
      child: Image.network(
        u,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: px,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}
