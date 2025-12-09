import 'package:flutter/material.dart';
import 'package:vecinapp/core/models/common_expense.dart';

/// Diálogo modal para ver el detalle completo del gasto común
class CommonExpenseDetailDialog extends StatefulWidget {
  final CommonExpense expense;
  final String communityId;
  final VoidCallback onUpdated;

  const CommonExpenseDetailDialog({
    super.key,
    required this.expense,
    required this.communityId,
    required this.onUpdated,
  });

  @override
  State<CommonExpenseDetailDialog> createState() => _CommonExpenseDetailDialogState();
}

class _CommonExpenseDetailDialogState extends State<CommonExpenseDetailDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Detalle: ${widget.expense.period}'),
      content: const Text('Vista de detalle en construcción...'),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
