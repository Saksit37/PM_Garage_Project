import 'package:intl/intl.dart';

final _money = NumberFormat('#,##0.##');

/// 1500 -> "1,500 บาท"
String baht(num value) => '${_money.format(value)} บาท';

const _thaiMonths = [
  'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
];

/// วันที่แบบไทย พ.ศ. เช่น "9 ต.ค. 2569"
String thaiDate(DateTime d) =>
    '${d.day} ${_thaiMonths[d.month - 1]} ${d.year + 543}';

/// วันที่พร้อมเวลา เช่น "9 ต.ค. 2569 · 14:05"
String thaiDateTime(DateTime d) =>
    '${thaiDate(d)} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
