import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/models/common_expense.dart';
import 'package:vecinapp/core/services/common_expense_service.dart';
import 'package:vecinapp/core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vecinapp/admin/screens/common_expenses/common_expense_form_dialog.dart';
import 'package:vecinapp/admin/screens/common_expenses/common_expense_detail_dialog.dart';

/// Pantalla principal de gestión de gastos comunes para administradores
class CommonExpensesScreen extends StatefulWidget {
  const CommonExpensesScreen({super.key});

  @override
  State<CommonExpensesScreen> createState() => _CommonExpensesScreenState();
}

class _CommonExpensesScreenState extends State<CommonExpensesScreen> {
  final CommonExpenseService _service = CommonExpenseService();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  
  List<CommonExpense> _allExpenses = [];
  bool _isLoading = false;
  String? _error;
  
  // Filtros
  int? _selectedYear;
  int? _selectedMonth;
  ExpenseStatus? _selectedStatus;
  
  // Comunidad del usuario autenticado
  String? _communityId;

  // Paginación
  String _searchQuery = '';
  int _rowsPerPage = 10;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadCommunityAndExpenses();
  }

  Future<void> _loadCommunityAndExpenses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Obtener community_id del usuario autenticado
      final authService = AuthService();
      final user = authService.currentUser;
      
      if (user != null) {
        final db = FirebaseFirestore.instance;
        final userDoc = await db.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          _communityId = userData?['communityId'] as String?;
          
          if (_communityId != null) {
            await _loadExpenses();
          } else {
            setState(() {
              _error = 'Usuario sin comunidad asignada';
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExpenses() async {
    if (_communityId == null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final expenses = await _service.getCommonExpenses(
        communityId: _communityId!,
        year: _selectedYear,
        month: _selectedMonth,
        status: _selectedStatus?.value,
      );
      
      setState(() {
        _allExpenses = expenses;
        _currentPage = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<CommonExpense> get _filteredExpenses {
    var filtered = _allExpenses.where((expense) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return expense.period.toLowerCase().contains(query) ||
             expense.totalAmount.toString().contains(query);
    }).toList();
    
    return filtered;
  }
  
  List<CommonExpense> get _paginatedExpenses {
    final filtered = _filteredExpenses;
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end);
  }
  
  int get _totalPages => (_filteredExpenses.length / _rowsPerPage).ceil();

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => CommonExpenseFormDialog(
        communityId: _communityId!,
        onSaved: () {
          Navigator.pop(context);
          _loadExpenses();
        },
      ),
    );
  }

  void _showEditDialog(CommonExpense expense) {
    showDialog(
      context: context,
      builder: (context) => CommonExpenseFormDialog(
        communityId: _communityId!,
        expense: expense,
        onSaved: () {
          Navigator.pop(context);
          _loadExpenses();
        },
      ),
    );
  }

  void _showDetailDialog(CommonExpense expense) {
    showDialog(
      context: context,
      builder: (context) => CommonExpenseDetailDialog(
        expense: expense,
        communityId: _communityId!,
        onUpdated: _loadExpenses,
      ),
    );
  }

  Future<void> _closePeriod(CommonExpense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Período'),
        content: Text(
          '¿Estás seguro de cerrar el período ${expense.period}?\n\n'
          'Esto calculará la distribución por unidades y no podrás editar los items.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Período'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _service.closeExpense(
          communityId: _communityId!,
          expenseId: expense.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Período cerrado exitosamente')),
          );
          _loadExpenses();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _notifyResidents(CommonExpense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificar Residentes'),
        content: Text(
          '¿Estás seguro de notificar a todos los residentes sobre el gasto común de ${expense.period}?\n\n'
          'Se enviarán emails con los PDFs adjuntos.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Enviar Notificaciones'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Enviando notificaciones...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final result = await _service.notifyResidents(
          communityId: _communityId!,
          expenseId: expense.id,
        );
        if (mounted) {
          Navigator.pop(context); // Cerrar loading
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Notificaciones Enviadas'),
              content: Text(
                'Total: ${result['total']}\n'
                'Enviados: ${result['sent']}\n'
                'Fallidos: ${result['failed']}'
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          _loadExpenses();
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Cerrar loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteExpense(CommonExpense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Gasto Común'),
        content: Text('¿Estás seguro de eliminar el gasto común de ${expense.period}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _service.deleteCommonExpense(
          communityId: _communityId!,
          expenseId: expense.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gasto común eliminado')),
          );
          _loadExpenses();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Color _getStatusColor(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.draft:
        return Colors.grey;
      case ExpenseStatus.closed:
        return Colors.blue;
      case ExpenseStatus.notified:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestión de Gastos Comunes'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros y Búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Año',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ...List.generate(3, (i) => DateTime.now().year - i).map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedYear = value);
                      _loadExpenses();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar',
                      hintText: 'Período, monto...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onChanged: (value) => setState(() {
                      _searchQuery = value;
                      _currentPage = 0;
                    }),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Mes',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ...List.generate(12, (i) => i + 1).map((month) {
                        return DropdownMenuItem(
                          value: month,
                          child: Text(CommonExpense.getMonthName(month)),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedMonth = value);
                      _loadExpenses();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<ExpenseStatus?>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ...ExpenseStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.displayName),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedStatus = value);
                      _loadExpenses();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Gasto Común'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Tabla
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(child: Text('Error: $_error'))
                            : _paginatedExpenses.isEmpty
                                ? const Center(child: Text('No hay gastos comunes para mostrar'))
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SingleChildScrollView(
                                      child: DataTable(
                                        headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                                        dataRowHeight: 70,
                                        columns: const [
                                          DataColumn(label: Text('Período', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Año', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Mes', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Unidades', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                                        ],
                                        rows: _paginatedExpenses.map((expense) {
                                          return DataRow(cells: [
                                            DataCell(Text(expense.period)),
                                            DataCell(Text(expense.year.toString())),
                                            DataCell(Text(CommonExpense.getMonthName(expense.month))),
                                            DataCell(Text(_currencyFormat.format(expense.totalAmount))),
                                            DataCell(Text('${expense.unitExpenses.length}')),
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(expense.status).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: _getStatusColor(expense.status)),
                                                ),
                                                child: Text(
                                                  expense.status.displayName,
                                                  style: TextStyle(
                                                    color: _getStatusColor(expense.status),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Ver detalles
                                                  IconButton(
                                                    icon: const Icon(Icons.visibility_outlined,  color: AppColors.primary),
                                                    tooltip: 'Ver detalles',
                                                    onPressed: () => _showDetailDialog(expense),
                                                  ),
                                                  
                                                  // Editar (solo DRAFT)
                                                  if (expense.status == ExpenseStatus.draft)
                                                    IconButton(
                                                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                                      tooltip: 'Editar',
                                                      onPressed: () => _showEditDialog(expense),
                                                    ),
                                                  
                                                  // Cerrar período (solo DRAFT)
                                                  if (expense.status == ExpenseStatus.draft)
                                                    IconButton(
                                                      icon: const Icon(Icons.check_circle, color: AppColors.success),
                                                      tooltip: 'Cerrar período',
                                                      onPressed: () => _closePeriod(expense),
                                                    ),
                                                  
                                                  // Notificar (solo CLOSED)
                                                  if (expense.status == ExpenseStatus.closed)
                                                    IconButton(
                                                      icon: const Icon(Icons.email_outlined, color: Colors.blue),
                                                      tooltip: 'Notificar residentes',
                                                      onPressed: () => _notifyResidents(expense),
                                                    ),
                                                  
                                                  // Eliminar (solo DRAFT)
                                                  if (expense.status == ExpenseStatus.draft)
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                                      tooltip: 'Eliminar',
                                                      onPressed: () => _deleteExpense(expense),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ]);
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                  ),
                  
                  // Pagination
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: [
                        const Text('Filas por página:', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _rowsPerPage,
                          underline: Container(),
                          items: [5, 10, 20, 50].map((value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('$value'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _rowsPerPage = value;
                                _currentPage = 0;
                              });
                            }
                          },
                        ),
                        
                        const Spacer(),
                        
                        Text(
                          'Mostrando ${_paginatedExpenses.isEmpty ? 0 : _currentPage * _rowsPerPage + 1}-${(_currentPage * _rowsPerPage + _paginatedExpenses.length).clamp(0, _filteredExpenses.length)} de ${_filteredExpenses.length}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentPage > 0
                              ? () => setState(() => _currentPage--)
                              : null,
                        ),
                        Text('${_currentPage + 1} / ${_totalPages == 0 ? 1 : _totalPages}'),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _currentPage < _totalPages - 1
                              ? () => setState(() => _currentPage++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
