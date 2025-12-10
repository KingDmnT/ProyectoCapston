import 'package:flutter/material.dart';
import 'package:vecinapp/core/models/common_expense.dart';
import 'package:vecinapp/core/services/common_expense_service.dart';

/// Diálogo modal para crear un nuevo gasto común
class CommonExpenseFormDialog extends StatefulWidget {
  final String communityId;
  final Function(CommonExpense) onSaved; // Callback que retorna el gasto creado

  const CommonExpenseFormDialog({
    super.key,
    required this.communityId,
    required this.onSaved,
  });

  @override
  State<CommonExpenseFormDialog> createState() => _CommonExpenseFormDialogState();
}

class _CommonExpenseFormDialogState extends State<CommonExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final CommonExpenseService _service = CommonExpenseService();
  
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Validar si ya existe (opcional, el backend podría rechazarlo)
      
      // 2. Crear objeto preliminar
      // Nota: El ID será asignado por el backend
      final newExpense = CommonExpense(
        id: '', 
        communityId: widget.communityId,
        period: '${CommonExpense.getMonthName(_selectedMonth)} $_selectedYear', // Formato visual, backend usa year/month
        month: _selectedMonth,
        year: _selectedYear,
        status: ExpenseStatus.draft,
        totalAmount: 0,
        items: {},
        unitExpenses: [],
        createdBy: '', // Asignado por backend
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 3. Llamar al servicio
      final created = await _service.createCommonExpense(newExpense);
      
      if (mounted) {
        widget.onSaved(created); // Retornar el gasto creado para abrir detalle
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al crear: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo Gasto Común'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.red[50],
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
                
              const Text('Selecciona el período para el nuevo gasto común.'),
              const SizedBox(height: 20),
              
              DropdownButtonFormField<int>(
                value: _selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Año',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(5, (i) => DateTime.now().year + 1 - i).map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedYear = val!),
              ),
              
              const SizedBox(height: 16),
              
              DropdownButtonFormField<int>(
                value: _selectedMonth,
                decoration: const InputDecoration(
                  labelText: 'Mes',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(12, (i) => i + 1).map((month) {
                  return DropdownMenuItem(
                    value: month,
                    child: Text(CommonExpense.getMonthName(month)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedMonth = val!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Crear y Editar'),
        ),
      ],
    );
  }
}
