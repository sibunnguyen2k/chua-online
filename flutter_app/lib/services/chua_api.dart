import '../core/api_client.dart';
import '../models/app_models.dart';

/// Lớp truy cập API có kiểu cho toàn bộ chức năng của ứng dụng.
class ChuaApi {
  ChuaApi(this.client);
  final ApiClient client;

  bool get hasSession => client.hasToken;

  Future<void> registerGuest(String name) async {
    final r = await client.post('/auth/guest',
        body: {'displayName': name}, auth: false);
    await client.tokens.save(r['token'] as String);
  }

  Future<void> logout() => client.tokens.clear();

  Future<UserProfile> me() async =>
      UserProfile.fromJson(await client.get('/me'));

  Future<UserProfile> updateName(String name) async => UserProfile.fromJson(
      await client.patch('/me', body: {'displayName': name}));

  /// Trả về tổng công đức mới sau khi đồng bộ [taps] lần gõ mõ.
  Future<int> syncMerit(int taps) async =>
      ((await client.post('/merit/sync', body: {'taps': taps}))['totalMerit']
              as num)
          .toInt();

  Future<({int streak, int reward, int totalMerit})> checkin() async {
    final r = await client.post('/checkin');
    return (
      streak: (r['streak'] as num).toInt(),
      reward: (r['reward'] as num).toInt(),
      totalMerit: (r['totalMerit'] as num).toInt(),
    );
  }

  Future<List<Quest>> quests() async => [
        for (final q in (await client.get('/quests'))['items'] as List<dynamic>)
          Quest.fromJson(q as Map<String, dynamic>),
      ];

  Future<({int reward, int totalMerit})> claimQuest(String id) async {
    final r = await client.post('/quests/$id/claim');
    return (
      reward: (r['reward'] as num).toInt(),
      totalMerit: (r['totalMerit'] as num).toInt()
    );
  }

  Future<List<Temple>> temples({String? query}) async => [
        for (final t in (await client.get('/temples', query: {
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        }))['items'] as List<dynamic>)
          Temple.fromJson(t as Map<String, dynamic>),
      ];

  Future<List<OfferingItem>> offeringCatalog() async => [
        for (final o in (await client.get('/offerings/catalog'))['items']
            as List<dynamic>)
          OfferingItem.fromJson(o as Map<String, dynamic>),
      ];

  Future<({int merit, int totalMerit})> makeOffering(
      String item, int? templeId) async {
    final r = await client
        .post('/offerings', body: {'item': item, 'templeId': templeId});
    return (
      merit: (r['merit'] as num).toInt(),
      totalMerit: (r['totalMerit'] as num).toInt()
    );
  }

  Future<({int merit, int totalMerit})> chant(int count) async {
    final r = await client.post('/chant', body: {'count': count});
    return (
      merit: (r['merit'] as num).toInt(),
      totalMerit: (r['totalMerit'] as num).toInt()
    );
  }

  Future<({Prayer prayer, int merit, int totalMerit})> createPrayer({
    required PrayerKind kind,
    required String content,
    int? templeId,
  }) async {
    final r = await client.post('/prayers', body: {
      'kind': kind.wire,
      'content': content,
      'templeId': templeId,
    });
    final p = r['prayer'] as Map<String, dynamic>;
    return (
      prayer: Prayer.fromJson({...p, 'templeName': null}),
      merit: (r['merit'] as num).toInt(),
      totalMerit: (r['totalMerit'] as num).toInt(),
    );
  }

  Future<PrayerPage> prayers({String? before, int limit = 20}) async {
    final r = await client.get('/prayers', query: {
      'limit': '$limit',
      if (before != null) 'before': before,
    });
    return PrayerPage(
      [
        for (final p in r['items'] as List<dynamic>)
          Prayer.fromJson(p as Map<String, dynamic>)
      ],
      r['nextCursor'] as String?,
    );
  }
}
