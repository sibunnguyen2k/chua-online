import '../core/api_client.dart';
import '../models/leaderboard_models.dart';

class LeaderboardApi {
  LeaderboardApi(this._client);

  final ApiClient _client;

  Future<LeaderboardPage> fetchPage(
      {required int page, required int limit}) async {
    final json = await _client
        .get('/leaderboard', query: {'page': '$page', 'limit': '$limit'});
    return LeaderboardPage.fromJson(json);
  }
}
