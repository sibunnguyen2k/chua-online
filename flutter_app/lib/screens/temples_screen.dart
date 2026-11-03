import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../widgets/sprites/sprite.dart';
import '../widgets/sprites/sprites.dart';
import '../widgets/ui_helpers.dart';

/// Danh sách chùa. Ở [pickMode], chạm vào chùa sẽ chọn và quay lại.
class TemplesScreen extends StatefulWidget {
  const TemplesScreen({super.key, this.pickMode = false});

  final bool pickMode;

  @override
  State<TemplesScreen> createState() => _TemplesScreenState();
}

class _TemplesScreenState extends State<TemplesScreen> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    AppScope.read(context).loadTemples().catchError((_) {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    final app = AppScope.read(context);
    _debounce = Timer(const Duration(milliseconds: 400),
        () => app.loadTemples(query: q).catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.pickMode ? 'Chọn chùa' : 'Chùa')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SearchBar(
              hintText: 'Tìm theo tên chùa hoặc tỉnh thành',
              leading: const Icon(Icons.search),
              onChanged: _onQuery,
              elevation: const WidgetStatePropertyAll(0),
            ),
          ),
          Expanded(
            child: app.temples.isEmpty
                ? const Center(child: Text('Không tìm thấy chùa nào.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: app.temples.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final t = app.temples[i];
                      final selected = app.selectedTemple?.id == t.id;
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            app.selectTemple(t);
                            if (widget.pickMode) {
                              Navigator.of(context).pop();
                            } else {
                              showSnack(
                                  context, 'Đã chọn ${t.name} làm nơi dâng lễ');
                            }
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 92,
                                height: 92,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Color(0xFFB8860B),
                                    Color(0xFF7B1E1E)
                                  ]),
                                ),
                                child: t.imageUrl == null
                                    ? Sprite(
                                        draw: (c) => drawBuddha(c), size: 70)
                                    : Image.network(t.imageUrl!,
                                        fit: BoxFit.cover,
                                        cacheWidth: 276,
                                        errorBuilder: (_, __, ___) => Sprite(
                                            draw: (c) => drawBuddha(c),
                                            size: 70)),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(t.name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w800)),
                                      Text(t.province,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                  color: theme
                                                      .colorScheme.primary)),
                                      const SizedBox(height: 4),
                                      Text(t.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall),
                                    ],
                                  ),
                                ),
                              ),
                              if (selected)
                                const Padding(
                                    padding: EdgeInsets.only(right: 12),
                                    child: Icon(Icons.check_circle_rounded,
                                        color: Colors.green)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
