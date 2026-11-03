import 'package:flutter/widgets.dart';

import '../controllers/app_controller.dart';

/// Cung cấp AppController xuống cây widget; `of` đăng ký rebuild khi trạng thái đổi.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope(
      {super.key, required AppController controller, required super.child})
      : super(notifier: controller);

  static AppController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Lấy controller mà không đăng ký rebuild (dùng trong callback/initState).
  static AppController read(BuildContext context) =>
      (context.getInheritedWidgetOfExactType<AppScope>()!).notifier!;
}
