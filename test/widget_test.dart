// มีไฟล์นี้ไว้เพื่อไม่ให้ `flutter create .` สร้าง widget_test.dart ตัวอย่างที่อ้างถึง MyApp
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_garage/main.dart';

void main() {
  testWidgets('หน้าแรกแสดงปุ่มเลือกโหมดร้านและลูกค้า', (tester) async {
    await tester.pumpWidget(const PatcharinApp());
    expect(find.text('พัชรินทร์มอเตอร์'), findsOneWidget);
    expect(find.text('สำหรับร้าน'), findsOneWidget);
    expect(find.text('สำหรับลูกค้า'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
