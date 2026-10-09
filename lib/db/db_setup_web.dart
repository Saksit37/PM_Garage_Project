import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// เว็บ: SQLite ทำงานผ่าน WebAssembly และเก็บข้อมูลใน IndexedDB ของเบราว์เซอร์
/// ต้องรัน `dart run sqflite_common_ffi_web:setup` หนึ่งครั้งก่อน
void setupDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}
