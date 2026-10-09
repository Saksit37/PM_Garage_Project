import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// ฐานข้อมูล SQLite ในเครื่อง
/// ตาราง: customers → vehicles → jobs → quote_items
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _fileName = 'patcharin_repair.db';
  static const _version = 1;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, _fileName),
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seed(db);
      },
    );
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE
      )''');
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL REFERENCES customers(id),
        plate TEXT NOT NULL UNIQUE,
        model TEXT
      )''');
    await db.execute('''
      CREATE TABLE jobs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL REFERENCES vehicles(id),
        symptom TEXT NOT NULL,
        status TEXT NOT NULL,
        received_at TEXT NOT NULL,
        closed_at TEXT
      )''');
    await db.execute('''
      CREATE TABLE quote_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_id INTEGER NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
        description TEXT NOT NULL,
        kind TEXT NOT NULL CHECK (kind IN ('part','labor')),
        amount REAL NOT NULL CHECK (amount >= 0),
        decision TEXT NOT NULL DEFAULT 'pending'
      )''');
    // ดัชนีสำหรับการค้นหาด้วยเบอร์และทะเบียน (R2) และหน้ารวมงาน (R4)
    await db.execute('CREATE INDEX idx_jobs_status ON jobs(status)');
    await db.execute('CREATE INDEX idx_jobs_vehicle ON jobs(vehicle_id)');
  }

  /// ข้อมูลตัวอย่างสำหรับสาธิต: ลูกค้า 3 ราย รถ 4 คัน งานหลายสถานะ และประวัติที่ปิดแล้ว
  static Future<void> _seed(Database db) async {
    final now = DateTime.now();
    String daysAgo(int d) => now.subtract(Duration(days: d)).toIso8601String();

    final batch = db.batch();
    batch.insert('customers', {'id': 1, 'name': 'สมชาย ใจดี', 'phone': '0812345678'});
    batch.insert('customers', {'id': 2, 'name': 'วิภา รักษ์รถ', 'phone': '0898765432'});
    batch.insert('customers', {'id': 3, 'name': 'ประเสริฐ มั่นคง', 'phone': '0861112222'});

    batch.insert('vehicles', {'id': 1, 'customer_id': 1, 'plate': 'กข 1234', 'model': 'Toyota Vios'});
    batch.insert('vehicles', {'id': 2, 'customer_id': 2, 'plate': '1กก 5678', 'model': 'Honda City'});
    batch.insert('vehicles', {'id': 3, 'customer_id': 3, 'plate': 'ขค 9012', 'model': 'Isuzu D-Max'});
    batch.insert('vehicles', {'id': 4, 'customer_id': 1, 'plate': 'งจ 3456', 'model': 'Honda Wave 110i'});

    // ประวัติที่ปิดแล้ว (R5)
    batch.insert('jobs', {
      'id': 1, 'vehicle_id': 1, 'symptom': 'เปลี่ยนน้ำมันเครื่องตามระยะ',
      'status': 'closed', 'received_at': daysAgo(120), 'closed_at': daysAgo(120),
    });
    batch.insert('quote_items', {'job_id': 1, 'description': 'น้ำมันเครื่องสังเคราะห์ 4 ลิตร', 'kind': 'part', 'amount': 1200, 'decision': 'approved'});
    batch.insert('quote_items', {'job_id': 1, 'description': 'ไส้กรองน้ำมันเครื่อง', 'kind': 'part', 'amount': 250, 'decision': 'approved'});
    batch.insert('quote_items', {'job_id': 1, 'description': 'ค่าแรงเปลี่ยนถ่าย', 'kind': 'labor', 'amount': 200, 'decision': 'approved'});

    batch.insert('jobs', {
      'id': 2, 'vehicle_id': 1, 'symptom': 'เบรกมีเสียงดัง',
      'status': 'closed', 'received_at': daysAgo(45), 'closed_at': daysAgo(43),
    });
    batch.insert('quote_items', {'job_id': 2, 'description': 'ผ้าเบรกหน้า', 'kind': 'part', 'amount': 1800, 'decision': 'approved'});
    batch.insert('quote_items', {'job_id': 2, 'description': 'เจียรจานเบรก', 'kind': 'labor', 'amount': 600, 'decision': 'rejected'});
    batch.insert('quote_items', {'job_id': 2, 'description': 'ค่าแรงเปลี่ยนผ้าเบรก', 'kind': 'labor', 'amount': 400, 'decision': 'approved'});

    // งานที่กำลังดำเนินการ (R3, R4)
    batch.insert('jobs', {
      'id': 3, 'vehicle_id': 1, 'symptom': 'แอร์ไม่เย็น มีกลิ่นอับ',
      'status': 'waiting_approval', 'received_at': daysAgo(1),
    });
    batch.insert('quote_items', {'job_id': 3, 'description': 'น้ำยาแอร์ R134a', 'kind': 'part', 'amount': 900, 'decision': 'pending'});
    batch.insert('quote_items', {'job_id': 3, 'description': 'กรองแอร์', 'kind': 'part', 'amount': 350, 'decision': 'pending'});
    batch.insert('quote_items', {'job_id': 3, 'description': 'ล้างตู้แอร์', 'kind': 'labor', 'amount': 1500, 'decision': 'pending'});

    batch.insert('jobs', {
      'id': 4, 'vehicle_id': 2, 'symptom': 'สตาร์ทติดยาก แบตเตอรี่อ่อน',
      'status': 'repairing', 'received_at': daysAgo(0),
    });
    batch.insert('quote_items', {'job_id': 4, 'description': 'แบตเตอรี่ 65Ah', 'kind': 'part', 'amount': 2800, 'decision': 'approved'});
    batch.insert('quote_items', {'job_id': 4, 'description': 'ค่าแรงตรวจระบบไฟชาร์จ', 'kind': 'labor', 'amount': 300, 'decision': 'approved'});

    batch.insert('jobs', {
      'id': 5, 'vehicle_id': 3, 'symptom': 'ช่วงล่างมีเสียงดังเวลาผ่านลูกระนาด',
      'status': 'waiting_parts', 'received_at': daysAgo(3),
    });
    batch.insert('quote_items', {'job_id': 5, 'description': 'ลูกหมากปีกนกล่าง (คู่)', 'kind': 'part', 'amount': 2400, 'decision': 'approved'});
    batch.insert('quote_items', {'job_id': 5, 'description': 'ค่าแรงเปลี่ยนลูกหมาก', 'kind': 'labor', 'amount': 800, 'decision': 'approved'});

    batch.insert('jobs', {
      'id': 6, 'vehicle_id': 4, 'symptom': 'โซ่หย่อน เปลี่ยนยางหลัง',
      'status': 'done', 'received_at': daysAgo(2),
    });
    batch.insert('quote_items', {'job_id': 6, 'description': 'ชุดโซ่สเตอร์', 'kind': 'part', 'amount': 950, 'decision': 'approved'});
    batch.insert('quote_items', {'job_id': 6, 'description': 'ยางหลัง 80/90-17', 'kind': 'part', 'amount': 650, 'decision': 'approved'});
    batch.insert('quote_items', {'job_id': 6, 'description': 'ค่าแรง', 'kind': 'labor', 'amount': 250, 'decision': 'approved'});

    await batch.commit(noResult: true);
  }
}
