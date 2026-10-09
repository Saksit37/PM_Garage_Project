import 'package:flutter/material.dart';

import '../models/job_status.dart';

/// ป้ายสถานะงาน สีตาม JobStatus
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.dense = false});

  final JobStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
            status.color.withAlpha(30), Theme.of(context).colorScheme.surface),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.color.withAlpha(90)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontWeight: FontWeight.w600,
          fontSize: dense ? 12 : 13,
        ),
      ),
    );
  }
}
