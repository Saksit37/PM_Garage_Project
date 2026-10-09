import 'package:flutter/foundation.dart';

import '../data/job_repository.dart';
import '../models/job.dart';
import '../models/job_status.dart';

/// สถานะของหน้ารวมงาน (R4) ใช้ร่วมกันระหว่างหน้ารวมงาน หน้ารายละเอียด และหน้ารับรถ
/// หน้าที่แก้ข้อมูลเรียก refresh() เพื่อให้หน้ารวมงานอัปเดตทันที
class JobBoardState extends ChangeNotifier {
  JobBoardState({JobRepository? jobs}) : _jobs = jobs ?? JobRepository();

  final JobRepository _jobs;

  JobStatus? _filter;
  List<Job> _items = const [];
  Map<JobStatus, int> _counts = const {};
  bool _loading = false;
  Object? _error;

  JobStatus? get filter => _filter;
  List<Job> get items => _items;
  bool get loading => _loading;
  Object? get error => _error;
  int countOf(JobStatus s) => _counts[s] ?? 0;
  int get totalOpen => _counts.values.fold(0, (a, b) => a + b);

  Future<void> setFilter(JobStatus? status) async {
    _filter = status;
    await refresh();
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _jobs.activeJobs(filter: _filter),
        _jobs.countByStatus(),
      ]);
      _items = results[0] as List<Job>;
      _counts = results[1] as Map<JobStatus, int>;
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
