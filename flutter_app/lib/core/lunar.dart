import 'dart:math' as math;

/// Âm lịch Việt Nam (múi giờ UTC+7) theo thuật toán Hồ Ngọc Đức.
class LunarDate {
  const LunarDate(this.day, this.month, this.year, this.isLeap);

  final int day;
  final int month;
  final int year;
  final bool isLeap;

  static const _can = [
    'Giáp',
    'Ất',
    'Bính',
    'Đinh',
    'Mậu',
    'Kỷ',
    'Canh',
    'Tân',
    'Nhâm',
    'Quý'
  ];
  static const _chi = [
    'Tý',
    'Sửu',
    'Dần',
    'Mão',
    'Thìn',
    'Tỵ',
    'Ngọ',
    'Mùi',
    'Thân',
    'Dậu',
    'Tuất',
    'Hợi'
  ];

  String get yearName => '${_can[(year + 6) % 10]} ${_chi[(year + 8) % 12]}';

  /// Tên ngày lễ Phật giáo (nếu có).
  String? get buddhistEvent {
    if (isLeap) return null;
    switch ('$day/$month') {
      case '1/1':
        return 'Vía Phật Di Lặc';
      case '19/2':
        return 'Vía Quán Thế Âm Bồ Tát';
      case '15/4':
        return 'Lễ Phật Đản';
      case '19/6':
        return 'Vía Quán Thế Âm đắc đạo';
      case '15/7':
        return 'Lễ Vu Lan';
      case '19/9':
        return 'Vía Quán Thế Âm xuất gia';
      case '17/11':
        return 'Vía Phật A Di Đà';
      case '8/12':
        return 'Lễ Phật thành đạo';
    }
    if (day == 1) return 'Ngày Mùng Một';
    if (day == 15) return 'Ngày Rằm';
    return null;
  }

  static LunarDate fromSolar(DateTime d, {double tz = 7}) =>
      _convert(d.day, d.month, d.year, tz);

  static const _synodic = 29.530588853;

  static int _jd(int dd, int mm, int yy) {
    final a = (14 - mm) ~/ 12;
    final y = yy + 4800 - a;
    final m = mm + 12 * a - 3;
    var jd = dd +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
    if (jd < 2299161) jd = dd + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - 32083;
    return jd;
  }

  static double _newMoon(int k) {
    final t = k / 1236.85;
    final t2 = t * t;
    final t3 = t2 * t;
    const dr = math.pi / 180;
    var jd1 = 2415020.75933 + _synodic * k + 0.0001178 * t2 - 0.000000155 * t3;
    jd1 += 0.00033 * math.sin((166.56 + 132.87 * t - 0.009173 * t2) * dr);
    final m = 359.2242 + 29.10535608 * k - 0.0000333 * t2 - 0.00000347 * t3;
    final mpr = 306.0253 + 385.81691806 * k + 0.0107306 * t2 + 0.00001236 * t3;
    final f = 21.2964 + 390.67050646 * k - 0.0016528 * t2 - 0.00000239 * t3;
    var c1 = (0.1734 - 0.000393 * t) * math.sin(m * dr) +
        0.0021 * math.sin(2 * dr * m);
    c1 -= 0.4068 * math.sin(mpr * dr) + 0.0161 * math.sin(dr * 2 * mpr);
    c1 -= 0.0004 * math.sin(dr * 3 * mpr);
    c1 += 0.0104 * math.sin(dr * 2 * f) - 0.0051 * math.sin(dr * (m + mpr));
    c1 -=
        0.0074 * math.sin(dr * (m - mpr)) + 0.0004 * math.sin(dr * (2 * f + m));
    c1 -= 0.0004 * math.sin(dr * (2 * f - m)) -
        0.0006 * math.sin(dr * (2 * f + mpr));
    c1 += 0.0010 * math.sin(dr * (2 * f - mpr)) +
        0.0005 * math.sin(dr * (2 * mpr + m));
    final deltat = t < -11
        ? 0.001 +
            0.000839 * t +
            0.0002261 * t2 -
            0.00000845 * t3 -
            0.000000081 * t * t3
        : -0.000278 + 0.000265 * t + 0.000262 * t2;
    return jd1 + c1 - deltat;
  }

  static int _newMoonDay(int k, double tz) =>
      (_newMoon(k) + 0.5 + tz / 24).floor();

  static int _sunLongitude(double jdn, double tz) {
    final t = (jdn - 2451545.0 - 0.5 - tz / 24) / 36525;
    final t2 = t * t;
    const dr = math.pi / 180;
    final m =
        357.52910 + 35999.05030 * t - 0.0001559 * t2 - 0.00000048 * t * t2;
    final l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2;
    var dl = (1.914600 - 0.004817 * t - 0.000014 * t2) * math.sin(dr * m);
    dl += (0.019993 - 0.000101 * t) * math.sin(dr * 2 * m) +
        0.000290 * math.sin(dr * 3 * m);
    var l = l0 + dl;
    final omega = 125.04 - 1934.136 * t;
    l = l - 0.00569 - 0.00478 * math.sin(omega * dr);
    l *= dr;
    l -= math.pi * 2 * (l / (math.pi * 2)).floor();
    return (l / math.pi * 6).floor();
  }

  static int _lunarMonth11(int yy, double tz) {
    final off = _jd(31, 12, yy) - 2415021;
    final k = (off / _synodic).floor();
    var nm = _newMoonDay(k, tz);
    if (_sunLongitude(nm.toDouble(), tz) >= 9) nm = _newMoonDay(k - 1, tz);
    return nm;
  }

  static int _leapMonthOffset(int a11, double tz) {
    final k = ((a11 - 2415021.076998695) / _synodic + 0.5).floor();
    var i = 1;
    var arc = _sunLongitude(_newMoonDay(k + i, tz).toDouble(), tz);
    int last;
    do {
      last = arc;
      i++;
      arc = _sunLongitude(_newMoonDay(k + i, tz).toDouble(), tz);
    } while (arc != last && i < 14);
    return i - 1;
  }

  static LunarDate _convert(int dd, int mm, int yy, double tz) {
    final dayNumber = _jd(dd, mm, yy);
    final k = ((dayNumber - 2415021.076998695) / _synodic).floor();
    var monthStart = _newMoonDay(k + 1, tz);
    if (monthStart > dayNumber) monthStart = _newMoonDay(k, tz);
    var a11 = _lunarMonth11(yy, tz);
    var b11 = a11;
    int lunarYear;
    if (a11 >= monthStart) {
      lunarYear = yy;
      a11 = _lunarMonth11(yy - 1, tz);
    } else {
      lunarYear = yy + 1;
      b11 = _lunarMonth11(yy + 1, tz);
    }
    final lunarDay = dayNumber - monthStart + 1;
    final diff = (monthStart - a11) ~/ 29;
    var leap = false;
    var lunarMonth = diff + 11;
    if (b11 - a11 > 365) {
      final leapDiff = _leapMonthOffset(a11, tz);
      if (diff >= leapDiff) {
        lunarMonth = diff + 10;
        if (diff == leapDiff) leap = true;
      }
    }
    if (lunarMonth > 12) lunarMonth -= 12;
    if (lunarMonth >= 11 && diff < 4) lunarYear -= 1;
    return LunarDate(lunarDay, lunarMonth, lunarYear, leap);
  }
}
