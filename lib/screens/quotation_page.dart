import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/job_repository.dart';
import '../data/quote_repository.dart';
import '../models/job.dart';
import '../models/job_status.dart';
import '../models/quote_item.dart';
import '../services/quote_calculator.dart';
import '../widgets/feedback.dart';
import '../widgets/format.dart';
import '../widgets/quote_widgets.dart';

/// R3 ฝั่งร้าน: ทำใบเสนอราคา แยกค่าอะไหล่กับค่าแรง แล้วส่งให้ลูกค้าอนุมัติ
class QuotationPage extends StatefulWidget {
  const QuotationPage({super.key, required this.jobId});
  final int jobId;

  @override
  State<QuotationPage> createState() => _QuotationPageState();
}

class _QuotationData {
  const _QuotationData(this.job, this.items);
  final Job job;
  final List<QuoteItem> items;
}

class _QuotationPageState extends State<QuotationPage> {
  final _quotes = QuoteRepository();
  final _jobs = JobRepository();
  late Future<_QuotationData> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_QuotationData> _load() async => _QuotationData(
      await _jobs.jobById(widget.jobId), await _quotes.itemsFor(widget.jobId));

  void _reload() => setState(() {
  _future = _load();
  });

  Future<void> _run(Future<void> Function() action, String ok) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      showSuccess(context, ok);
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addItem() async {
    final result = await showModalBottomSheet<_NewItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddItemSheet(),
    );
    if (result == null) return;
    await _run(
      () => _quotes.addItem(
        jobId: widget.jobId,
        description: result.description,
        kind: result.kind,
        amount: result.amount,
      ),
      'เพิ่ม "${result.description}" แล้ว',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_QuotationData>(
      future: _future,
      builder: (context, snap) {
        final data = snap.data;
        final editable = data != null &&
            data.job.status != JobStatus.closed &&
            data.job.status != JobStatus.done;
        return Scaffold(
          appBar: AppBar(
            title: Text(data == null ? 'ใบเสนอราคา' : 'ใบเสนอราคา ${data.job.plate}'),
          ),
          floatingActionButton: editable
              ? FloatingActionButton.extended(
                  onPressed: _busy ? null : _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('เพิ่มรายการ'),
                )
              : null,
          body: () {
            if (snap.hasError) {
              return ErrorRetry(error: snap.error!, onRetry: _reload);
            }
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildBody(data, editable);
          }(),
        );
      },
    );
  }

  Widget _buildBody(_QuotationData data, bool editable) {
    final summary = QuoteCalculator.summarize(data.items);
    final parts = data.items.where((i) => i.kind == ItemKind.part).toList();
    final labor = data.items.where((i) => i.kind == ItemKind.labor).toList();
    final hasPending = data.items.any((i) => i.decision == Decision.pending);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (data.items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text('ยังไม่มีรายการ กด "เพิ่มรายการ" เพื่อเริ่มทำใบเสนอราคา',
                textAlign: TextAlign.center),
          ),
        if (parts.isNotEmpty) _group(ItemKind.part.label, parts, editable),
        if (labor.isNotEmpty) _group(ItemKind.labor.label, labor, editable),
        const SizedBox(height: 12),
        QuoteTotals(summary: summary),
        const SizedBox(height: 16),
        if (editable)
          FilledButton.icon(
            onPressed: (!_busy && hasPending)
                ? () => _run(() => _quotes.sendForApproval(widget.jobId),
                    'ส่งใบเสนอราคาให้ลูกค้าแล้ว สถานะเป็น "รออนุมัติ"')
                : null,
            icon: const Icon(Icons.send),
            label: Text(data.job.status == JobStatus.waitingApproval
                ? 'ส่งให้ลูกค้าอนุมัติอีกครั้ง'
                : 'ส่งให้ลูกค้าอนุมัติ'),
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
      ],
    );
  }

  Widget _group(String title, List<QuoteItem> items, bool editable) {
    final subtotal = items.fold<double>(0, (s, i) => s + i.amount);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Column(children: [
          ListTile(
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text('เสนอ ${baht(subtotal)}'),
          ),
          const Divider(height: 1),
          for (final item in items)
            ListTile(
              title: Text(item.description),
              subtitle: DecisionBadge(item.decision),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(baht(item.amount),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (editable && item.decision == Decision.pending)
                  IconButton(
                    tooltip: 'ลบรายการ',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _busy
                        ? null
                        : () => _run(() => _quotes.deleteItem(item),
                            'ลบ "${item.description}" แล้ว'),
                  ),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _NewItem {
  const _NewItem(this.description, this.kind, this.amount);
  final String description;
  final ItemKind kind;
  final double amount;
}

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet();

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _desc = TextEditingController();
  final _amount = TextEditingController();
  ItemKind _kind = ItemKind.part;

  @override
  void dispose() {
    _desc.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _NewItem(_desc.text.trim(), _kind, double.parse(_amount.text.trim())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('เพิ่มรายการ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SegmentedButton<ItemKind>(
              segments: [
                for (final k in ItemKind.values)
                  ButtonSegment(value: k, label: Text(k.label)),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'ชื่อรายการ',
                hintText: _kind == ItemKind.part ? 'เช่น ผ้าเบรกหน้า' : 'เช่น ค่าแรงเปลี่ยนผ้าเบรก',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อรายการ' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount,
              decoration:
                  const InputDecoration(labelText: 'ราคา', suffixText: 'บาท'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                if (n == null) return 'กรุณากรอกราคาเป็นตัวเลข';
                if (n <= 0) return 'ราคาต้องมากกว่า 0';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('เพิ่ม'),
            ),
          ],
        ),
      ),
    );
  }
}
