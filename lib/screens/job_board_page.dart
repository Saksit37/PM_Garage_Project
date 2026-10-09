import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../models/job_status.dart';
import '../state/job_board_state.dart';
import '../state/session_state.dart';
import '../widgets/feedback.dart';
import '../widgets/format.dart';
import '../widgets/status_chip.dart';
import 'intake_page.dart';
import 'job_detail_page.dart';
import 'search_page.dart';

/// R4: หน้ารวมงานของร้าน กรองตามสถานะได้ และเป็นหน้าหลักของโหมดร้าน
class JobBoardPage extends StatefulWidget {
  const JobBoardPage({super.key});

  @override
  State<JobBoardPage> createState() => _JobBoardPageState();
}

class _JobBoardPageState extends State<JobBoardPage> {
  @override
  void initState() {
    super.initState();
    // โหลดหลังเฟรมแรก เพื่อไม่เรียก notifyListeners ระหว่าง build
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<JobBoardState>().refresh());
  }

  Future<void> _openIntake() async {
    final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const IntakePage()));
    if (created == true && mounted) {
      await context.read<JobBoardState>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = context.watch<JobBoardState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('งานซ่อมทั้งหมด'),
        actions: [
          IconButton(
            tooltip: 'ค้นหาทะเบียนหรือเบอร์',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchPage())),
          ),
          IconButton(
            tooltip: 'ออกจากโหมดร้าน',
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<SessionState>().signOut();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openIntake,
        icon: const Icon(Icons.add),
        label: const Text('รับรถ'),
      ),
      body: Column(
        children: [
          _FilterBar(board: board),
          Expanded(child: _buildList(board)),
        ],
      ),
    );
  }

  Widget _buildList(JobBoardState board) {
    if (board.error != null && board.items.isEmpty) {
      return ErrorRetry(error: board.error!, onRetry: board.refresh);
    }
    if (board.loading && board.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (board.items.isEmpty) {
      return Center(
        child: Text(board.filter == null
            ? 'ยังไม่มีงานที่กำลังดำเนินการ'
            : 'ไม่มีงานสถานะ "${board.filter!.label}"'),
      );
    }
    return RefreshIndicator(
      onRefresh: board.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: board.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _JobCard(job: board.items[i]),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.board});
  final JobBoardState board;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      ChoiceChip(
        label: Text('ทั้งหมด ${board.totalOpen}'),
        selected: board.filter == null,
        onSelected: (_) => board.setFilter(null),
      ),
      for (final s in JobStatus.filters)
        ChoiceChip(
          label: Text('${s.label} ${board.countOf(s)}'),
          selected: board.filter == s,
          selectedColor: s.color.withAlpha(40),
          onSelected: (_) => board.setFilter(s),
        ),
    ];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => JobDetailPage(jobId: job.id)));
          if (context.mounted) await context.read<JobBoardState>().refresh();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(job.plate,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                StatusChip(job.status),
              ]),
              const SizedBox(height: 2),
              Text('${job.model} · ${job.customerName}',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              Text(job.symptom, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text('รับรถ ${thaiDateTime(job.receivedAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ],
          ),
        ),
      ),
    );
  }
}
