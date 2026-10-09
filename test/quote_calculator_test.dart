import 'package:flutter_test/flutter_test.dart';
import 'package:pm_garage/models/quote_item.dart';
import 'package:pm_garage/services/quote_calculator.dart';

QuoteItem item(int id, ItemKind kind, double amount, Decision d) => QuoteItem(
      id: id,
      jobId: 1,
      description: 'รายการ $id',
      kind: kind,
      amount: amount,
      decision: d,
    );

void main() {
  group('QuoteCalculator (R3)', () {
    test('ไม่มีรายการ ยอดเป็น 0 และยังไม่ถือว่าตอบครบ', () {
      final s = QuoteCalculator.summarize([]);
      expect(s.totalApproved, 0);
      expect(s.allDecided, isFalse);
    });

    test('นับยอดเฉพาะรายการที่อนุมัติ และแยกอะไหล่กับค่าแรง', () {
      final s = QuoteCalculator.summarize([
        item(1, ItemKind.part, 900, Decision.approved),
        item(2, ItemKind.part, 350, Decision.rejected),
        item(3, ItemKind.labor, 1500, Decision.approved),
      ]);
      expect(s.partsApproved, 900);
      expect(s.laborApproved, 1500);
      expect(s.totalApproved, 2400);
      expect(s.totalProposed, 2750);
      expect(s.rejectedCount, 1);
      expect(s.allDecided, isTrue);
    });

    test('ยังมีรายการรอตอบ ถือว่ายังตอบไม่ครบ', () {
      final s = QuoteCalculator.summarize([
        item(1, ItemKind.part, 900, Decision.approved),
        item(2, ItemKind.labor, 300, Decision.pending),
      ]);
      expect(s.pendingCount, 1);
      expect(s.allDecided, isFalse);
      expect(s.totalApproved, 900);
    });

    test('ไม่อนุมัติทุกรายการ ยอดเป็น 0 แต่ตอบครบแล้ว', () {
      final s = QuoteCalculator.summarize([
        item(1, ItemKind.part, 900, Decision.rejected),
        item(2, ItemKind.labor, 300, Decision.rejected),
      ]);
      expect(s.totalApproved, 0);
      expect(s.allDecided, isTrue);
      expect(s.approvedCount, 0);
    });
  });
}
