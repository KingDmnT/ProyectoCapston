import 'package:flutter/material.dart';
import 'package:vecinapp/core/models/common_expense.dart';

/// Diálogo modal para crear o editar un gasto común
class CommonExpenseFormDialog extends StatefulWidget {
  final String communityId;
  final CommonExpense? expense;
  final VoidCallback onSaved;

  const CommonExpenseFormDialog({
    super.key,
    required this.communityId,
    this.expense,
    required this.onSaved,
  });

  @override
  State<CommonExpenseFormDialog> createState() => _CommonExpenseFormDialogState();
}

class _CommonExpenseFormDialogState extends State<CommonExpenseFormDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.expense == null ? 'Crear Gasto Común' : 'Editar Gasto Común'),
      content: const Text('Formulario en construcción...'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: widget.onSaved,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
