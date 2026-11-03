import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/app_controller.dart';
import 'core/api_client.dart';
import 'core/app_scope.dart';
import 'core/theme.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/chua_api.dart';

// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
const _baseUrl = String.fromEnvironment('API_BASE_URL',
    defaultValue: 'http://localhost:3000');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final client = ApiClient(baseUrl: _baseUrl, tokens: TokenStore(prefs));
  final controller = AppController(ChuaApi(client))..bootstrap();
  runApp(ChuaOnlineApp(controller: controller));
}

class ChuaOnlineApp extends StatelessWidget {
  const ChuaOnlineApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: MaterialApp(
        title: 'Chùa Online',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: ListenableBuilder(
          listenable: controller,
          builder: (_, __) => switch (controller.state) {
            SessionState.loading =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
            SessionState.needsOnboarding => const OnboardingScreen(),
            SessionState.ready => const MainShell(),
          },
        ),
      ),
    );
  }
}
