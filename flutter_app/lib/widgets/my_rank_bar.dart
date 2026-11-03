import 'package:flutter/material.dart';

import '../models/leaderboard_models.dart';
import 'merit_format.dart';
import 'user_avatar.dart';

/// Thanh cố định đáy màn hình: thứ hạng vĩnh viễn của chính người dùng.
class MyRankBar extends StatelessWidget {
  const MyRankBar({super.key, required this.me});

  final LeaderboardEntry? me;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final m = me;

    return Material(
      elevation: 12,
      color: scheme.primaryContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: m == null
              ? SizedBox(
                  height: 44,
                  child: Center(
                    child: Text(
                      'Hãy gõ mõ để tích công đức và lên bảng xếp hạng!',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              : Row(
                  children: [
                    UserAvatar(name: m.name, url: m.avatarUrl, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            m.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${formatMerit(m.score)} công đức',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Hạng', style: theme.textTheme.labelSmall),
                        Text(
                          '#${formatMerit(m.rank)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
