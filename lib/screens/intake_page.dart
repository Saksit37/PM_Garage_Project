import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/customer_repository.dart';
import '../widgets/feedback.dart';

/// R1: รับรถ บันทึกลูกค้า เบอร์ ทะเบียน รุ่น และอาการในหน้าเดียว
/// ถ้าทะเบียนหรือเบอร์เคยมาแล้ว ระบบดึงข้อมูลเดิมมาเติมให้
/// คืนค่า true เมื่อบันทึกสำเร็จ
class IntakePage extends StatefulWidget {
  const IntakePage({super.key, this.prefill});

  /// เติมข้อมูลมาให้ก่อน เช่น กด "รับรถคันนี้" จากหน้าค้นหา
  final IntakePrefill? prefill;

  @override
  State<IntakePage> createState() => _IntakePageState();
}

class _IntakePageState extends State<IntakePage> {
  final _formKey = GlobalKey<FormState>();
  final _plate = TextEditingController();
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _model = TextEditingController();
  final _symptom = TextEditingController();
  final _repo = CustomerRepository();

  bool _saving = false;
  bool _lookingUp = false;
  String? _foundNote;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p != null) _apply(p, overwrite: true);
  }

  @override
  void dispose() {
    for (final c in [_plate, _phone, _name, _model, _symptom]) {
      c.dispose();
    }
    super.dispose();
  }

  void _apply(IntakePrefill p, {bool overwrite = false}) {
    void set(TextEditingController c, String? v) {
      if (v == null || v.isEmpty) return;
      if (overwrite || c.text.trim().isEmpty) c.text = v;
    }

    set(_plate, p.plate);
    set(_phone, p.phone);
    set(_name, p.name);
    set(_model, p.model);
  }

  /// เรียกเมื่อกรอกทะเบียนหรือเบอร์เสร็จ
  Future<void> _lookup() async {
    if (_lookingUp) return;
    setState(() => _lookingUp = true);
    try {
      final found = await _repo.lookupForIntake(
          plate: _plate.text, phone: _phone.text);
      if (!mounted) return;
      setState(() {
        if (found != null) {
          _apply(found);
          _foundNote = found.plate != null
              ? 'พบรถคันนี้ในระบบ เติมข้อมูลเดิมให้แล้ว'
              : 'พบลูกค้าเบอร์นี้ในระบบ เติมชื่อให้แล้ว';
        } else {
          _foundNote = null;
        }
      });
    } catch (e) {
      if (mounted) showError(context, e, onRetry: _lookup);
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _repo.receiveVehicle(
        name: _name.text,
        phone: _phone.text,
        plate: _plate.text,
        model: _model.text,
        symptom: _symptom.text,
      );
      if (!mounted) return;
      showSuccess(context, 'บันทึกการรับรถ ${_plate.text.trim()} แล้ว');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showError(context, e, onRetry: _save);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? 'กรุณากรอก$label' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รับรถเข้าซ่อม')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionLabel('ข้อมูลรถ'),
            TextFormField(
              controller: _plate,
              decoration: InputDecoration(
                labelText: 'ทะเบียนรถ',
                hintText: 'เช่น กข 1234',
                suffixIcon: _lookingUp
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : IconButton(
                        tooltip: 'ดึงข้อมูลเดิม',
                        icon: const Icon(Icons.manage_search),
                        onPressed: _lookup,
                      ),
              ),
              textInputAction: TextInputAction.next,
              onEditingComplete: () {
                _lookup();
                FocusScope.of(context).nextFocus();
              },
              validator: (v) => _required(v, 'ทะเบียนรถ'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _model,
              decoration: const InputDecoration(
                  labelText: 'ยี่ห้อ / รุ่น (ถ้ามี)', hintText: 'เช่น Toyota Vios'),
              textInputAction: TextInputAction.next,
            ),
            if (_foundNote != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(_foundNote!,
                        style: const TextStyle(color: Colors.green))),
              ]),
            ],
            const SizedBox(height: 20),
            const _SectionLabel('ข้อมูลลูกค้า'),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(
                  labelText: 'เบอร์โทร', hintText: '0812345678'),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\- ]')),
              ],
              textInputAction: TextInputAction.next,
              onEditingComplete: () {
                _lookup();
                FocusScope.of(context).nextFocus();
              },
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length < 9 || digits.length > 10) {
                  return 'เบอร์โทรต้องมี 9–10 หลัก';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'ชื่อลูกค้า'),
              textInputAction: TextInputAction.next,
              validator: (v) => _required(v, 'ชื่อลูกค้า'),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('อาการที่ลูกค้าแจ้ง'),
            TextFormField(
              controller: _symptom,
              decoration: const InputDecoration(
                  hintText: 'เช่น แอร์ไม่เย็น มีเสียงดังตอนเบรก'),
              minLines: 3,
              maxLines: 5,
              validator: (v) => _required(v, 'อาการรถ'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'กำลังบันทึก...' : 'บันทึกการรับรถ'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black54)),
      );
}
