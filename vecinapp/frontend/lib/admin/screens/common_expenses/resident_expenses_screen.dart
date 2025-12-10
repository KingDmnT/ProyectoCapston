
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';
import 'package:http/http.dart' as http; // Mantener para descarga directa de PDF bytes por ahora si el service solo da URL
import '../../../core/services/common_expense_service.dart';
import '../../../core/services/auth_service.dart'; // Para token si es necesario manual

class ResidentExpensesScreen extends StatefulWidget {
  final Map<String, dynamic> expense;
  final String communityId;

  const ResidentExpensesScreen({
    Key? key,
    required this.expense,
    required this.communityId,
  }) : super(key: key);

  @override
  _ResidentExpensesScreenState createState() => _ResidentExpensesScreenState();
}

class _ResidentExpensesScreenState extends State<ResidentExpensesScreen> {
  final CommonExpenseService _service = CommonExpenseService();
  final AuthService _authService = AuthService(); // Para obtener token para el download GET manual
  
  List<dynamic> _residents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchResidents();
  }

  Future<void> _fetchResidents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.getExpenseResidents(
        communityId: widget.communityId,
        expenseId: widget.expense['id'],
      );
      
      if (mounted) {
        setState(() {
          _residents = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsPaid(String residentUid, bool currentStatus) async {
    try {
      final newStatus = !currentStatus;
      await _service.payResidentExpense(
        communityId: widget.communityId,
        expenseId: widget.expense['id'],
        residentUid: residentUid,
        isPaid: newStatus,
      );

      // Recargar lista
      if (mounted) {
        _fetchResidents();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Marcado como pagado' : 'Marcado como pendiente'),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Future<void> _downloadPdf(String residentUid, String residentName) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando PDF...')),
      );
      
      // Obtenemos la URL del servicio
      final urlString = _service.getResidentPdfUrl(
        communityId: widget.communityId,
        expenseId: widget.expense['id'],
        residentUid: residentUid,
      );

      // Nota: Para file_saver necesitamos los bytes.
      // Usamos http.get aquí porque `file_saver` necesita bytes y ApiService encapsula requests JSON habitualmente.
      // Si ApiService tuviera metodo downloadBytes podría usarse. Por ahora, usamos http directo con token helper.
      final token = await _authService.currentUser?.getIdToken();
      final response = await http.get(
        Uri.parse(urlString),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
         await FileSaver.instance.saveFile(
           name: 'gasto_comun_${residentName.replaceAll(" ", "_")}',
           bytes: response.bodyBytes,
           ext: 'pdf',
           mimeType: MimeType.pdf,
         );
         if (mounted) {
           ScaffoldMessenger.of(context).hideCurrentSnackBar();
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('PDF descargado correctamente'), backgroundColor: Colors.green),
           );
         }
      } else {
        throw Exception('Error al descargar PDF: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error descargando PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$');
    final monthNames = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final period = "${monthNames[widget.expense['month']]} ${widget.expense['year']}";

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalle por Residente',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          period,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
            const Divider(height: 1),
            
            // Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Error: $_error'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _residents.length,
                          itemBuilder: (context, index) {
                            final resident = _residents[index];
                            final isPaid = resident['is_paid'] ?? false;
                            final unitNames = (resident['units'] as List).join(', ');
                            
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                      child: Icon(
                                        isPaid ? Icons.check_circle : Icons.pending,
                                        color: isPaid ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            resident['resident_name'],
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            unitNames,
                                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            currencyFormat.format(resident['total_amount']),
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C5F8D)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF2C5F8D)),
                                          onPressed: () {
                                            _downloadPdf(resident['resident_uid'], resident['resident_name']);
                                          },
                                          tooltip: 'Descargar Gasto Común',
                                        ),
                                        Switch(
                                          value: isPaid,
                                          onChanged: (val) => _markAsPaid(resident['resident_uid'], isPaid),
                                          activeColor: Colors.green,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
