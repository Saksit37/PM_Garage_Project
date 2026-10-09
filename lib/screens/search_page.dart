import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/customer_repository.dart';
import '../state/job_board_state.dart';
import '../widgets/feedback.dart';
import '../widgets/format.dart';
import '../widgets/status_chip.dart';
import 'history_page.dart';
import 'intake_page.dart';
import 'job_detail_page.dart';

/// R2: ค้นหารถจากทะเบียนหรือเบอร์โทร
/// ผลค้นหาแสดงทะเบียน ชื่อลูกค้า และงานซ่อมล่าสุด
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _repo = CustomerRepository();
  final _query = TextEditingController();
  Timer? _debounce;

  List<VehicleSearchResult> _results = const [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  /// รอให้หยุดพิมพ์ 300 ms ก่อนค้น เพื่อไม่ query ทุกตัวอักษร
  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(text));
  }

  Future<void> _run(String text) async {
    if (text.trim().isEmpty) {
      setState(() {
        _results = const [];
        _searched = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await _repo.search(text);
      if (!mounted || text != _query.text) return; // ผลเก่าที่มาช้า ไม่ต้องแสดง
      setState(() {
        _results = r;
        _searched = true;
      });
    } catch (e) {
      if (mounted) showError(context, e, onRetry: () => _run(_query.text));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openActions(VehicleSearchResult r) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: Text(r.vehicle.plate,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${r.customer.name} · ${r.customer.phone}'),
          ),
          if (r.hasOpenJob)
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('เปิดงานที่กำลังซ่อม'),
              onTap: () {
                Navigator.pop(sheet);
                _push(JobDetailPage(jobId: r.latestJobId!));
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('รับรถคันนี้เข้าซ่อม'),
              onTap: () {
                Navigator.pop(sheet);
                _push(IntakePage(
                  prefill: IntakePrefill(
                    plate: r.vehicle.plate,
                    model: r.vehicle.model,
                    name: r.customer.name,
                    phone: r.customer.phone,
                  ),
                ));
              },
            ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('ดูประวัติการซ่อม'),
            onTap: () {
              Navigator.pop(sheet);
              _push(HistoryPage(vehicleId: r.vehicle.id, plate: r.vehicle.plate));
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _push(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (!mounted) return;
    await context.read<JobBoardState>().refresh();
    await _run(_query.text); // ข้อมูลอาจเปลี่ยน เช่น รับรถใหม่
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _query,
          autofocus: true,
          onChanged: _onChanged,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'ค้นหาทะเบียน หรือ เบอร์โทร',
            hintStyle: TextStyle(color: Colors.white60),
            border: InputBorder.none,
            filled: false,
          ),
        ),
        bottom: _loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2))
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_searched) {
      return const Center(
          child: Text('พิมพ์ทะเบียน (บางส่วนก็ได้) หรือเบอร์โทรอย่างน้อย 3 หลัก'));
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('ไม่พบรถหรือลูกค้าที่ตรงกับคำค้น'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('รับรถใหม่'),
            onPressed: () => _push(const IntakePage()),
          ),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = _results[i];
        return Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () => _openActions(r),
            title: Text(r.vehicle.plate,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r.customer.name} · ${r.customer.phone}'),
                const SizedBox(height: 4),
                Text(
                  r.latestSymptom == null
                      ? 'ยังไม่มีงานซ่อม'
                      : 'ล่าสุด: ${r.latestSymptom} (${thaiDate(r.latestDate!)})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: r.latestStatus == null
                ? null
                : StatusChip(r.latestStatus!, dense: true),
          ),
        );
      },
    );
  }
}
