import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/app_models.dart';
import '../services/chua_api.dart';

enum SessionState { loading, needsOnboarding, ready }

/// Trạng thái toàn cục: phiên đăng nhập, hồ sơ, nhiệm vụ, chùa đang chọn
/// và bộ đệm gõ mõ (gom nhiều lần gõ thành một request đồng bộ).
class AppController extends ChangeNotifier {
  AppController(this.api);

  static const _flushDelay = Duration(seconds: 2);
  static const _maxTapsPerSync = 10000;

  final ChuaApi api;

  SessionState _state = SessionState.loading;
  UserProfile? _me;
  List<Quest> _quests = const [];
  List<Temple> _temples = const [];
  List<OfferingItem> _catalog = const [];
  Temple? _selectedTemple;

  int _pendingTaps = 0;
  bool _flushing = false;
  bool _disposed = false;
  Timer? _flushTimer;

  SessionState get state => _state;
  UserProfile? get me => _me;
  List<Quest> get quests => _quests;
  List<Temple> get temples => _temples;
  List<OfferingItem> get catalog => _catalog;
  Temple? get selectedTemple => _selectedTemple;

  Future<void> bootstrap() async {
    if (!api.hasSession) {
      _state = SessionState.needsOnboarding;
      _notify();
      return;
    }
    try {
      await refresh();
      _state = SessionState.ready;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await api.logout();
        _state = SessionState.needsOnboarding;
      } else {
        _state =
            SessionState.ready; // offline: vẫn vào app, dữ liệu sẽ tải lại sau
      }
    }
    _notify();
  }

  Future<void> register(String name) async {
    await api.registerGuest(name);
    await refresh();
    _state = SessionState.ready;
    _notify();
  }

  Future<void> logout() async {
    await flushTaps();
    await api.logout();
    _me = null;
    _quests = const [];
    _selectedTemple = null;
    _state = SessionState.needsOnboarding;
    _notify();
  }

  Future<void> refresh() async {
    final results = await Future.wait([api.me(), api.quests()]);
    _me = _withPending(results[0] as UserProfile);
    _quests = results[1] as List<Quest>;
    _notify();
  }

  Future<void> loadQuests() async {
    _quests = await api.quests();
    _notify();
  }

  Future<void> loadTemples({String? query}) async {
    _temples = await api.temples(query: query);
    _selectedTemple ??= _temples.isEmpty ? null : _temples.first;
    _notify();
  }

  Future<void> loadCatalog() async {
    if (_catalog.isNotEmpty) return;
    _catalog = await api.offeringCatalog();
    _notify();
  }

  void selectTemple(Temple t) {
    _selectedTemple = t;
    _notify();
  }

  Future<void> updateName(String name) async {
    _me = _withPending(await api.updateName(name));
    _notify();
  }

  // ---- Gõ mõ: cộng ngay trên UI, đồng bộ theo lô ----

  void tap() {
    final m = _me;
    if (m == null) return;
    _me = m.copyWith(totalMerit: m.totalMerit + 1);
    _pendingTaps++;
    _flushTimer?.cancel();
    _flushTimer = Timer(_flushDelay, flushTaps);
    _notify();
  }

  Future<void> flushTaps() async {
    _flushTimer?.cancel();
    if (_flushing || _pendingTaps == 0) return;
    _flushing = true;
    final n = math.min(_pendingTaps, _maxTapsPerSync);
    _pendingTaps -= n;
    try {
      final total = await api.syncMerit(n);
      final m = _me;
      if (m != null) _me = m.copyWith(totalMerit: total + _pendingTaps);
    } on ApiException {
      _pendingTaps += n; // giữ lại để thử lại ở lần sau
    } finally {
      _flushing = false;
    }
    if (_pendingTaps > 0) _flushTimer = Timer(_flushDelay, flushTaps);
    _notify();
  }

  // ---- Các hành động có phản hồi công đức ----

  UserProfile _withPending(UserProfile p) =>
      p.copyWith(totalMerit: p.totalMerit + _pendingTaps);

  void _applyTotal(int serverTotal) {
    final m = _me;
    if (m != null) _me = m.copyWith(totalMerit: serverTotal + _pendingTaps);
  }

  Future<int> makeOffering(String item) async {
    final r = await api.makeOffering(item, _selectedTemple?.id);
    _applyTotal(r.totalMerit);
    unawaited(loadQuests().catchError((_) {}));
    _notify();
    return r.merit;
  }

  Future<int> chant(int count) async {
    final r = await api.chant(count);
    _applyTotal(r.totalMerit);
    unawaited(loadQuests().catchError((_) {}));
    _notify();
    return r.merit;
  }

  Future<int> sendPrayer(PrayerKind kind, String content) async {
    final r = await api.createPrayer(
        kind: kind, content: content, templeId: _selectedTemple?.id);
    _applyTotal(r.totalMerit);
    unawaited(loadQuests().catchError((_) {}));
    _notify();
    return r.merit;
  }

  Future<({int streak, int reward})> checkin() async {
    final r = await api.checkin();
    _applyTotal(r.totalMerit);
    final m = _me;
    if (m != null) _me = m.copyWith(checkedInToday: true, streak: r.streak);
    _notify();
    return (streak: r.streak, reward: r.reward);
  }

  Future<int> claimQuest(String id) async {
    final r = await api.claimQuest(id);
    _applyTotal(r.totalMerit);
    await loadQuests();
    return r.reward;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _flushTimer?.cancel();
    super.dispose();
  }
}
