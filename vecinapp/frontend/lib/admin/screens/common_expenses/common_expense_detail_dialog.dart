import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vecinapp/core/models/common_expense.dart';
import 'package:vecinapp/core/services/common_expense_service.dart';
import 'package:vecinapp/core/theme/app_theme.dart';

/// Diálogo modal para ver y editar el detalle completo del gasto común
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

class _CommonExpenseDetailDialogState extends State<CommonExpenseDetailDialog> with TickerProviderStateMixin {
  final CommonExpenseService _service = CommonExpenseService();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
  
  late CommonExpense _currentExpense;
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentExpense = widget.expense;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Refrescar datos desde el servidor
  Future<void> _refreshExpense() async {
    setState(() => _isLoading = true);
    try {
      final updated = await _service.getCommonExpenseById(
        communityId: widget.communityId,
        expenseId: _currentExpense.id,
      );
      if (mounted) {
        setState(() {
          _currentExpense = updated;
          _isLoading = false;
        });
        widget.onUpdated(); // Notificar al padre que hubo cambios
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al refrescar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Guardar cambios en los items
  Future<void> _saveItemsChanges() async {
    setState(() => _isLoading = true);
    try {
      // Serializar items actuales para enviar update
      // CommonExpense.toJson() ya maneja la serialización correcta de items
      final json = _currentExpense.toJson();
      final itemsJson = json['items'];

      await _service.updateCommonExpense(
        communityId: widget.communityId,
        expenseId: _currentExpense.id,
        updates: {'items': itemsJson},
      );

      await _refreshExpense(); // Recargar para confirmar y actualizar totales
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados correctamente'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Agregar o Editar Item
  void _showItemDialog(String categoryKey, [ExpenseLineItem? item, int? index]) {
    final isEditing = item != null;
    final descController = TextEditingController(text: item?.description ?? '');
    final amountController = TextEditingController(text: item?.amount.toStringAsFixed(0) ?? '');
    final docNumberController = TextEditingController(text: item?.docNumber ?? '');
    
    DateTime? selectedDate = item?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isEditing ? 'Editar Ítem' : 'Agregar Ítem'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Monto (\$)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: docNumberController,
                    decoration: const InputDecoration(labelText: 'N° Documento (Opcional)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(selectedDate == null 
                        ? 'Sin fecha' 
                        : 'Fecha: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}'),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setStateDialog(() => selectedDate = date);
                          }
                        },
                        child: const Text('Cambiar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final desc = descController.text.trim();
                  final amount = double.tryParse(amountController.text.replaceAll('.', '')) ?? 0.0;
                  
                  if (desc.isEmpty || amount <= 0) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Descripción y monto válido requeridos')),
                    );
                    return;
                  }

                  final newItem = ExpenseLineItem(
                    description: desc,
                    amount: amount,
                    docNumber: docNumberController.text.isEmpty ? null : docNumberController.text,
                    date: selectedDate,
                  );

                  // Actualizar estado local
                  setState(() {
                    if (isEditing) {
                      _currentExpense.items[categoryKey]![index!] = newItem;
                    } else {
                      if (!_currentExpense.items.containsKey(categoryKey)) {
                         _currentExpense.items[categoryKey] = [];
                      }
                      _currentExpense.items[categoryKey]!.add(newItem);
                    }
                  });

                  Navigator.pop(context);
                  _saveItemsChanges(); // Guardar en backend
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteItem(String categoryKey, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ítem'),
        content: const Text('¿Estás seguro de eliminar este ítem?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _currentExpense.items[categoryKey]!.removeAt(index);
              });
              Navigator.pop(context);
              _saveItemsChanges();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(ExpenseCategory category) {
    final categoryKey = category.value;
    final items = _currentExpense.items[categoryKey] ?? [];
    final canEdit = _currentExpense.status == ExpenseStatus.draft;

    return Column(
      children: [
        // Header de acciones
        if (canEdit)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showItemDialog(categoryKey),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar Línea'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        
        // Tabla de items
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No hay gastos registrados en esta categoría'))
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Descripción')),
                        DataColumn(label: Text('Fecha')),
                        DataColumn(label: Text('Doc.')),
                        DataColumn(label: Text('Monto')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return DataRow(
                          cells: [
                            DataCell(Text(item.description, style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text(item.date != null ? DateFormat('dd/MM/yyyy').format(item.date!) : '-')),
                            DataCell(Text(item.docNumber ?? '-')),
                            DataCell(Text(_currencyFormat.format(item.amount))),
                            DataCell(
                              canEdit 
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      onPressed: () => _showItemDialog(categoryKey, item, index),
                                      tooltip: 'Editar',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _deleteItem(categoryKey, index),
                                      tooltip: 'Eliminar',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
        
        // Total Categoría
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Total ${category.displayName}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                _currencyFormat.format(_currentExpense.getCategoryTotal(categoryKey)),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
       backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.2),
               blurRadius: 10,
               offset: const Offset(0, 4),
             )
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalle Gasto Común: ${_currentExpense.period}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _currentExpense.status == ExpenseStatus.draft 
                                  ? Colors.orange.withOpacity(0.2) 
                                  : Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _currentExpense.status.displayName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold,
                                  color: _currentExpense.status == ExpenseStatus.draft 
                                    ? Colors.orange[800] 
                                    : Colors.blue[800],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Total: ${_currencyFormat.format(_currentExpense.totalAmount)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Remuneraciones'),
                Tab(text: 'Gastos Extra.'),
                Tab(text: 'Mantención'),
                Tab(text: 'Servicios Comunes'),
              ],
            ),
            
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCategoryTab(ExpenseCategory.remuneraciones),
                      _buildCategoryTab(ExpenseCategory.gastosExtraordinarios),
                      _buildCategoryTab(ExpenseCategory.mantencion),
                      _buildCategoryTab(ExpenseCategory.serviciosComunes),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
