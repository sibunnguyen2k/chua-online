import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../widgets/ui_helpers.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  String? _claiming;
  bool _checkingIn = false;

  @override
  void initState() {
    super.initState();
    AppScope.read(context).loadQuests().catchError((_) {});
  }

  Future<void> _claim(String id) async {
    final app = AppScope.read(context);
    setState(() => _claiming = id);
    final reward = await guarded(context, () => app.claimQuest(id));
    if (!mounted) return;
    setState(() => _claiming = null);
    if (reward != null) showMeritSnack(context, reward, 'Nhận thưởng nhiệm vụ');
  }

  Future<void> _checkin() async {
    final app = AppScope.read(context);
    setState(() => _checkingIn = true);
    final r = await guarded(context, app.checkin);
    if (!mounted) return;
    setState(() => _checkingIn = false);
    if (r != null)
      showMeritSnack(context, r.reward, 'Điểm danh ngày thứ ${r.streak}');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final me = app.me;
    final theme = Theme.of(context);
    final streak = me?.streak ?? 0;
    final done = me?.checkedInToday ?? false;
    // Vòng 7 ngày: hiển thị vị trí của chuỗi hiện tại trong tuần.
    final lit = streak == 0 ? 0 : ((streak - 1) % 7) + 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Nhiệm vụ & Điểm danh')),
      body: RefreshIndicator(
        onRefresh: app.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chuỗi $streak ngày liên tiếp',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 1; i <= 7; i++)
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: i <= lit
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            child: i <= lit
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 20)
                                : Text('$i',
                                    style: theme.textTheme.labelMedium),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (done || _checkingIn) ? null : _checkin,
                        child: Text(done
                            ? 'Đã điểm danh hôm nay'
                            : 'Điểm danh nhận công đức'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SectionTitle('Nhiệm vụ hôm nay'),
            if (app.quests.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator())),
            for (final q in app.quests)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(q.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value:
                                    q.target == 0 ? 0 : q.progress / q.target,
                                minHeight: 7,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  '${q.progress}/${q.target} • thưởng +${q.reward}',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (q.claimed)
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.green)
                        else
                          FilledButton.tonal(
                            onPressed: q.claimable && _claiming == null
                                ? () => _claim(q.id)
                                : null,
                            child: Text(_claiming == q.id ? '...' : 'Nhận'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
