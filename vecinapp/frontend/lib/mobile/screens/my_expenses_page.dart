import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/services/common_expense_service.dart';
import 'package:vecinapp/core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de historial de gastos comunes del residente
class MyExpensesPage extends StatefulWidget {
  const MyExpensesPage({super.key});

  @override
  State<MyExpensesPage> createState() => _MyExpensesPageState();
}

class _MyExpensesPageState extends State<MyExpensesPage> {
  final CommonExpenseService _service = CommonExpenseService();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  
  List<Map<String, dynamic>> _expenses = [];
  Map<String, dynamic>? _selectedExpense;
  bool _isLoading = false;
  String? _communityId;
  String _selectedPeriod = '';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    print('🔍 MyExpensesPage: Iniciando carga de gastos...');
    setState(() => _isLoading = true);
    
    try {
      // Obtener community_id del usuario autenticado
      final authService = AuthService();
      final user = authService.currentUser;
      
      print('👤 Usuario actual: ${user?.uid}');
      
      if (user != null) {
        final db = FirebaseFirestore.instance;
        final userDoc = await db.collection('users').doc(user.uid).get();
        
        print('📄 Usuario existe en Firestore: ${userDoc.exists}');
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          _communityId = userData?['communityId'] as String?;
          
          print('🏘️ Community ID: $_communityId');
          
          if (_communityId != null) {
            final expenses = await _service.getMyExpenses(communityId: _communityId!);
            
            print('💰 Gastos obtenidos: ${expenses.length}');
            if (expenses.isNotEmpty) {
              print('📊 Primer gasto: ${expenses.first}');
            }
            
            setState(() {
              _expenses = expenses;
              _isLoading = false;
              
              // Seleccionar el más reciente por defecto
              if (_expenses.isNotEmpty) {
                _selectedExpense = _expenses.first;
                _selectedPeriod = _selectedExpense!['period'] ?? '';
                print('✅ Gasto seleccionado: $_selectedPeriod');
              } else {
                print('⚠️ No hay gastos disponibles');
              }
            });
          } else {
            print('❌ Usuario sin community_id');
            setState(() => _isLoading = false);
          }
        } else {
          print('❌ Usuario no encontrado en Firestore');
          setState(() => _isLoading = false);
        }
      } else {
        print('❌ No hay usuario autenticado');
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      print('💥 Error cargando gastos: $e');
      print('📍 Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _downloadPDF() async {
    if (_selectedExpense == null || _communityId == null) return;
    
    try {
      final expenseId = _selectedExpense!['id'] as String;
      
      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Generando enlace de descarga...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // 1. Solicitar token temporal al backend
      final tokenResponse = await _service.generateDownloadToken(
        communityId: _communityId!,
        expenseId: expenseId,
      );
      
      final token = tokenResponse['token'] as String;
      
      // 2. Construir URL con el token
      final baseUrl = 'http://localhost:8000'; // TODO: Obtener de configuración
      final pdfUrl = '$baseUrl/common-expenses/my-expenses/$expenseId/pdf?community_id=$_communityId&token=$token';
      
      // 3. Abrir URL en navegador/visor externo
      final uri = Uri.parse(pdfUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF abierto correctamente'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el PDF'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      print('Error al descargar PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'closed':
        return Colors.blue;
      case 'notified':
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  String _getStatusName(String status) {
    switch (status) {
      case 'closed':
        return 'Cerrado';
      case 'notified':
        return 'Notificado';
      case 'draft':
        return 'Borrador';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Gastos Comunes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay gastos comunes disponibles',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Selector de período
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPeriod,
                              decoration: const InputDecoration(
                                labelText: 'Período',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: _expenses.map((expense) {
                                final period = expense['period'] as String;
                                return DropdownMenuItem<String>(
                                  value: period,
                                  child: Text(period),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedPeriod = value;
                                    _selectedExpense = _expenses.firstWhere(
                                      (e) => e['period'] == value,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _downloadPDF,
                            icon: const Icon(Icons.download),
                            label: const Text('Descargar PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Divider(height: 1),
                    
                    // Detalle del gasto seleccionado
                    if (_selectedExpense != null)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card de resumen
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Total a Pagar',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _currencyFormat.format(_selectedExpense!['total_amount']),
                                                  style: const TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(_selectedExpense!['status']).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _getStatusColor(_selectedExpense!['status']),
                                              ),
                                            ),
                                            child: Text(
                                              _getStatusName(_selectedExpense!['status']),
                                              style: TextStyle(
                                                color: _getStatusColor(_selectedExpense!['status']),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _InfoChip(
                                              icon: Icons.calendar_today,
                                              label: 'Período',
                                              value: _selectedExpense!['period'],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _InfoChip(
                                              icon: Icons.event_available,
                                              label: 'Fecha Cierre',
                                              value: _selectedExpense!['closed_at'] != null
                                                  ? DateFormat('dd/MM/yyyy').format(
                                                      DateTime.parse(_selectedExpense!['closed_at'])
                                                    )
                                                  : '-',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Mis Unidades
                              const Text(
                                'Mis Unidades',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              ...(_selectedExpense!['my_units'] as List<dynamic>).map((unit) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.home,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Unidad ${unit['unit_name']}',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Alícuota: ${(unit['alicuota'] * 100).toStringAsFixed(2)}%',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _currencyFormat.format(unit['amount']),
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
