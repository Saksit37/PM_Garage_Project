import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/customer.dart';
import '../models/job_status.dart';
import '../services/app_exception.dart';

/// ผลการค้นหารถ (R2): ทะเบียน ชื่อลูกค้า และงานซ่อมล่าสุด
class VehicleSearchResult {
  const VehicleSearchResult({
    required this.vehicle,
    required this.customer,
    this.latestJobId,
    this.latestSymptom,
    this.latestStatus,
    this.latestDate,
  });

  final Vehicle vehicle;
  final Customer customer;
  final int? latestJobId;
  final String? latestSymptom;
  final JobStatus? latestStatus;
  final DateTime? latestDate;

  bool get hasOpenJob => latestStatus != null && latestStatus!.isOpen;
}

/// ข้อมูลที่ดึงมาเติมฟอร์มรับรถให้อัตโนมัติ เมื่อเป็นลูกค้าหรือรถที่เคยมาแล้ว (R1)
class IntakePrefill {
  const IntakePrefill({this.name, this.phone, this.plate, this.model});
  final String? name;
  final String? phone;
  final String? plate;
  final String? model;
}

class CustomerRepository {
  CustomerRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;
  final AppDatabase _db;

  /// R2: ค้นหาจากทะเบียน (บางส่วนก็ได้) หรือเบอร์โทร
  /// งานล่าสุดเลือกจาก received_at ล่าสุดของรถแต่ละคัน
  Future<List<VehicleSearchResult>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final db = await _db.database;
    final digits = normalizePhone(q);

    final rows = await db.rawQuery('''
      SELECT v.id AS v_id, v.customer_id, v.plate, v.model,
             c.id AS c_id, c.name, c.phone,
             j.id AS j_id, j.symptom, j.status, j.received_at
      FROM vehicles v
      JOIN customers c ON c.id = v.customer_id
      LEFT JOIN jobs j ON j.id = (
        SELECT id FROM jobs WHERE vehicle_id = v.id
        ORDER BY received_at DESC LIMIT 1)
      WHERE REPLACE(v.plate, ' ', '') LIKE ?
         ${digits.length >= 3 ? 'OR c.phone LIKE ?' : ''}
      ORDER BY j.received_at DESC
      LIMIT 30
    ''', [
      '%${q.replaceAll(' ', '')}%',
      if (digits.length >= 3) '%$digits%',
    ]);

    return rows.map((r) {
      final status = r['status'] as String?;
      final received = r['received_at'] as String?;
      return VehicleSearchResult(
        vehicle: Vehicle(
          id: r['v_id'] as int,
          customerId: r['customer_id'] as int,
          plate: r['plate'] as String,
          model: (r['model'] as String?) ?? '',
        ),
        customer: Customer(
          id: r['c_id'] as int,
          name: r['name'] as String,
          phone: r['phone'] as String,
        ),
        latestJobId: r['j_id'] as int?,
        latestSymptom: r['symptom'] as String?,
        latestStatus: status == null ? null : JobStatus.fromDb(status),
        latestDate: received == null ? null : DateTime.parse(received),
      );
    }).toList();
  }

  /// R1: หาข้อมูลเดิมจากทะเบียนก่อน ถ้าไม่พบค่อยหาจากเบอร์
  Future<IntakePrefill?> lookupForIntake({String? plate, String? phone}) async {
    final db = await _db.database;
    if (plate != null && normalizePlate(plate).isNotEmpty) {
      final rows = await db.rawQuery('''
        SELECT v.plate, v.model, c.name, c.phone FROM vehicles v
        JOIN customers c ON c.id = v.customer_id WHERE v.plate = ?''',
          [normalizePlate(plate)]);
      if (rows.isNotEmpty) {
        final r = rows.first;
        return IntakePrefill(
          plate: r['plate'] as String,
          model: r['model'] as String?,
          name: r['name'] as String,
          phone: r['phone'] as String,
        );
      }
    }
    if (phone != null && normalizePhone(phone).length >= 9) {
      final rows = await db.query('customers',
          where: 'phone = ?', whereArgs: [normalizePhone(phone)]);
      if (rows.isNotEmpty) {
        final c = Customer.fromMap(rows.first);
        return IntakePrefill(name: c.name, phone: c.phone);
      }
    }
    return null;
  }

  /// R1: บันทึกการรับรถในธุรกรรมเดียว
  /// - ลูกค้าเดิม (เบอร์ซ้ำ) อัปเดตชื่อ ไม่สร้างซ้ำ
  /// - รถเดิม (ทะเบียนซ้ำ) ผูกกับลูกค้าคนนี้
  /// - ห้ามรับรถที่ยังมีงานค้างไม่ปิด
  /// คืนค่า id ของใบสั่งซ่อมใหม่
  Future<int> receiveVehicle({
    required String name,
    required String phone,
    required String plate,
    required String model,
    required String symptom,
  }) async {
    final cleanPhone = normalizePhone(phone);
    final cleanPlate = normalizePlate(plate);
    if (name.trim().isEmpty) throw const AppException('กรุณากรอกชื่อลูกค้า');
    if (cleanPhone.length < 9 || cleanPhone.length > 10) {
      throw const AppException('เบอร์โทรต้องมี 9–10 หลัก');
    }
    if (cleanPlate.isEmpty) throw const AppException('กรุณากรอกทะเบียนรถ');
    if (symptom.trim().isEmpty) throw const AppException('กรุณากรอกอาการรถ');

    final db = await _db.database;

    // ตรวจงานค้างก่อนเริ่มธุรกรรม เพื่อให้ข้อความแจ้งผู้ใช้ไม่ถูกห่อเป็น error ของฐานข้อมูล
    // (บนเว็บ error ที่โยนกลางธุรกรรมจะกลายเป็น error ทั่วไป)
    final openJob = await db.rawQuery('''
      SELECT j.id FROM jobs j JOIN vehicles v ON v.id = j.vehicle_id
      WHERE v.plate = ? AND j.status != ? LIMIT 1''',
        [cleanPlate, JobStatus.closed.dbValue]);
    if (openJob.isNotEmpty) {
      throw AppException(
          'รถทะเบียน $cleanPlate ยังมีงานที่ยังไม่ปิด ปิดงานเดิมก่อนรับรถใหม่');
    }

    return db.transaction((txn) async {
      final customerId = await _upsertCustomer(txn, name.trim(), cleanPhone);
      final vehicleId =
          await _upsertVehicle(txn, customerId, cleanPlate, model.trim());

      return txn.insert('jobs', {
        'vehicle_id': vehicleId,
        'symptom': symptom.trim(),
        'status': JobStatus.received.dbValue,
        'received_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<int> _upsertCustomer(
      DatabaseExecutor txn, String name, String phone) async {
    final found =
        await txn.query('customers', where: 'phone = ?', whereArgs: [phone]);
    if (found.isNotEmpty) {
      final id = found.first['id'] as int;
      await txn.update('customers', {'name': name},
          where: 'id = ?', whereArgs: [id]);
      return id;
    }
    return txn.insert('customers', {'name': name, 'phone': phone});
  }

  Future<int> _upsertVehicle(
      DatabaseExecutor txn, int customerId, String plate, String model) async {
    final found =
        await txn.query('vehicles', where: 'plate = ?', whereArgs: [plate]);
    if (found.isNotEmpty) {
      final id = found.first['id'] as int;
      await txn.update(
        'vehicles',
        {
          'customer_id': customerId,
          if (model.isNotEmpty) 'model': model,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return id;
    }
    return txn.insert('vehicles',
        {'customer_id': customerId, 'plate': plate, 'model': model});
  }

  /// ใช้ตอนลูกค้าเข้าแอปด้วยเบอร์โทร
  Future<Customer?> findByPhone(String phone) async {
    final db = await _db.database;
    final rows = await db.query('customers',
        where: 'phone = ?', whereArgs: [normalizePhone(phone)]);
    return rows.isEmpty ? null : Customer.fromMap(rows.first);
  }

  Future<List<Vehicle>> vehiclesOf(int customerId) async {
    final db = await _db.database;
    final rows = await db.query('vehicles',
        where: 'customer_id = ?', whereArgs: [customerId], orderBy: 'plate');
    return rows.map(Vehicle.fromMap).toList();
  }
}
