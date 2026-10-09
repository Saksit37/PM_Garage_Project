import 'package:flutter/material.dart';

import '../data/approval_repository.dart';
import '../data/job_repository.dart';
import '../data/quote_repository.dart';
import '../models/job.dart';
import '../models/job_status.dart';
import '../models/quote_item.dart';
import '../services/quote_calculator.dart';
import '../widgets/feedback.dart';
import '../widgets/format.dart';
import '../widgets/quote_widgets.dart';
import '../widgets/status_chip.dart';

/// R3 ฝั่งลูกค้า: ดูใบเสนอราคาและอนุมัติหรือไม่อนุมัติทีละรายการ
/// ยอดรวมคำนวณใหม่จากรายการที่อนุมัติทันทีหลังกด
class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key, required this.jobId});
  final int jobId;

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  final _jobs = JobRepository();
  final _quotes = QuoteRepository();
  final _approval = ApprovalRepository();

  Job? _job;
  List<QuoteItem> _items = const [];
  Object? _error;
  bool _loading = true;

  /// id ของรายการที่กำลังบันทึก ใช้กันกดซ้ำและแสดงตัวโหลดเฉพาะแถวนั้น
  int? _savingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // ครั้งแรก (_loading = true อยู่แล้ว) ไม่ต้อง setState ระหว่าง initState
    if (!_loading || _error != null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final job = await _jobs.jobById(widget.jobId);
      final items = await _quotes.itemsFor(widget.jobId);
      if (!mounted) return;
      setState(() {
        _job = job;
        _items = items;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(QuoteItem item, Decision decision) async {
    setState(() => _savingId = item.id);
    try {
      final summary = await _approval.decide(item, decision);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      if (summary.allDecided && summary.approvedCount > 0) {
        showSuccess(context,
            'ตอบครบแล้ว ร้านจะเริ่มซ่อม ยอดที่อนุมัติ ${baht(summary.totalApproved)}');
      }
    } catch (e) {
      if (mounted) showError(context, e, onRetry: () => _decide(item, decision));
    } finally {
      if (mounted) setState(() => _savingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ใบเสนอราคา')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) return ErrorRetry(error: _error!, onRetry: _load);
    if (_loading && _job == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final job = _job!;
    final canDecide = job.status == JobStatus.waitingApproval;
    final summary = QuoteCalculator.summarize(_items);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(
            child: Text(job.plate,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          StatusChip(job.status),
        ]),
        Text(job.symptom, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 12),
        if (canDecide && summary.pendingCount > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Text(
                'กรุณาเลือกอนุมัติหรือไม่อนุมัติทีละรายการ (เหลือ ${summary.pendingCount} รายการ)'),
          ),
        if (_items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text('ร้านยังไม่ได้ทำใบเสนอราคา',
                textAlign: TextAlign.center),
          ),
        for (final kind in ItemKind.values)
          if (_items.any((i) => i.kind == kind)) ...[
            const SizedBox(height: 12),
            Text(kind.label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            for (final item in _items.where((i) => i.kind == kind))
              _itemCard(item, canDecide),
          ],
        const SizedBox(height: 16),
        QuoteTotals(summary: summary),
      ],
    );
  }

  Widget _itemCard(QuoteItem item, bool canDecide) {
    final saving = _savingId == item.id;
    final dim = item.decision == Decision.rejected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(item.description,
                      style: TextStyle(
                        fontSize: 16,
                        decoration: dim ? TextDecoration.lineThrough : null,
                        color: dim ? Colors.black38 : null,
                      )),
                ),
                Text(baht(item.amount),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: dim ? Colors.black38 : null)),
              ]),
              const SizedBox(height: 8),
              if (saving)
                const LinearProgressIndicator()
              else if (canDecide)
                Row(children: [
                  Expanded(
                    child: _choice(
                      label: 'อนุมัติ',
                      icon: Icons.check,
                      color: const Color(0xFF16A34A),
                      selected: item.decision == Decision.approved,
                      onTap: _savingId != null
                          ? null
                          : () => _decide(item, Decision.approved),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _choice(
                      label: 'ไม่อนุมัติ',
                      icon: Icons.close,
                      color: const Color(0xFFDC2626),
                      selected: item.decision == Decision.rejected,
                      onTap: _savingId != null
                          ? null
                          : () => _decide(item, Decision.rejected),
                    ),
                  ),
                ])
              else
                DecisionBadge(item.decision),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choice({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return selected
        ? FilledButton.icon(
            onPressed: onTap,
            style: FilledButton.styleFrom(backgroundColor: color),
            icon: Icon(icon, size: 18),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(foregroundColor: color),
            icon: Icon(icon, size: 18),
            label: Text(label),
          );
  }
}
