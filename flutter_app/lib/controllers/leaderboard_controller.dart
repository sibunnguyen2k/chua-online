import 'package:flutter/foundation.dart';

import '../models/leaderboard_models.dart';
import '../core/api_client.dart';
import '../services/leaderboard_api.dart';

class LeaderboardController extends ChangeNotifier {
  LeaderboardController(this._api);

  static const int pageSize = 20;

  final LeaderboardApi _api;

  final List<LeaderboardEntry> _items = [];
  final Set<String> _seenIds = {};
  LeaderboardEntry? _me;

  int _nextPage = 1;
  int _generation = 0; // vô hiệu hoá response cũ khi refresh giữa chừng
  bool _hasMore = true;
  bool _loading = false;
  bool _disposed = false;
  String? _error;

  List<LeaderboardEntry> get items => _items;
  LeaderboardEntry? get me => _me;
  bool get hasMore => _hasMore;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isInitialLoading => _loading && _items.isEmpty;

  Future<void> refresh() => _fetch(reset: true);

  Future<void> loadMore() {
    if (_loading || !_hasMore) return Future.value();
    return _fetch(reset: false);
  }

  Future<void> _fetch({required bool reset}) async {
    final gen = reset ? ++_generation : _generation;
    _loading = true;
    _error = null;
    _notify();

    try {
      final page = await _api.fetchPage(
        page: reset ? 1 : _nextPage,
        limit: pageSize,
      );
      if (gen != _generation || _disposed) return;

      if (reset) {
        _items.clear();
        _seenIds.clear();
      }
      // Điểm thay đổi liên tục nên xếp hạng có thể dịch chuyển giữa các trang:
      // lọc trùng theo userId để không hiển thị một người hai lần.
      for (final e in page.items) {
        if (_seenIds.add(e.userId)) _items.add(e);
      }
      _nextPage = page.page + 1;
      _hasMore = page.hasMore;
      _me = page.me ?? _me;
    } on ApiException catch (e) {
      if (gen == _generation) _error = e.message;
    } catch (_) {
      if (gen == _generation) _error = 'Đã xảy ra lỗi không xác định.';
    } finally {
      if (gen == _generation) {
        _loading = false;
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
