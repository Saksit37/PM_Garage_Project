/// ข้อผิดพลาดที่ตั้งใจแจ้งผู้ใช้ ข้อความเป็นภาษาไทยพร้อมแสดงใน SnackBar
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => 'AppException: $message';
}

/// แปลง error ใดๆ เป็นข้อความที่ผู้ใช้อ่านเข้าใจ
String friendlyError(Object error) {
  if (error is AppException) return error.message;
  // บางแพลตฟอร์มห่อ AppException ไว้ใน error อื่น ดึงข้อความเดิมออกมา
  final text = error.toString();
  const marker = 'AppException:';
  final i = text.indexOf(marker);
  if (i >= 0) return text.substring(i + marker.length).trim();
  return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
}
