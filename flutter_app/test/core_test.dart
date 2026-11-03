import 'package:chua_online/core/lunar.dart';
import 'package:chua_online/widgets/merit_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('âm lịch: các mốc đã biết', () {
    final tet2025 = LunarDate.fromSolar(DateTime(2025, 1, 29));
    expect([tet2025.day, tet2025.month, tet2025.year], [1, 1, 2025]);
    expect(tet2025.yearName, 'Ất Tỵ');

    expect(LunarDate.fromSolar(DateTime(2025, 5, 12)).buddhistEvent,
        'Lễ Phật Đản');
    expect(
        LunarDate.fromSolar(DateTime(2025, 9, 6)).buddhistEvent, 'Lễ Vu Lan');
    expect(LunarDate.fromSolar(DateTime(2026, 2, 17)).year, 2026);
  });

  test('formatMerit dùng dấu chấm ngăn cách hàng nghìn', () {
    expect(formatMerit(0), '0');
    expect(formatMerit(999), '999');
    expect(formatMerit(1000), '1.000');
    expect(formatMerit(1234567), '1.234.567');
  });
}
