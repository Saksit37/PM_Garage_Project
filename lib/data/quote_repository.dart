import '../db/app_database.dart';
import '../models/job_status.dart';
import '../models/quote_item.dart';
import '../services/app_exception.dart';

/// R3 ฝั่งร้าน: เพิ่ม/ลบรายการในใบเสนอราคา และส่งให้ลูกค้าอนุมัติ
class QuoteRepository {
  QuoteRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;
  final AppDatabase _db;

  Future<List<QuoteItem>> itemsFor(int jobId) async {
    final db = await _db.database;
    final rows = await db.query('quote_items',
        where: 'job_id = ?', whereArgs: [jobId], orderBy: 'kind DESC, id');
    return rows.map(QuoteItem.fromMap).toList();
  }

  Future<String> _statusOf(int jobId) async {
    final db = await _db.database;
    final rows = await db.query('jobs',
        columns: ['status'], where: 'id = ?', whereArgs: [jobId]);
    if (rows.isEmpty) throw const AppException('ไม่พบใบสั่งซ่อมนี้');
    return rows.first['status'] as String;
  }

  Future<void> _ensureEditable(int jobId) async {
    final status = JobStatus.fromDb(await _statusOf(jobId));
    if (status == JobStatus.closed || status == JobStatus.done) {
      throw const AppException('งานนี้ซ่อมเสร็จหรือปิดแล้ว แก้ใบเสนอราคาไม่ได้');
    }
  }

  /// เพิ่มรายการใหม่ สถานะเริ่มต้นเป็น "รอลูกค้าตอบ"
  Future<void> addItem({
    required int jobId,
    required String description,
    required ItemKind kind,
    required double amount,
  }) async {
    if (description.trim().isEmpty) {
      throw const AppException('กรุณากรอกชื่อรายการ');
    }
    if (amount <= 0) throw const AppException('ราคาต้องมากกว่า 0 บาท');
    await _ensureEditable(jobId);

    final db = await _db.database;
    await db.insert('quote_items', {
      'job_id': jobId,
      'description': description.trim(),
      'kind': kind.dbValue,
      'amount': amount,
      'decision': Decision.pending.dbValue,
    });
  }

  /// ลบได้เฉพาะรายการที่ลูกค้ายังไม่ตอบ เพื่อให้ผลอนุมัติที่บันทึกแล้วตรวจสอบย้อนหลังได้
  Future<void> deleteItem(QuoteItem item) async {
    if (item.decision != Decision.pending) {
      throw const AppException('รายการที่ลูกค้าตอบแล้วลบไม่ได้');
    }
    await _ensureEditable(item.jobId);
    final db = await _db.database;
    await db.delete('quote_items', where: 'id = ?', whereArgs: [item.id]);
  }

  /// ส่งใบเสนอราคาให้ลูกค้า: ต้องมีรายการที่รอตอบอย่างน้อย 1 รายการ
  /// สถานะงานเปลี่ยนเป็น "รออนุมัติ"
  Future<void> sendForApproval(int jobId) async {
    await _ensureEditable(jobId);
    final items = await itemsFor(jobId);
    if (!items.any((i) => i.decision == Decision.pending)) {
      throw const AppException('ยังไม่มีรายการใหม่ให้ลูกค้าอนุมัติ');
    }
    final db = await _db.database;
    await db.update('jobs', {'status': JobStatus.waitingApproval.dbValue},
        where: 'id = ?', whereArgs: [jobId]);
  }
}
