// เลือกไฟล์ตามแพลตฟอร์มตอนคอมไพล์ (conditional import)
// - มือถือ / Windows / Linux ใช้ db_setup_io.dart
// - เว็บ (Chrome) ใช้ db_setup_web.dart
// แยกไฟล์เพราะ sqflite_common_ffi ใช้ dart:ffi ซึ่งคอมไพล์บนเว็บไม่ได้
export 'db_setup_io.dart' if (dart.library.js_interop) 'db_setup_web.dart';
