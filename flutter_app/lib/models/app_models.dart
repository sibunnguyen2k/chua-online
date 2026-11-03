import 'package:flutter/material.dart';

class LevelTier {
  const LevelTier(this.name, this.min);
  final String name;
  final int min;
}

class LevelInfo {
  const LevelInfo({
    required this.index,
    required this.name,
    required this.nextName,
    required this.nextAt,
    required this.progress,
    required this.all,
  });

  final int index;
  final String name;
  final String? nextName;
  final int? nextAt;
  final double progress;
  final List<LevelTier> all;

  factory LevelInfo.fromJson(Map<String, dynamic> j) => LevelInfo(
        index: (j['index'] as num).toInt(),
        name: j['name'] as String,
        nextName: j['nextName'] as String?,
        nextAt: (j['nextAt'] as num?)?.toInt(),
        progress: (j['progress'] as num).toDouble(),
        all: [
          for (final t in j['all'] as List<dynamic>)
            LevelTier((t as Map<String, dynamic>)['name'] as String,
                (t['min'] as num).toInt()),
        ],
      );
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.totalMerit,
    required this.rank,
    required this.streak,
    required this.checkedInToday,
    required this.claimableQuests,
    required this.level,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final int totalMerit;
  final int? rank;
  final int streak;
  final bool checkedInToday;
  final int claimableQuests;
  final LevelInfo level;

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        avatarUrl: j['avatarUrl'] as String?,
        totalMerit: (j['totalMerit'] as num).toInt(),
        rank: (j['rank'] as num?)?.toInt(),
        streak: (j['streak'] as num).toInt(),
        checkedInToday: j['checkedInToday'] as bool,
        claimableQuests: (j['claimableQuests'] as num).toInt(),
        level: LevelInfo.fromJson(j['level'] as Map<String, dynamic>),
      );

  UserProfile copyWith({int? totalMerit, bool? checkedInToday, int? streak}) =>
      UserProfile(
        id: id,
        name: name,
        avatarUrl: avatarUrl,
        totalMerit: totalMerit ?? this.totalMerit,
        rank: rank,
        streak: streak ?? this.streak,
        checkedInToday: checkedInToday ?? this.checkedInToday,
        claimableQuests: claimableQuests,
        level: level,
      );
}

class Quest {
  const Quest({
    required this.id,
    required this.title,
    required this.target,
    required this.reward,
    required this.progress,
    required this.claimed,
    required this.claimable,
  });

  final String id;
  final String title;
  final int target;
  final int reward;
  final int progress;
  final bool claimed;
  final bool claimable;

  factory Quest.fromJson(Map<String, dynamic> j) => Quest(
        id: j['id'] as String,
        title: j['title'] as String,
        target: (j['target'] as num).toInt(),
        reward: (j['reward'] as num).toInt(),
        progress: (j['progress'] as num).toInt(),
        claimed: j['claimed'] as bool,
        claimable: j['claimable'] as bool,
      );
}

class Temple {
  const Temple({
    required this.id,
    required this.name,
    required this.province,
    required this.description,
    required this.imageUrl,
  });

  final int id;
  final String name;
  final String province;
  final String description;
  final String? imageUrl;

  factory Temple.fromJson(Map<String, dynamic> j) => Temple(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        province: j['province'] as String,
        description: j['description'] as String,
        imageUrl: j['imageUrl'] as String?,
      );
}

class OfferingItem {
  const OfferingItem({
    required this.id,
    required this.label,
    required this.merit,
    required this.dailyLimit,
  });

  final String id;
  final String label;
  final int merit;
  final int dailyLimit;

  factory OfferingItem.fromJson(Map<String, dynamic> j) => OfferingItem(
        id: j['id'] as String,
        label: j['label'] as String,
        merit: (j['merit'] as num).toInt(),
        dailyLimit: (j['dailyLimit'] as num).toInt(),
      );

  IconData get icon => switch (id) {
        'incense' => Icons.local_fire_department_rounded,
        'flower' => Icons.local_florist_rounded,
        'lamp' => Icons.light_rounded,
        'fruit' => Icons.apple_rounded,
        'meal' => Icons.rice_bowl_rounded,
        _ => Icons.favorite_rounded,
      };
}

enum PrayerKind {
  cauAn('cau_an', 'Cầu an', Icons.health_and_safety_rounded),
  cauSieu('cau_sieu', 'Cầu siêu', Icons.spa_rounded),
  samHoi('sam_hoi', 'Sám hối', Icons.self_improvement_rounded),
  cauDuyen('cau_duyen', 'Cầu duyên', Icons.favorite_rounded),
  cauTai('cau_tai', 'Cầu tài lộc', Icons.paid_rounded);

  const PrayerKind(this.wire, this.label, this.icon);
  final String wire;
  final String label;
  final IconData icon;

  static PrayerKind fromWire(String s) => PrayerKind.values
      .firstWhere((k) => k.wire == s, orElse: () => PrayerKind.cauAn);
}

class Prayer {
  const Prayer({
    required this.id,
    required this.kind,
    required this.content,
    required this.templeName,
    required this.createdAt,
  });

  final String id;
  final PrayerKind kind;
  final String content;
  final String? templeName;
  final DateTime createdAt;

  factory Prayer.fromJson(Map<String, dynamic> j) => Prayer(
        id: j['id'] as String,
        kind: PrayerKind.fromWire(j['kind'] as String),
        content: j['content'] as String,
        templeName: j['templeName'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
      );
}

class PrayerPage {
  const PrayerPage(this.items, this.nextCursor);
  final List<Prayer> items;
  final String? nextCursor;
}

class Scripture {
  const Scripture(
      {required this.title, required this.subtitle, required this.body});
  final String title;
  final String subtitle;
  final String body;
}
