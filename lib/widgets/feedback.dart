import 'package:flutter/material.dart';

import '../services/app_exception.dart';

/// แจ้งข้อผิดพลาดด้วย SnackBar พร้อมปุ่ม "ลองใหม่" (ถ้าส่ง onRetry มา)
void showError(BuildContext context, Object error, {VoidCallback? onRetry}) {
  // พิมพ์ error จริงลง console เพื่อใช้ไล่ปัญหา (ผู้ใช้เห็นแค่ข้อความภาษาไทย)
  debugPrint('[showError] $error');
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(friendlyError(error)),
    backgroundColor: Theme.of(context).colorScheme.error,
    action: onRetry == null
        ? null
        : SnackBarAction(
            label: 'ลองใหม่', textColor: Colors.white, onPressed: onRetry),
  ));
}

void showSuccess(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

/// หน้าจอ error กลางหน้าพร้อมปุ่มลองใหม่ ใช้กับ FutureBuilder
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(friendlyError(error), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: const Text('ลองใหม่')),
        ]),
      ),
    );
  }
}
