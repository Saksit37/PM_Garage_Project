# แอปพลิเคชันบันทึกใบสั่งซ่อมที่ตรวจสอบได้และประวัติการซ่อมบำรุงรถ

โจทย์จาก **พัชรินทร์มอเตอร์** (อู่ซ่อม แต่ง และขายรถ) · รายวิชา MAD 1/2569

Flutter + SQLite (sqflite) + Provider ทำงานในเครื่องทั้งหมด ไม่ต้องใช้คีย์หรือบัญชีบริการภายนอก

## วิธีติดตั้งและรัน (เครื่องที่ยังไม่ได้ตั้งค่า)

ต้องใช้ Flutter 3.27 ขึ้นไป

```bash
# 1) สร้างโฟลเดอร์ android/ ios/ (repo นี้เก็บเฉพาะ lib/ test/ และ pubspec)
flutter create . --platforms=android,ios,windows --project-name patcharin_repair

# 2) ติดตั้ง package
flutter pub get

# 3) ตรวจโค้ดและรันเทสต์
flutter analyze
flutter test

# 4) รันบนอีมูเลเตอร์หรือมือถือ
flutter run
```

เปิดแอปครั้งแรก ระบบจะสร้างฐานข้อมูลและใส่ข้อมูลตัวอย่างให้เอง
ถ้าต้องการล้างข้อมูล ให้ลบแอปออกจากเครื่องแล้วติดตั้งใหม่

## ข้อมูลทดสอบ

| โหมด | วิธีเข้า | สิ่งที่จะเห็น |
| --- | --- | --- |
| ร้าน | หน้าแรก > "สำหรับร้าน" | งาน 4 สถานะบนหน้ารวมงาน |
| ลูกค้า | เบอร์ `0812345678` (สมชาย) | กข 1234 มีใบเสนอราคารออนุมัติ 3 รายการ + ประวัติ 2 ครั้ง |
| ลูกค้า | เบอร์ `0898765432` (วิภา) | 1กก 5678 สถานะกำลังซ่อม |
| ลูกค้า | เบอร์ `0861112222` (ประเสริฐ) | ขค 9012 สถานะรออะไหล่ |

## ความต้องการ R1–R5 → หน้าจอและไฟล์

| R | ฟีเจอร์ | เส้นทางในแอป | ไฟล์หลัก |
| --- | --- | --- | --- |
| R1 | บันทึกการรับรถ ดึงข้อมูลลูกค้าเดิม | ร้าน > ปุ่ม "รับรถ" | `lib/screens/intake_page.dart`, `lib/data/customer_repository.dart` |
| R2 | ค้นหาจากทะเบียนหรือเบอร์ | ร้าน > ไอคอนค้นหา | `lib/screens/search_page.dart`, `lib/data/customer_repository.dart` |
| R3 | ใบเสนอราคาแยกอะไหล่/ค่าแรง + อนุมัติทีละรายการ | ร้าน > เปิดงาน > ใบเสนอราคา · ลูกค้า > อนุมัติใบเสนอราคา | `lib/screens/quotation_page.dart`, `lib/screens/approval_page.dart`, `lib/services/quote_calculator.dart` |
| R4 | หน้ารวมงาน กรองสถานะ ปิดงาน | ร้าน > หน้าแรก > ชิปสถานะ > เปิดงาน | `lib/screens/job_board_page.dart`, `lib/screens/job_detail_page.dart`, `lib/state/job_board_state.dart` |
| R5 | ประวัติการซ่อม | เปิดงาน > ประวัติ · ลูกค้า > ประวัติ | `lib/screens/history_page.dart`, `lib/data/job_repository.dart` |

## การแบ่งงาน (ขอบเขตคำถาม B1)

| สมาชิก | ขอบเขต | ไฟล์ |
| --- | --- | --- |
| คนที่ 1 | R1 รับรถ + R2 ค้นหา | `screens/intake_page.dart`, `screens/search_page.dart`, `data/customer_repository.dart`, `models/customer.dart` |
| คนที่ 2 | R3 ฝั่งร้าน + ฐานข้อมูล | `screens/quotation_page.dart`, `data/quote_repository.dart`, `db/app_database.dart`, `models/quote_item.dart`, `widgets/quote_widgets.dart` |
| คนที่ 3 | R3 ฝั่งลูกค้า + โหมดลูกค้า | `screens/approval_page.dart`, `screens/customer_login_page.dart`, `screens/customer_home_page.dart`, `data/approval_repository.dart`, `services/quote_calculator.dart`, `state/session_state.dart`, `test/quote_calculator_test.dart` |
| คนที่ 4 | R4 หน้ารวมงาน + R5 ประวัติ | `screens/job_board_page.dart`, `screens/job_detail_page.dart`, `screens/history_page.dart`, `data/job_repository.dart`, `state/job_board_state.dart`, `models/job_status.dart` |

ไฟล์ร่วม: `main.dart`, `theme.dart`, `screens/role_select_page.dart`, `widgets/format.dart`, `widgets/feedback.dart`, `widgets/status_chip.dart`, `services/app_exception.dart`

## กติกาทางธุรกิจที่เขียนไว้ในโค้ด

- รถที่ยังมีงานค้างไม่ปิด รับซ้ำไม่ได้ (`customer_repository.dart` › `receiveVehicle`)
- ลบได้เฉพาะรายการที่ลูกค้ายังไม่ตอบ เพื่อให้ผลอนุมัติตรวจสอบย้อนหลังได้ (`quote_repository.dart` › `deleteItem`)
- ลูกค้าตอบครบและอนุมัติอย่างน้อย 1 รายการ → สถานะเปลี่ยนเป็น "กำลังซ่อม" เอง (`approval_repository.dart` › `decide`)
- ยอดรวมนับเฉพาะรายการที่อนุมัติ แยกอะไหล่/ค่าแรง (`quote_calculator.dart`)
- ปิดงานได้เมื่อ "ซ่อมเสร็จ" เท่านั้น และบันทึกวันที่ปิดงาน (`job_repository.dart` › `closeJob`)
# PM_Garage_Project
