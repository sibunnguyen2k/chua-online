import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/lunar.dart';
import '../data/content.dart';
import '../widgets/merit_format.dart';
import '../widgets/sprites/sprite.dart';
import '../widgets/sprites/sprites.dart';
import '../widgets/ui_helpers.dart';
import 'chant_screen.dart';
import 'prayer_screen.dart';
import 'quests_screen.dart';
import 'scriptures_screen.dart';
import 'temples_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onSelectTab});

  final ValueChanged<int> onSelectTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    app.loadTemples().catchError((_) {});
  }

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final me = app.me;
    if (me == null) return const Center(child: CircularProgressIndicator());

    final actions = <_Action>[
      _Action('Gõ mõ', (c) => drawWoodenFish(c), () => widget.onSelectTab(1)),
      _Action('Thắp hương', (c) => drawIncenseBurner(c, sticks: 3),
          () => widget.onSelectTab(2)),
      _Action('Niệm Phật', (c) => drawPrayerBeads(c),
          () => _push(const ChantScreen())),
      _Action('Tụng kinh', (c) => drawBell(c),
          () => _push(const ScripturesScreen())),
      _Action('Cầu nguyện', (c) => drawLantern(c),
          () => _push(const PrayerScreen())),
      _Action('Chùa', (c) => drawBuddha(c), () => _push(const TemplesScreen())),
    ];

    final quote = buddhistQuotes[
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays %
            buddhistQuotes.length];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: app.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _Greeting(
                name: me.name,
                levelName: me.level.name,
                merit: me.totalMerit,
                rank: me.rank,
                progress: me.level.progress,
                nextName: me.level.nextName,
                nextAt: me.level.nextAt),
            const SizedBox(height: 12),
            const _LunarCard(),
            const SizedBox(height: 12),
            _CheckinCard(onOpenQuests: () => _push(const QuestsScreen())),
            const SectionTitle('Tu tập hằng ngày'),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: [for (final a in actions) _ActionTile(action: a)],
            ),
            SectionTitle(
              'Nhiệm vụ hôm nay',
              trailing: TextButton(
                onPressed: () => _push(const QuestsScreen()),
                child: Text(me.claimableQuests > 0
                    ? 'Nhận thưởng (${me.claimableQuests})'
                    : 'Xem tất cả'),
              ),
            ),
            for (final q in app.quests.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    title: Text(q.title),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: LinearProgressIndicator(
                          value: q.target == 0 ? 0 : q.progress / q.target,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                    trailing: Text(q.claimed ? 'Đã nhận' : '+${q.reward}'),
                  ),
                ),
              ),
            const SectionTitle('Lời Phật dạy hôm nay'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text('“$quote”',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontStyle: FontStyle.italic, height: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action {
  const _Action(this.label, this.draw, this.onTap);
  final String label;
  final SpriteDraw draw;
  final VoidCallback onTap;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});
  final _Action action;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: action.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Sprite(draw: action.draw, size: 46),
            const SizedBox(height: 6),
            Text(action.label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.name,
    required this.levelName,
    required this.merit,
    required this.rank,
    required this.progress,
    required this.nextName,
    required this.nextAt,
  });

  final String name, levelName;
  final String? nextName;
  final int merit;
  final int? rank;
  final int? nextAt;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
            colors: [Color(0xFF8B1A1A), Color(0xFFB8860B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      child: Stack(
        children: [
          Positioned(
              right: -4,
              top: -6,
              child: Sprite(
                  draw: (c) => drawMonk(c, pose: MonkPose.praying), size: 84)),
          DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('A Di Đà Phật 🙏'),
                Text(name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Phẩm vị: $levelName'),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatMerit(merit),
                        style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('công đức')),
                    const Spacer(),
                    if (rank != null)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('Hạng #${formatMerit(rank!)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700))),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      color: Colors.amberAccent),
                ),
                const SizedBox(height: 6),
                Text(
                    nextName == null
                        ? 'Đã đạt phẩm vị cao nhất'
                        : 'Còn ${formatMerit(nextAt! - merit)} để lên $nextName',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LunarCard extends StatelessWidget {
  const _LunarCard();

  static const _weekdays = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật'
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lunar = LunarDate.fromSolar(now);
    final event = lunar.buddhistEvent;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${now.day}',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  Text('Th.${now.month}', style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_weekdays[now.weekday - 1],
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                      'Âm lịch: ${lunar.day}/${lunar.month}${lunar.isLeap ? ' (nhuận)' : ''} năm ${lunar.yearName}'),
                  if (event != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.celebration_rounded, size: 16),
                        label: Text(event),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckinCard extends StatefulWidget {
  const _CheckinCard({required this.onOpenQuests});
  final VoidCallback onOpenQuests;

  @override
  State<_CheckinCard> createState() => _CheckinCardState();
}

class _CheckinCardState extends State<_CheckinCard> {
  bool _busy = false;

  Future<void> _checkin() async {
    final app = AppScope.read(context);
    setState(() => _busy = true);
    final r = await guarded(context, app.checkin);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r != null)
      showMeritSnack(context, r.reward, 'Điểm danh ngày thứ ${r.streak}');
  }

  @override
  Widget build(BuildContext context) {
    final me = AppScope.of(context).me!;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(Icons.local_fire_department_rounded,
            color: Colors.deepOrange.shade400, size: 34),
        title: Text('Chuỗi ${me.streak} ngày tinh tấn',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(me.checkedInToday
            ? 'Hôm nay bạn đã điểm danh ✓'
            : 'Điểm danh để nhận công đức'),
        trailing: me.checkedInToday
            ? IconButton(
                onPressed: widget.onOpenQuests,
                icon: const Icon(Icons.chevron_right))
            : FilledButton(
                onPressed: _busy ? null : _checkin,
                child: const Text('Điểm danh')),
      ),
    );
  }
}
