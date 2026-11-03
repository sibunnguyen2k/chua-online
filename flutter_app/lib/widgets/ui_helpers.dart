import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import 'merit_format.dart';

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}

void showMeritSnack(BuildContext context, int merit, String what) =>
    showSnack(context, '🪷 $what  +${formatMerit(merit)} công đức');

/// Chạy một hành động API; lỗi được hiển thị dạng snackbar và trả về null.
Future<T?> guarded<T>(BuildContext context, Future<T> Function() action) async {
  try {
    return await action();
  } on ApiException catch (e) {
    if (context.mounted) showSnack(context, e.message);
  } catch (_) {
    if (context.mounted) showSnack(context, 'Đã có lỗi xảy ra.');
  }
  return null;
}

/// Phản hồi xúc giác + âm thanh hệ thống. Thay bằng audio asset (mõ, chuông) khi có.
void tapFeedback() {
  HapticFeedback.lightImpact();
  SystemSound.play(SystemSoundType.click);
}

class MeritPill extends StatelessWidget {
  const MeritPill({super.key, required this.merit});
  final int merit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.spa_rounded, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            formatMerit(merit),
            style: TextStyle(
                fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(text,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// Mở danh sách chùa để chọn nơi dâng lễ / cầu nguyện.
class TempleChip extends StatelessWidget {
  const TempleChip({super.key, required this.name, required this.onTap});
  final String? name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: const Icon(Icons.temple_buddhist_rounded, size: 18),
        label: Text(name ?? 'Chọn chùa'),
        onPressed: onTap,
      );
}
