import '../db/app_database.dart';
import '../models/job_status.dart';
import '../models/quote_item.dart';
import '../services/app_exception.dart';
import '../services/quote_calculator.dart';
import 'quote_repository.dart';

/// R3 ฝั่งลูกค้า: บันทึกผลอนุมัติทีละรายการ
class ApprovalRepository {
  ApprovalRepository({AppDatabase? db, QuoteRepository? quotes})
      : _db = db ?? AppDatabase.instance,
        _quotes = quotes ?? QuoteRepository(db: db);

  final AppDatabase _db;
  final QuoteRepository _quotes;

  /// บันทึกผลของรายการเดียว แล้วคืนสรุปยอดใหม่
  /// เมื่อลูกค้าตอบครบทุกรายการและอนุมัติอย่างน้อย 1 รายการ
  /// งานจะเปลี่ยนเป็น "กำลังซ่อม" ให้อัตโนมัติ ร้านจึงรู้ว่าทำต่อได้
  Future<QuoteSummary> decide(QuoteItem item, Decision decision) async {
    if (decision == Decision.pending) {
      throw const AppException('กรุณาเลือกอนุมัติหรือไม่อนุมัติ');
    }
    final db = await _db.database;
    final jobRows = await db.query('jobs',
        columns: ['status'], where: 'id = ?', whereArgs: [item.jobId]);
    if (jobRows.isEmpty) throw const AppException('ไม่พบใบสั่งซ่อมนี้');
    final status = JobStatus.fromDb(jobRows.first['status'] as String);
    if (status != JobStatus.waitingApproval) {
      throw const AppException('ใบเสนอราคานี้ไม่ได้อยู่ในสถานะรออนุมัติแล้ว');
    }

    await db.update('quote_items', {'decision': decision.dbValue},
        where: 'id = ?', whereArgs: [item.id]);

    final summary = QuoteCalculator.summarize(await _quotes.itemsFor(item.jobId));
    if (summary.allDecided && summary.approvedCount > 0) {
      await db.update('jobs', {'status': JobStatus.repairing.dbValue},
          where: 'id = ?', whereArgs: [item.jobId]);
    }
    return summary;
  }
}
