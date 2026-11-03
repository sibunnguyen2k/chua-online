import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../widgets/merit_format.dart';
import '../widgets/sprites/sprite.dart';
import '../widgets/sprites/sprites.dart';
import '../widgets/ui_helpers.dart';
import '../widgets/user_avatar.dart';
import 'quests_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    app.flushTaps().then((_) => app.refresh()).catchError((_) {});
  }

  Future<void> _editName() async {
    final app = AppScope.read(context);
    final ctrl = TextEditingController(text: app.me?.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi pháp danh'),
        content: TextField(controller: ctrl, maxLength: 40, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Lưu')),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    await guarded(context, () => app.updateName(name));
  }

  Future<void> _logout() async {
    final app = AppScope.read(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text(
            'Tài khoản khách sẽ không thể khôi phục sau khi đăng xuất.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (ok == true) await app.logout();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final me = app.me;
    final theme = Theme.of(context);
    if (me == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá nhân'),
        actions: [
          IconButton(
              tooltip: 'Đăng xuất',
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded))
        ],
      ),
      body: RefreshIndicator(
        onRefresh: app.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
                child: UserAvatar(name: me.name, url: me.avatarUrl, size: 96)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                    child: Text(me.name,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900))),
                IconButton(
                    onPressed: _editName,
                    icon: const Icon(Icons.edit_rounded, size: 20)),
              ],
            ),
            Center(child: Chip(label: Text('Phẩm vị: ${me.level.name}'))),
            const SizedBox(height: 12),
            Row(
              children: [
                _Stat(label: 'Công đức', value: formatMerit(me.totalMerit)),
                const SizedBox(width: 10),
                _Stat(
                    label: 'Thứ hạng',
                    value: me.rank == null ? '—' : '#${formatMerit(me.rank!)}'),
                const SizedBox(width: 10),
                _Stat(label: 'Chuỗi ngày', value: '${me.streak}'),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.task_alt_rounded),
                title: const Text('Nhiệm vụ & Điểm danh'),
                subtitle: me.claimableQuests > 0
                    ? Text('${me.claimableQuests} phần thưởng đang chờ')
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const QuestsScreen())),
              ),
            ),
            const SectionTitle('Thành tựu phẩm vị'),
            for (var i = 0; i < me.level.all.length; i++)
              _TierTile(
                name: me.level.all[i].name,
                min: me.level.all[i].min,
                unlocked: i <= me.level.index,
                current: i == me.level.index,
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              FittedBox(
                  child: Text(value,
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary))),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierTile extends StatelessWidget {
  const _TierTile(
      {required this.name,
      required this.min,
      required this.unlocked,
      required this.current});
  final String name;
  final int min;
  final bool unlocked, current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: current ? scheme.primaryContainer : null,
        child: ListTile(
          leading: unlocked
              ? Sprite(draw: (c) => drawLotus(c), size: 40)
              : Icon(Icons.lock_outline_rounded,
                  color: scheme.outline, size: 30),
          title: Text(name,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: unlocked ? null : scheme.outline)),
          subtitle: Text('Từ ${formatMerit(min)} công đức'),
          trailing: current ? const Text('Hiện tại') : null,
        ),
      ),
    );
  }
}
