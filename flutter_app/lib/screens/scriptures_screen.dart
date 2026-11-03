import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../data/content.dart';
import '../models/app_models.dart';
import '../widgets/ui_helpers.dart';

class ScripturesScreen extends StatelessWidget {
  const ScripturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tụng kinh')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: scriptures.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final s = scriptures[i];
          return Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Icon(Icons.menu_book_rounded,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(s.title,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(s.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => ScriptureReaderScreen(scripture: s))),
            ),
          );
        },
      ),
    );
  }
}

class ScriptureReaderScreen extends StatefulWidget {
  const ScriptureReaderScreen({super.key, required this.scripture});
  final Scripture scripture;

  @override
  State<ScriptureReaderScreen> createState() => _ScriptureReaderScreenState();
}

class _ScriptureReaderScreenState extends State<ScriptureReaderScreen> {
  static const _readMerit = 27; // số công đức khi hoàn thành một lần tụng

  final _scroll = ScrollController();
  double _fontSize = 20;
  bool _autoScroll = false;
  bool _busy = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _setAuto(bool on) {
    _timer?.cancel();
    if (on) {
      _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (!_scroll.hasClients) return;
        final max = _scroll.position.maxScrollExtent;
        if (_scroll.offset >= max) {
          _setAuto(false);
          return;
        }
        _scroll.jumpTo((_scroll.offset + 0.6).clamp(0, max));
      });
    }
    setState(() => _autoScroll = on);
  }

  Future<void> _finish() async {
    final app = AppScope.read(context);
    setState(() => _busy = true);
    final merit = await guarded(context, () => app.chant(_readMerit));
    if (!mounted) return;
    setState(() => _busy = false);
    if (merit != null)
      showMeritSnack(
          context, merit, 'Hoàn thành tụng ${widget.scripture.title}');
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scripture;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.title),
        actions: [
          IconButton(
            tooltip: _autoScroll ? 'Dừng cuộn' : 'Tự cuộn',
            icon: Icon(_autoScroll
                ? Icons.pause_circle_rounded
                : Icons.play_circle_rounded),
            onPressed: () => _setAuto(!_autoScroll),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Text(s.body,
                  style: TextStyle(fontSize: _fontSize, height: 1.8)),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.text_fields_rounded, size: 20),
                  Expanded(
                    child: Slider(
                      min: 16,
                      max: 34,
                      value: _fontSize,
                      onChanged: (v) => setState(() => _fontSize = v),
                    ),
                  ),
                  FilledButton(
                    onPressed: _busy ? null : _finish,
                    child: Text(_busy ? '...' : 'Hoàn thành'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
