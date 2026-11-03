import 'package:flutter/material.dart';

import '../models/leaderboard_models.dart';
import 'merit_format.dart';
import 'user_avatar.dart';

class LeaderboardTile extends StatelessWidget {
  const LeaderboardTile(
      {super.key, required this.entry, this.highlight = false});

  final LeaderboardEntry entry;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              '#${entry.rank}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          UserAvatar(name: entry.name, url: entry.avatarUrl, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatMerit(entry.score),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
