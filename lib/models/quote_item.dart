/// ประเภทรายการในใบเสนอราคา: ผู้ใช้ขอให้แยกค่าอะไหล่กับค่าแรง (R3)
enum ItemKind {
  part('part', 'ค่าอะไหล่'),
  labor('labor', 'ค่าแรง');

  const ItemKind(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static ItemKind fromDb(String v) =>
      ItemKind.values.firstWhere((k) => k.dbValue == v, orElse: () => part);
}

/// ผลการตัดสินใจของลูกค้าต่อรายการ
enum Decision {
  pending('pending', 'รอลูกค้าตอบ'),
  approved('approved', 'อนุมัติ'),
  rejected('rejected', 'ไม่อนุมัติ');

  const Decision(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static Decision fromDb(String v) =>
      Decision.values.firstWhere((d) => d.dbValue == v, orElse: () => pending);
}

class QuoteItem {
  const QuoteItem({
    required this.id,
    required this.jobId,
    required this.description,
    required this.kind,
    required this.amount,
    required this.decision,
  });

  final int id;
  final int jobId;
  final String description;
  final ItemKind kind;

  /// ราคาเป็นบาท
  final double amount;
  final Decision decision;

  factory QuoteItem.fromMap(Map<String, Object?> m) => QuoteItem(
        id: m['id'] as int,
        jobId: m['job_id'] as int,
        description: m['description'] as String,
        kind: ItemKind.fromDb(m['kind'] as String),
        amount: (m['amount'] as num).toDouble(),
        decision: Decision.fromDb(m['decision'] as String),
      );
}
