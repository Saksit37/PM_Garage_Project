import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/session_state.dart';
import '../theme.dart';
import 'customer_login_page.dart';
import 'job_board_page.dart';

/// หน้าแรก: เลือกโหมดร้านหรือลูกค้า
class RoleSelectPage extends StatelessWidget {
  const RoleSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.build_circle, size: 64, color: AppColors.orange),
              const SizedBox(height: 16),
              const Text('พัชรินทร์มอเตอร์',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('ใบสั่งซ่อมและประวัติการซ่อมรถ',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              const Spacer(),
              _RoleCard(
                icon: Icons.storefront,
                title: 'สำหรับร้าน',
                subtitle: 'รับรถ ทำใบเสนอราคา ติดตามงาน',
                onTap: () {
                  context.read<SessionState>().enterShop();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const JobBoardPage()));
                },
              ),
              const SizedBox(height: 12),
              _RoleCard(
                icon: Icons.person,
                title: 'สำหรับลูกค้า',
                subtitle: 'ดูใบเสนอราคา อนุมัติ และดูประวัติรถ',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CustomerLoginPage())),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFFFEDD5),
              child: Icon(icon, color: AppColors.orange),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ]),
        ),
      ),
    );
  }
}
