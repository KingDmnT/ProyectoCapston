import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class GenerarQrVisitaPage extends StatefulWidget {
  final String tipoVisita;
  final String nombreResidente;

  const GenerarQrVisitaPage({
    super.key, 
    required this.tipoVisita,
    required this.nombreResidente,
  });

  @override
  State<GenerarQrVisitaPage> createState() => _GenerarQrVisitaPageState();
}

class _GenerarQrVisitaPageState extends State<GenerarQrVisitaPage> {
  final _nombreCtrl = TextEditingController();
  final _rutCtrl = TextEditingController();
  final _patenteCtrl = TextEditingController();
  
  String? _qrData; 
  bool _mostrarFormulario = true;
  int _selectedIndex = 0; 

  final Color azulCorporativo = const Color(0xFF2F3DBE);

  void _generarCodigo() {
    if (_nombreCtrl.text.trim().isEmpty || _rutCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nombre y RUT son obligatorios"), backgroundColor: Colors.orange),
      );
      return;
    }

    final dataString = """
ACCESO: ${widget.tipoVisita.toUpperCase()}
RESIDENTE: ${widget.nombreResidente}
VISITA: ${_nombreCtrl.text.trim()}
RUT: ${_rutCtrl.text.trim()}
PATENTE: ${_patenteCtrl.text.isEmpty ? 'A PIE' : _patenteCtrl.text.trim()}
FECHA: ${DateTime.now().toString().substring(0, 16)}
""";

    setState(() {
      _qrData = dataString;
      _mostrarFormulario = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            // ENCABEZADO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: BoxDecoration(
                color: azulCorporativo,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          // MODIFICADO: Siempre vuelve atrás (al menú "Gestionar Visitas")
                          // independientemente de si estamos viendo el formulario o el QR.
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          _mostrarFormulario ? "Nueva Visita" : "Pase de Acceso",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Emisor: ${widget.nombreResidente}",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // CONTENIDO
            Expanded(
              child: SingleChildScrollView(
                child: _mostrarFormulario ? _buildFormulario() : _buildQrView(),
              ),
            ),
          ],
        ),
      ),
      
      // BARRA INFERIOR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Colors.white,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: azulCorporativo,
              color: Colors.grey[600],
              textStyle: GoogleFonts.lato(color: Colors.white),
              tabs: const [
                GButton(icon: Icons.home_filled, text: 'Inicio'),
                GButton(icon: Icons.calendar_month_outlined, text: 'Reservas'),
                GButton(icon: Icons.person_outline, text: 'Perfil'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                if (index == 0) Navigator.popUntil(context, ModalRoute.withName('/home'));
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Datos de la Visita", style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            const SizedBox(height: 20),
            
            _buildInput(label: "Nombre Completo", icon: Icons.person, controller: _nombreCtrl),
            const SizedBox(height: 15),
            _buildInput(label: "RUT / DNI", icon: Icons.badge, controller: _rutCtrl),
            const SizedBox(height: 15),
            _buildInput(label: "Patente Vehículo (Opcional)", icon: Icons.directions_car, controller: _patenteCtrl),
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _generarCodigo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulCorporativo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.qr_code_2),
                label: const Text("Generar Código QR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              children: [
                QrImageView(
                  data: _qrData ?? "Error",
                  version: QrVersions.auto,
                  size: 250.0,
                  foregroundColor: azulCorporativo,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  "Muestra este código en portería",
                  style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
                const SizedBox(height: 10),
                Text(
                  "Visita: ${_nombreCtrl.text}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({required String label, required IconData icon, required TextEditingController controller}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: azulCorporativo),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: azulCorporativo, width: 2),
        ),
      ),
    );
  }
}
