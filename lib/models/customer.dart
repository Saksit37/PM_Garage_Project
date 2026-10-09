class Customer {
  const Customer({required this.id, required this.name, required this.phone});

  final int id;
  final String name;
  final String phone;

  factory Customer.fromMap(Map<String, Object?> m) => Customer(
        id: m['id'] as int,
        name: m['name'] as String,
        phone: m['phone'] as String,
      );
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.customerId,
    required this.plate,
    required this.model,
  });

  final int id;
  final int customerId;
  final String plate;
  final String model;

  factory Vehicle.fromMap(Map<String, Object?> m) => Vehicle(
        id: m['id'] as int,
        customerId: m['customer_id'] as int,
        plate: m['plate'] as String,
        model: (m['model'] as String?) ?? '',
      );
}

/// ทำเบอร์โทรให้อยู่ในรูปเดียวกันก่อนเก็บหรือค้นหา เช่น "081-234 5678" -> "0812345678"
String normalizePhone(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');

/// ทำทะเบียนให้อยู่ในรูปเดียวกัน ตัดช่องว่างซ้ำ เช่น " กข  1234 " -> "กข 1234"
String normalizePlate(String input) =>
    input.trim().replaceAll(RegExp(r'\s+'), ' ');
