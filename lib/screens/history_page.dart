import 'package:flutter/material.dart';

import '../data/job_repository.dart';
import '../models/quote_item.dart';
import '../widgets/feedback.dart';
import '../widgets/format.dart';

/// R5: ประวัติการซ่อมของรถ 1 คัน (งานที่ปิดแล้ว) เรียงจากใหม่ไปเก่า
/// ใช้ทั้งฝั่งร้านและฝั่งลูกค้า
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.vehicleId, required this.plate});
  final int vehicleId;
  final String plate;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _jobs = JobRepository();
  late Future<List<HistoryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _jobs.historyForVehicle(widget.vehicleId);
  }

  void _reload() =>
    setState(() {
      _future = _jobs.historyForVehicle(widget.vehicleId);
    });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ประวัติ ${widget.plate}')),
      body: FutureBuilder<List<HistoryEntry>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorRetry(error: snap.error!, onRetry: _reload);
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snap.data!;
          if (entries.isEmpty) {
            return const Center(child: Text('ยังไม่มีประวัติการซ่อมที่ปิดงานแล้ว'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, i) =>
                _entry(entries[i], isLast: i == entries.length - 1),
          );
        },
      ),
    );
  }

  /// แสดงเป็นเส้นเวลา: จุดด้านซ้าย + การ์ดงานด้านขวา
  Widget _entry(HistoryEntry e, {required bool isLast}) {
    final approved =
        e.items.where((i) => i.decision == Decision.approved).toList();
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 24,
          child: Column(children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 18),
              decoration: const BoxDecoration(
                  color: Color(0xFFF97316), shape: BoxShape.circle),
            ),
            if (!isLast)
              Expanded(
                  child: Container(width: 2, color: const Color(0xFFE2E8F0))),
          ]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(thaiDate(e.job.closedAt ?? e.job.receivedAt),
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(e.job.symptom,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (approved.isEmpty)
                      const Text('ไม่มีรายการที่อนุมัติ')
                    else
                      for (final item in approved)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(children: [
                            Icon(
                                item.kind == ItemKind.part
                                    ? Icons.settings
                                    : Icons.handyman,
                                size: 16,
                                color: Colors.black45),
                            const SizedBox(width: 6),
                            Expanded(child: Text(item.description)),
                            Text(baht(item.amount)),
                          ]),
                        ),
                    const Divider(height: 18),
                    Row(children: [
                      Expanded(
                        child: Text(
                          'อะไหล่ ${baht(e.summary.partsApproved)} · ค่าแรง ${baht(e.summary.laborApproved)}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                        ),
                      ),
                      Text(baht(e.summary.totalApproved),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
