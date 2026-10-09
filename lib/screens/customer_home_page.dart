import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/customer_repository.dart';
import '../data/job_repository.dart';
import '../models/customer.dart';
import '../models/job.dart';
import '../models/job_status.dart';
import '../state/session_state.dart';
import '../widgets/feedback.dart';
import '../widgets/format.dart';
import '../widgets/status_chip.dart';
import 'approval_page.dart';
import 'history_page.dart';

/// หน้าหลักของลูกค้า: รถของฉัน + สถานะงานปัจจุบัน (R3, R4, R5 ฝั่งลูกค้า)
class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _VehicleWithJob {
  const _VehicleWithJob(this.vehicle, this.openJob);
  final Vehicle vehicle;
  final Job? openJob;
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final _customers = CustomerRepository();
  final _jobs = JobRepository();
  late Future<List<_VehicleWithJob>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_VehicleWithJob>> _load() async {
    final customer = context.read<SessionState>().customer!;
    final vehicles = await _customers.vehiclesOf(customer.id);
    return [
      for (final v in vehicles)
        _VehicleWithJob(v, await _jobs.openJobForVehicle(v.id)),
    ];
  }

  void _reload() => setState(() {
  _future = _load();
  });

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<SessionState>().customer;
    return Scaffold(
      appBar: AppBar(
        title: Text('สวัสดี คุณ${customer?.name ?? ''}'),
        actions: [
          IconButton(
            tooltip: 'ออก',
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<SessionState>().signOut();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<_VehicleWithJob>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorRetry(error: snap.error!, onRetry: _reload);
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(child: Text('ยังไม่มีรถในระบบ'));
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _vehicleCard(list[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _vehicleCard(_VehicleWithJob item) {
    final job = item.openJob;
    final needsAction = job?.status == JobStatus.waitingApproval;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.directions_car, color: Colors.black45),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item.vehicle.plate,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              if (job != null) StatusChip(job.status),
            ]),
            Text(item.vehicle.model,
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 10),
            if (job == null)
              const Text('ไม่มีงานซ่อมที่กำลังดำเนินการ')
            else ...[
              Text(job.symptom),
              Text('รับรถ ${thaiDate(job.receivedAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ],
            const SizedBox(height: 12),
            Row(children: [
              if (job != null)
                Expanded(
                  child: needsAction
                      ? FilledButton(
                          onPressed: () => _open(ApprovalPage(jobId: job.id)),
                          child: const Text('อนุมัติใบเสนอราคา'),
                        )
                      : OutlinedButton(
                          onPressed: () => _open(ApprovalPage(jobId: job.id)),
                          child: const Text('ดูใบเสนอราคา'),
                        ),
                ),
              if (job != null) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _open(HistoryPage(
                      vehicleId: item.vehicle.id, plate: item.vehicle.plate)),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('ประวัติ'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
