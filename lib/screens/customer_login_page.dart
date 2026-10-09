import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/session_state.dart';
import '../widgets/feedback.dart';
import 'customer_home_page.dart';

/// ลูกค้าเข้าแอปด้วยเบอร์โทรที่ร้านบันทึกไว้ตอนรับรถ
class CustomerLoginPage extends StatefulWidget {
  const CustomerLoginPage({super.key});

  @override
  State<CustomerLoginPage> createState() => _CustomerLoginPageState();
}

class _CustomerLoginPageState extends State<CustomerLoginPage> {
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final session = context.read<SessionState>();
    try {
      await session.enterCustomer(_phone.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CustomerHomePage()));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<SessionState>().busy;
    return Scaffold(
      appBar: AppBar(title: const Text('สำหรับลูกค้า')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.directions_car, size: 56, color: Color(0xFFF97316)),
          const SizedBox(height: 12),
          const Text('กรอกเบอร์โทรที่แจ้งร้านไว้',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('เพื่อดูใบเสนอราคา สถานะงาน และประวัติรถของคุณ',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10,
            decoration: const InputDecoration(
              labelText: 'เบอร์โทร',
              hintText: '0812345678',
              prefixIcon: Icon(Icons.phone),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: busy ? null : _submit,
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('เข้าดูรถของฉัน'),
          ),
        ],
      ),
    );
  }
}
