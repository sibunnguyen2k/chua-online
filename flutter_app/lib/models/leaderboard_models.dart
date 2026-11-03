class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.score,
  });

  final int rank;
  final String userId;
  final String name;
  final String? avatarUrl;
  final int score;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num).toInt(),
      userId: json['userId'] as String,
      name: json['name'] as String? ?? 'Phật tử ẩn danh',
      avatarUrl: json['avatarUrl'] as String?,
      score: (json['score'] as num).toInt(),
    );
  }
}

class LeaderboardPage {
  const LeaderboardPage({
    required this.page,
    required this.hasMore,
    required this.items,
    required this.me,
  });

  final int page;
  final bool hasMore;
  final List<LeaderboardEntry> items;

  /// Null nếu user chưa có điểm nào trên bảng xếp hạng.
  final LeaderboardEntry? me;

  factory LeaderboardPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>;
    final rawMe = json['me'] as Map<String, dynamic>?;
    return LeaderboardPage(
      page: (json['page'] as num).toInt(),
      hasMore: json['hasMore'] as bool,
      items: List<LeaderboardEntry>.unmodifiable(
        rawItems
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)),
      ),
      me: rawMe == null ? null : LeaderboardEntry.fromJson(rawMe),
    );
  }
}
