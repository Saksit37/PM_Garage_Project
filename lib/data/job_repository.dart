import '../db/app_database.dart';
import '../models/job.dart';
import '../models/job_status.dart';
import '../models/quote_item.dart';
import '../services/app_exception.dart';
import '../services/quote_calculator.dart';
import 'quote_repository.dart';

/// งานที่ปิดแล้ว 1 รายการในหน้าประวัติ (R5)
class HistoryEntry {
  const HistoryEntry({required this.job, required this.items, required this.summary});
  final Job job;
  final List<QuoteItem> items;
  final QuoteSummary summary;
}

class JobRepository {
  JobRepository({AppDatabase? db, QuoteRepository? quotes})
      : _db = db ?? AppDatabase.instance,
        _quotes = quotes ?? QuoteRepository(db: db);

  final AppDatabase _db;
  final QuoteRepository _quotes;

  static const _baseSelect = '''
    SELECT j.id, j.vehicle_id, j.symptom, j.status, j.received_at, j.closed_at,
           v.plate, v.model, c.name AS customer_name, c.phone AS customer_phone
    FROM jobs j
    JOIN vehicles v ON v.id = j.vehicle_id
    JOIN customers c ON c.id = v.customer_id
  ''';

  /// R4: งานที่ยังไม่ปิด กรองตามสถานะได้ (null = ทั้งหมด)
  Future<List<Job>> activeJobs({JobStatus? filter}) async {
    final db = await _db.database;
    final rows = filter == null
        ? await db.rawQuery(
            '$_baseSelect WHERE j.status != ? ORDER BY j.received_at DESC',
            [JobStatus.closed.dbValue])
        : await db.rawQuery(
            '$_baseSelect WHERE j.status = ? ORDER BY j.received_at DESC',
            [filter.dbValue]);
    return rows.map(Job.fromMap).toList();
  }

  /// จำนวนงานในแต่ละสถานะ ใช้แสดงตัวเลขบนชิปตัวกรอง
  Future<Map<JobStatus, int>> countByStatus() async {
    final db = await _db.database;
    final rows = await db.rawQuery(
        'SELECT status, COUNT(*) AS n FROM jobs WHERE status != ? GROUP BY status',
        [JobStatus.closed.dbValue]);
    return {
      for (final r in rows) JobStatus.fromDb(r['status'] as String): r['n'] as int,
    };
  }

  Future<Job> jobById(int id) async {
    final db = await _db.database;
    final rows = await db.rawQuery('$_baseSelect WHERE j.id = ?', [id]);
    if (rows.isEmpty) throw const AppException('ไม่พบใบสั่งซ่อมนี้');
    return Job.fromMap(rows.first);
  }

  /// R4: ร้านเปลี่ยนสถานะเอง ได้เฉพาะ กำลังซ่อม / รออะไหล่ / ซ่อมเสร็จ
  Future<void> updateStatus(int jobId, JobStatus status) async {
    if (!JobStatus.manual.contains(status)) {
      throw AppException('เปลี่ยนเป็นสถานะ "${status.label}" จากหน้านี้ไม่ได้');
    }
    final job = await jobById(jobId);
    if (job.status == JobStatus.closed) {
      throw const AppException('งานนี้ปิดไปแล้ว แก้ไขสถานะไม่ได้');
    }
    if (job.status == JobStatus.waitingApproval) {
      final summary = QuoteCalculator.summarize(await _quotes.itemsFor(jobId));
      if (summary.pendingCount > 0) {
        throw const AppException('ลูกค้ายังตอบใบเสนอราคาไม่ครบ');
      }
      // ลูกค้าไม่อนุมัติเลย: ให้ไปที่ "ซ่อมเสร็จ" เพื่อส่งคืนรถได้เท่านั้น
      if (summary.approvedCount == 0 && status != JobStatus.done) {
        throw const AppException(
            'ลูกค้าไม่อนุมัติรายการใด เลือก "ซ่อมเสร็จ" เพื่อส่งคืนรถ หรือเพิ่มรายการใหม่');
      }
    }
    final db = await _db.database;
    await db.update('jobs', {'status': status.dbValue},
        where: 'id = ?', whereArgs: [jobId]);
  }

  /// R4: ปิดงานได้เมื่อสถานะเป็น "ซ่อมเสร็จ" เท่านั้น และบันทึกวันที่ปิดงาน
  Future<void> closeJob(int jobId) async {
    final job = await jobById(jobId);
    if (job.status != JobStatus.done) {
      throw const AppException('ปิดงานได้เมื่อสถานะเป็น "ซ่อมเสร็จ" เท่านั้น');
    }
    final db = await _db.database;
    await db.update(
      'jobs',
      {
        'status': JobStatus.closed.dbValue,
        'closed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [jobId],
    );
  }

  /// R5: งานที่ปิดแล้วของรถคันหนึ่ง เรียงจากใหม่ไปเก่า พร้อมยอดที่อนุมัติ
  Future<List<HistoryEntry>> historyForVehicle(int vehicleId) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
        '$_baseSelect WHERE j.vehicle_id = ? AND j.status = ? '
        'ORDER BY j.closed_at DESC',
        [vehicleId, JobStatus.closed.dbValue]);
    final result = <HistoryEntry>[];
    for (final r in rows) {
      final job = Job.fromMap(r);
      final items = await _quotes.itemsFor(job.id);
      result.add(HistoryEntry(
        job: job,
        items: items,
        summary: QuoteCalculator.summarize(items),
      ));
    }
    return result;
  }

  /// งานล่าสุดที่ยังไม่ปิดของรถ (ฝั่งลูกค้า)
  Future<Job?> openJobForVehicle(int vehicleId) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
        '$_baseSelect WHERE j.vehicle_id = ? AND j.status != ? '
        'ORDER BY j.received_at DESC LIMIT 1',
        [vehicleId, JobStatus.closed.dbValue]);
    return rows.isEmpty ? null : Job.fromMap(rows.first);
  }
}
