import 'package:flutter/foundation.dart';

import '../data/customer_repository.dart';
import '../models/customer.dart';
import '../services/app_exception.dart';

enum Role { shop, customer }

/// โหมดที่ใช้งานอยู่ (ร้าน / ลูกค้า) และลูกค้าที่เข้าระบบ
/// ลูกค้าเข้าด้วยเบอร์โทรที่ร้านบันทึกไว้ตอนรับรถ (แทน OTP ที่ตัดออกจากโจทย์)
class SessionState extends ChangeNotifier {
  SessionState({CustomerRepository? customers})
      : _customers = customers ?? CustomerRepository();

  final CustomerRepository _customers;

  Role? _role;
  Customer? _customer;
  bool _busy = false;

  Role? get role => _role;
  Customer? get customer => _customer;
  bool get busy => _busy;

  void enterShop() {
    _role = Role.shop;
    _customer = null;
    notifyListeners();
  }

  /// คืนค่าเมื่อเข้าได้ ถ้าไม่พบเบอร์จะโยน AppException
  Future<void> enterCustomer(String phone) async {
    final digits = normalizePhone(phone);
    if (digits.length < 9 || digits.length > 10) {
      throw const AppException('เบอร์โทรต้องมี 9–10 หลัก');
    }
    _busy = true;
    notifyListeners();
    try {
      final found = await _customers.findByPhone(digits);
      if (found == null) {
        throw const AppException('ไม่พบเบอร์นี้ในระบบ กรุณาใช้เบอร์ที่แจ้งร้านตอนนำรถเข้า');
      }
      _role = Role.customer;
      _customer = found;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void signOut() {
    _role = null;
    _customer = null;
    notifyListeners();
  }
}
