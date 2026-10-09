import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'db/db_setup.dart';
import 'screens/role_select_page.dart';
import 'state/job_board_state.dart';
import 'state/session_state.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // เลือกตัวเปิด SQLite ตามแพลตฟอร์ม (มือถือ / Windows / เว็บ) ดู db/db_setup.dart
  setupDatabaseFactory();
  runApp(const PatcharinApp());
}

class PatcharinApp extends StatelessWidget {
  const PatcharinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionState()),
        ChangeNotifierProvider(create: (_) => JobBoardState()),
      ],
      child: MaterialApp(
        title: 'พัชรินทร์มอเตอร์',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const RoleSelectPage(),
      ),
    );
  }
}
