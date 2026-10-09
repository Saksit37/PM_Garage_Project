import 'job_status.dart';

/// ใบสั่งซ่อม 1 ใบ พร้อมข้อมูลรถและลูกค้าที่ join มาแล้ว
class Job {
  const Job({
    required this.id,
    required this.vehicleId,
    required this.symptom,
    required this.status,
    required this.receivedAt,
    this.closedAt,
    required this.plate,
    required this.model,
    required this.customerName,
    required this.customerPhone,
  });

  final int id;
  final int vehicleId;
  final String symptom;
  final JobStatus status;
  final DateTime receivedAt;
  final DateTime? closedAt;
  final String plate;
  final String model;
  final String customerName;
  final String customerPhone;

  /// ใช้กับผลลัพธ์จาก JobRepository._baseSelect
  factory Job.fromMap(Map<String, Object?> m) => Job(
        id: m['id'] as int,
        vehicleId: m['vehicle_id'] as int,
        symptom: m['symptom'] as String,
        status: JobStatus.fromDb(m['status'] as String),
        receivedAt: DateTime.parse(m['received_at'] as String),
        closedAt: m['closed_at'] == null
            ? null
            : DateTime.parse(m['closed_at'] as String),
        plate: m['plate'] as String,
        model: (m['model'] as String?) ?? '',
        customerName: m['customer_name'] as String,
        customerPhone: m['customer_phone'] as String,
      );
}
