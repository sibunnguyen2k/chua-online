import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../widgets/sprites/sprite.dart';
import '../widgets/sprites/sprites.dart';
import '../widgets/ui_helpers.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = AppScope.read(context);
    setState(() => _busy = true);
    await guarded(context, () => app.register(_name.text.trim()));
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Sprite(draw: (c) => drawBuddha(c), size: 130),
                      Sprite(
                          draw: (c) => drawMonk(c, pose: MonkPose.praying),
                          size: 90),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Chùa Online',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(
                    'Thắp hương, gõ mõ, niệm Phật và tích công đức mỗi ngày.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _name,
                    maxLength: 40,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _busy ? null : _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Pháp danh / tên của bạn',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Bắt đầu tu tập'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
