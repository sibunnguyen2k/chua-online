import 'package:flutter/material.dart';

import '../controllers/leaderboard_controller.dart';
import '../services/leaderboard_api.dart';
import '../widgets/leaderboard_tile.dart';
import '../widgets/my_rank_bar.dart';
import '../widgets/podium.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.api});

  final LeaderboardApi api;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const double _prefetchExtent = 300; // tải trước khi chạm đáy
  static const int _podiumCount = 3;

  late final LeaderboardController _controller =
      LeaderboardController(widget.api);
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _controller.refresh();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - _prefetchExtent) {
      _controller.loadMore();
    }
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Bảng Xếp Hạng Công Đức'),
            centerTitle: true,
          ),
          body: _buildBody(context),
          bottomNavigationBar: MyRankBar(me: _controller.me),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final c = _controller;

    if (c.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (c.items.isEmpty) {
      return _Message(
        text: c.error ?? 'Chưa có ai trên bảng xếp hạng.',
        onRetry: c.refresh,
      );
    }

    final items = c.items;
    final topCount = items.length < _podiumCount ? items.length : _podiumCount;
    final restCount = items.length - topCount;
    final hasFooter = c.hasMore || c.error != null;

    // index 0: Podium | 1..restCount: danh sách từ hạng 4 | cuối: loader/lỗi
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 1 + restCount + (hasFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) return Podium(top: items.sublist(0, topCount));
          if (index <= restCount) {
            final entry = items[topCount + index - 1];
            return LeaderboardTile(
              key: ValueKey(entry.userId),
              entry: entry,
              highlight: entry.userId == c.me?.userId,
            );
          }
          return _Footer(error: c.error, onRetry: c.loadMore);
        },
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: error == null
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error!),
                  TextButton(onPressed: onRetry, child: const Text('Thử lại')),
                ],
              ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          const SizedBox(height: 8),
          FilledButton(onPressed: onRetry, child: const Text('Tải lại')),
        ],
      ),
    );
  }
}
