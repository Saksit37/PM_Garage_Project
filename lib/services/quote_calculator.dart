import '../models/quote_item.dart';

/// สรุปยอดใบเสนอราคา (R3)
/// ยอดที่ต้องจ่ายจริงนับเฉพาะรายการที่ลูกค้า "อนุมัติ" และแยกค่าอะไหล่กับค่าแรง
class QuoteSummary {
  const QuoteSummary({
    required this.partsApproved,
    required this.laborApproved,
    required this.totalProposed,
    required this.approvedCount,
    required this.rejectedCount,
    required this.pendingCount,
  });

  final double partsApproved;
  final double laborApproved;

  /// ยอดรวมของทุกรายการที่ร้านเสนอ (ก่อนลูกค้าเลือก)
  final double totalProposed;
  final int approvedCount;
  final int rejectedCount;
  final int pendingCount;

  double get totalApproved => partsApproved + laborApproved;
  int get itemCount => approvedCount + rejectedCount + pendingCount;

  /// ลูกค้าตอบครบทุกรายการแล้ว
  bool get allDecided => itemCount > 0 && pendingCount == 0;

  static const empty = QuoteSummary(
    partsApproved: 0,
    laborApproved: 0,
    totalProposed: 0,
    approvedCount: 0,
    rejectedCount: 0,
    pendingCount: 0,
  );
}

class QuoteCalculator {
  const QuoteCalculator._();

  static QuoteSummary summarize(List<QuoteItem> items) {
    var parts = 0.0;
    var labor = 0.0;
    var proposed = 0.0;
    var approved = 0;
    var rejected = 0;
    var pending = 0;

    for (final item in items) {
      proposed += item.amount;
      switch (item.decision) {
        case Decision.approved:
          approved++;
          if (item.kind == ItemKind.part) {
            parts += item.amount;
          } else {
            labor += item.amount;
          }
        case Decision.rejected:
          rejected++;
        case Decision.pending:
          pending++;
      }
    }

    return QuoteSummary(
      partsApproved: parts,
      laborApproved: labor,
      totalProposed: proposed,
      approvedCount: approved,
      rejectedCount: rejected,
      pendingCount: pending,
    );
  }
}
