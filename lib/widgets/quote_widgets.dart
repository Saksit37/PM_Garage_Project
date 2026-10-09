import 'package:flutter/material.dart';

import '../models/quote_item.dart';
import '../services/quote_calculator.dart';
import 'format.dart';

/// ป้ายผลอนุมัติของแต่ละรายการ
class DecisionBadge extends StatelessWidget {
  const DecisionBadge(this.decision, {super.key});
  final Decision decision;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (decision) {
      Decision.approved => (const Color(0xFF16A34A), Icons.check_circle),
      Decision.rejected => (const Color(0xFFDC2626), Icons.cancel),
      Decision.pending => (const Color(0xFFD97706), Icons.schedule),
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text(decision.label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}

/// กล่องสรุปยอด: แยกอะไหล่ / ค่าแรง และยอดรวมเฉพาะที่อนุมัติ
class QuoteTotals extends StatelessWidget {
  const QuoteTotals({super.key, required this.summary});
  final QuoteSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white70, fontSize: 14),
        child: Column(children: [
          _line('ค่าอะไหล่ (อนุมัติ)', baht(summary.partsApproved)),
          _line('ค่าแรง (อนุมัติ)', baht(summary.laborApproved)),
          const Divider(color: Colors.white24, height: 20),
          Row(children: [
            const Expanded(
              child: Text('ยอดรวมที่อนุมัติ',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            Text(baht(summary.totalApproved),
                style: const TextStyle(
                    color: Color(0xFFFDBA74),
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ]),
          if (summary.pendingCount > 0 || summary.rejectedCount > 0) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text('จากที่เสนอทั้งหมด ${baht(summary.totalProposed)}',
                  style: const TextStyle(fontSize: 12)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ]),
      );
}
