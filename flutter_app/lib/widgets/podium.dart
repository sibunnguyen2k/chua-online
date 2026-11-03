import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/leaderboard_models.dart';
import 'merit_format.dart';
import 'user_avatar.dart';

class _MedalStyle {
  const _MedalStyle(this.colors, this.glow);
  final List<Color> colors;
  final Color glow;
}

const _medals = <int, _MedalStyle>{
  1: _MedalStyle([Color(0xFFFFE082), Color(0xFFFFB300), Color(0xFFFF8F00)],
      Color(0xFFFFC107)),
  2: _MedalStyle([Color(0xFFF5F5F5), Color(0xFFB0BEC5), Color(0xFF78909C)],
      Color(0xFFB0BEC5)),
  3: _MedalStyle([Color(0xFFFFCCBC), Color(0xFFCD7F32), Color(0xFF8D5524)],
      Color(0xFFCD7F32)),
};

/// Top 3: hạng 1 ở giữa và lớn nhất, hạng 2 bên trái, hạng 3 bên phải.
/// Một AnimationController duy nhất dùng chung cho cả 3 huy chương.
class Podium extends StatefulWidget {
  const Podium({super.key, required this.top});

  final List<LeaderboardEntry> top; // 1..3 phần tử, đã sắp theo hạng

  @override
  State<Podium> createState() => _PodiumState();
}

class _PodiumState extends State<Podium> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  LeaderboardEntry? _at(int rank) {
    for (final e in widget.top) {
      if (e.rank == rank) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final first = _at(1);
    final second = _at(2);
    final third = _at(3);

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
                child: second == null
                    ? const SizedBox()
                    : _Slot(entry: second, avatar: 68, anim: _anim)),
            Expanded(
              child: first == null
                  ? const SizedBox()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _Slot(entry: first, avatar: 92, anim: _anim),
                    ),
            ),
            Expanded(
                child: third == null
                    ? const SizedBox()
                    : _Slot(entry: third, avatar: 68, anim: _anim)),
          ],
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.entry, required this.avatar, required this.anim});

  final LeaderboardEntry entry;
  final double avatar;
  final Animation<double> anim;

  @override
  Widget build(BuildContext context) {
    final style = _medals[entry.rank]!;
    final theme = Theme.of(context);
    final badge = entry.rank == 1 ? 36.0 : 30.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (entry.rank == 1)
          Icon(Icons.emoji_events_rounded, color: style.glow, size: 28),
        SizedBox(
          width: avatar + 12,
          height: avatar + badge / 2 + 6,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: anim,
                builder: (_, child) {
                  final pulse = 0.35 +
                      0.35 * (0.5 + 0.5 * math.sin(anim.value * 2 * math.pi));
                  return Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: style.colors),
                      boxShadow: [
                        BoxShadow(
                          color: style.glow.withValues(alpha: pulse),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: UserAvatar(
                    name: entry.name, url: entry.avatarUrl, size: avatar),
              ),
              Positioned(
                bottom: 0,
                child: _SparklingMedal(
                    rank: entry.rank, size: badge, style: style, anim: anim),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          '${formatMerit(entry.score)} công đức',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SparklingMedal extends StatelessWidget {
  const _SparklingMedal({
    required this.rank,
    required this.size,
    required this.style,
    required this.anim,
  });

  final int rank;
  final double size;
  final _MedalStyle style;
  final Animation<double> anim;

  @override
  Widget build(BuildContext context) {
    final base = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.colors,
        ),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          fontSize: size * 0.48,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black38, blurRadius: 2)],
        ),
      ),
    );

    // Vệt sáng quét ngang qua huy chương tạo hiệu ứng lấp lánh.
    return AnimatedBuilder(
      animation: anim,
      child: base,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: const [
            Color(0x00FFFFFF),
            Color(0xCCFFFFFF),
            Color(0x00FFFFFF)
          ],
          stops: const [0.35, 0.5, 0.65],
          transform: _SlideTransform(anim.value),
        ).createShader(bounds),
        child: child,
      ),
    );
  }
}

class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.t);
  final double t;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // t: 0 -> 1 đưa vệt sáng từ ngoài trái sang ngoài phải.
    return Matrix4.translationValues(bounds.width * (t * 2 - 1) * 1.2, 0, 0);
  }
}
