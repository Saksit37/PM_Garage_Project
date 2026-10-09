import 'package:flutter_test/flutter_test.dart';
import 'package:pm_garage/models/customer.dart';
import 'package:pm_garage/models/job_status.dart';
import 'package:pm_garage/widgets/format.dart';

void main() {
  group('normalize (R1, R2)', () {
    test('เบอร์โทรตัดขีดและช่องว่าง', () {
      expect(normalizePhone('081-234 5678'), '0812345678');
    });
    test('ทะเบียนตัดช่องว่างซ้ำ', () {
      expect(normalizePlate('  กข   1234 '), 'กข 1234');
    });
  });

  group('JobStatus (R4)', () {
    test('อ่านค่าจากฐานข้อมูลกลับเป็น enum', () {
      for (final s in JobStatus.values) {
        expect(JobStatus.fromDb(s.dbValue), s);
      }
    });
    test('ตัวกรองมี 4 สถานะตามที่ผู้ใช้ขอ', () {
      expect(JobStatus.filters.map((s) => s.label), [
        'รออนุมัติ',
        'กำลังซ่อม',
        'รออะไหล่',
        'ซ่อมเสร็จ',
      ]);
    });
    test('ปิดงานแล้วไม่นับเป็นงานที่เปิดอยู่', () {
      expect(JobStatus.closed.isOpen, isFalse);
      expect(JobStatus.done.isOpen, isTrue);
    });
  });

  group('format', () {
    test('เงินบาทมีคอมมา', () => expect(baht(2750), '2,750 บาท'));
    test('วันที่เป็น พ.ศ.',
        () => expect(thaiDate(DateTime(2026, 10, 9)), '9 ต.ค. 2569'));
  });
}
