import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../models/app_models.dart';
import '../widgets/sprites/sprite.dart';
import '../widgets/sprites/sprites.dart';
import '../widgets/ui_helpers.dart';
import 'temples_screen.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  final _text = TextEditingController();
  final List<Prayer> _history = [];
  PrayerKind _kind = PrayerKind.cauAn;
  String? _cursor;
  bool _sending = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    if (app.temples.isEmpty) app.loadTemples().catchError((_) {});
    _load(reset: true);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    final app = AppScope.read(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await app.api.prayers(before: reset ? null : _cursor);
      if (!mounted) return;
      setState(() {
        if (reset) _history.clear();
        _history.addAll(page.items);
        _cursor = page.nextCursor;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Không tải được lịch sử.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final content = _text.text.trim();
    if (content.isEmpty) return;
    final app = AppScope.read(context);
    setState(() => _sending = true);
    final merit = await guarded(context, () => app.sendPrayer(_kind, content));
    if (!mounted) return;
    setState(() => _sending = false);
    if (merit == null) return;
    _text.clear();
    await showDialog<void>(
        context: context, builder: (_) => _LanternDialog(merit: merit));
    if (mounted) _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cầu nguyện & Sám hối')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final k in PrayerKind.values)
                ChoiceChip(
                  avatar: Icon(k.icon, size: 18),
                  label: Text(k.label),
                  selected: k == _kind,
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TempleChip(
              name: app.selectedTemple?.name,
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const TemplesScreen(pickMode: true))),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            maxLength: 300,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Con xin thành tâm khấn nguyện...',
              border: OutlineInputBorder(),
            ),
          ),
          FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: const Icon(Icons.local_florist_rounded),
            label: Text(_sending ? 'Đang gửi...' : 'Thả đèn hoa đăng'),
          ),
          const SectionTitle('Lời nguyện của tôi'),
          if (_history.isEmpty && !_loading)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                  child: Text(_error ?? 'Bạn chưa gửi lời nguyện nào.',
                      style: theme.textTheme.bodyMedium)),
            ),
          for (final p in _history)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: Icon(p.kind.icon, color: theme.colorScheme.primary),
                  title: Text(p.content),
                  subtitle: Text(
                      '${p.kind.label}${p.templeName != null ? ' • ${p.templeName}' : ''} • ${_fmt(p.createdAt)}'),
                ),
              ),
            ),
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator())),
          if (!_loading && _cursor != null)
            TextButton(onPressed: () => _load(), child: const Text('Xem thêm')),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _LanternDialog extends StatelessWidget {
  const _LanternDialog({required this.merit});
  final int merit;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1B1030),
      child: SizedBox(
        height: 340,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 3),
              curve: Curves.easeOut,
              builder: (_, t, __) => Positioned(
                bottom: 60 + 180 * t,
                child: Opacity(
                  opacity: 1 - 0.5 * t,
                  child: Sprite(draw: (c) => drawLantern(c, t: t), size: 110),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              child: Column(
                children: [
                  Text('+$merit công đức',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                  const SizedBox(height: 4),
                  const Text('Lời nguyện đã được gửi đi 🙏',
                      style: TextStyle(color: Colors.white70)),
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Đóng')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
