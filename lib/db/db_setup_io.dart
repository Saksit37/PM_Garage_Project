import 'dart:io' show Platform;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Android/iOS ใช้ sqflite ได้เลย ส่วน Windows/Linux ต้องใช้ตัว FFI แทน
void setupDatabaseFactory() {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
