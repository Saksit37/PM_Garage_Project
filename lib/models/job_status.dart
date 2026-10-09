import 'package:flutter/material.dart';

/// สถานะของใบสั่งซ่อม (R4)
/// ค่า [dbValue] คือข้อความที่เก็บในคอลัมน์ jobs.status
enum JobStatus {
  received('received', 'รับรถแล้ว', Color(0xFF64748B)),
  waitingApproval('waiting_approval', 'รออนุมัติ', Color(0xFFD97706)),
  repairing('repairing', 'กำลังซ่อม', Color(0xFF2563EB)),
  waitingParts('waiting_parts', 'รออะไหล่', Color(0xFF9333EA)),
  done('done', 'ซ่อมเสร็จ', Color(0xFF16A34A)),
  closed('closed', 'ปิดงานแล้ว', Color(0xFF334155));

  const JobStatus(this.dbValue, this.label, this.color);

  final String dbValue;
  final String label;
  final Color color;

  static JobStatus fromDb(String value) => JobStatus.values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => JobStatus.received,
      );

  /// สถานะที่ใช้เป็นตัวกรองบนหน้ารวมงาน ตามที่ผู้ใช้ขอ 4 แบบ
  static const List<JobStatus> filters = [
    waitingApproval,
    repairing,
    waitingParts,
    done,
  ];

  /// สถานะที่ร้านเปลี่ยนเองได้จากหน้ารายละเอียดงาน
  /// (รออนุมัติ เกิดจากการส่งใบเสนอราคา และ ปิดงาน มีปุ่มของตัวเอง)
  static const List<JobStatus> manual = [repairing, waitingParts, done];

  bool get isOpen => this != JobStatus.closed;
}
