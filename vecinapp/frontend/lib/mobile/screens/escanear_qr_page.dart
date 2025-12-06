import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';

class EscanearQrPage extends StatefulWidget {
  const EscanearQrPage({super.key});

  @override
  State<EscanearQrPage> createState() => _EscanearQrPageState();
}

class _EscanearQrPageState extends State<EscanearQrPage> {
  // Controlador para manejar la cámara
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  final Color azulCorporativo = const Color(0xFF2F3DBE);
  bool _isScanCompleted = false; 

  void _onDetect(BarcodeCapture capture) {
    if (_isScanCompleted) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      setState(() => _isScanCompleted = true);
      final String code = barcodes.first.rawValue ?? "Sin datos";
      
      _mostrarResultado(code);
    }
  }

  void _mostrarResultado(String data) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF43CE88)),
              const SizedBox(width: 10),
              const Text("Lectura Exitosa"),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Datos del Pase:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(data, style: GoogleFonts.sourceCodePro(fontSize: 12)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
                setState(() => _isScanCompleted = false); 
              },
              child: const Text("Escanear Otro"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: azulCorporativo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context); 
                Navigator.pop(context); 
              },
              child: const Text("Finalizar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Escanear Pase", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // BOTÓN FLASH (Corregido para v5)
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller, // Escuchamos al controlador completo
            builder: (context, state, child) {
              // Accedemos a state.torchState
              final bool isTorchOn = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(
                  isTorchOn ? Icons.flash_on : Icons.flash_off, 
                  color: isTorchOn ? Colors.yellow : Colors.grey
                ),
                onPressed: () => controller.toggleTorch(),
              );
            },
          ),
          
          // BOTÓN CAMBIAR CÁMARA (Corregido para v5)
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (context, state, child) {
              // Accedemos a state.cameraDirection
              final bool isFront = state.cameraDirection == CameraFacing.front;
              return IconButton(
                icon: Icon(isFront ? Icons.camera_front : Icons.camera_rear),
                onPressed: () => controller.switchCamera(),
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true, 
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // Overlay decorativo
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: azulCorporativo, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(alignment: Alignment.topLeft, child: _corner()),
                  Align(alignment: Alignment.topRight, child: RotatedBox(quarterTurns: 1, child: _corner())),
                  Align(alignment: Alignment.bottomLeft, child: RotatedBox(quarterTurns: 3, child: _corner())),
                  Align(alignment: Alignment.bottomRight, child: RotatedBox(quarterTurns: 2, child: _corner())),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Apunta el código QR dentro del cuadro",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _corner() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white, width: 4),
          left: BorderSide(color: Colors.white, width: 4),
        ),
      ),
    );
  }
}
