import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/job_repository.dart';
import '../data/quote_repository.dart';
import '../models/job.dart';
import '../models/job_status.dart';
import '../services/quote_calculator.dart';
import '../state/job_board_state.dart';
import '../widgets/feedback.dart';
import '../widgets/format.dart';
import '../widgets/status_chip.dart';
import 'history_page.dart';
import 'quotation_page.dart';

/// R4: รายละเอียดงาน เปลี่ยนสถานะ และปิดงาน (ฝั่งร้าน)
class JobDetailPage extends StatefulWidget {
  const JobDetailPage({super.key, required this.jobId});
  final int jobId;

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailData {
  const _JobDetailData(this.job, this.summary);
  final Job job;
  final QuoteSummary summary;
}

class _JobDetailPageState extends State<JobDetailPage> {
  final _jobs = JobRepository();
  final _quotes = QuoteRepository();
  late Future<_JobDetailData> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_JobDetailData> _load() async {
    final job = await _jobs.jobById(widget.jobId);
    final items = await _quotes.itemsFor(widget.jobId);
    return _JobDetailData(job, QuoteCalculator.summarize(items));
  }

  void _reload() => setState(() {
  _future = _load();
  });

  /// ทำงานที่แก้ข้อมูล แล้วโหลดหน้านี้และหน้ารวมงานใหม่
  Future<void> _run(Future<void> Function() action, String successMsg) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      showSuccess(context, successMsg);
      _reload();
      await context.read<JobBoardState>().refresh();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmClose(Job job) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ปิดงานและส่งมอบรถ?'),
        content: Text('ทะเบียน ${job.plate}\nปิดงานแล้วจะย้ายไปอยู่ในประวัติการซ่อม และแก้ไขไม่ได้'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ปิดงาน')),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => _jobs.closeJob(job.id), 'ปิดงาน ${job.plate} แล้ว');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดงาน')),
      body: FutureBuilder<_JobDetailData>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorRetry(error: snap.error!, onRetry: _reload);
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final job = snap.data!.job;
          final summary = snap.data!.summary;
          return AbsorbPointer(
            absorbing: _busy,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _InfoCard(job: job),
                const SizedBox(height: 12),
                _QuoteCard(
                  summary: summary,
                  editable: job.status.isOpen && job.status != JobStatus.done,
                  onOpen: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => QuotationPage(jobId: job.id)));
                    _reload();
                    if (context.mounted) {
                      await context.read<JobBoardState>().refresh();
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (job.status.isOpen) ...[
                  const Text('เปลี่ยนสถานะ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in JobStatus.manual)
                        ChoiceChip(
                          label: Text(s.label),
                          selected: job.status == s,
                          selectedColor: s.color.withAlpha(40),
                          onSelected: job.status == s
                              ? null
                              : (_) => _run(() => _jobs.updateStatus(job.id, s),
                                  'เปลี่ยนสถานะเป็น "${s.label}" แล้ว'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: job.status == JobStatus.done
                        ? () => _confirmClose(job)
                        : null,
                    icon: const Icon(Icons.task_alt),
                    label: const Text('ปิดงาน / ส่งมอบรถ'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                  ),
                  if (job.status != JobStatus.done)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('ปิดงานได้เมื่อสถานะเป็น "ซ่อมเสร็จ"',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black45)),
                    ),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          HistoryPage(vehicleId: job.vehicleId, plate: job.plate))),
                  icon: const Icon(Icons.history),
                  label: const Text('ประวัติการซ่อมของรถคันนี้'),
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(job.plate,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              StatusChip(job.status),
            ]),
            Text(job.model, style: const TextStyle(color: Colors.black54)),
            const Divider(height: 24),
            _row(Icons.person, '${job.customerName} · ${job.customerPhone}'),
            _row(Icons.report_problem_outlined, job.symptom),
            _row(Icons.login, 'รับรถ ${thaiDateTime(job.receivedAt)}'),
            if (job.closedAt != null)
              _row(Icons.logout, 'ปิดงาน ${thaiDateTime(job.closedAt!)}'),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: Colors.black45),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ]),
      );
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.summary,
    required this.editable,
    required this.onOpen,
  });

  final QuoteSummary summary;
  final bool editable;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(
                  child: Text('ใบเสนอราคา',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Text(editable ? 'แก้ไข ›' : 'ดู ›',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              if (summary.itemCount == 0)
                const Text('ยังไม่มีรายการ แตะเพื่อเพิ่มรายการ')
              else ...[
                Text('อนุมัติ ${summary.approvedCount} · '
                    'ไม่อนุมัติ ${summary.rejectedCount} · '
                    'รอตอบ ${summary.pendingCount}'),
                const SizedBox(height: 4),
                Text('ยอดที่อนุมัติ ${baht(summary.totalApproved)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
