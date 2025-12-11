import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/services/camera_service.dart';
import 'package:vecinapp/core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum StreamMode { snapshot, mjpeg }

class CamerasScreen extends StatefulWidget {
  const CamerasScreen({super.key});

  @override
  State<CamerasScreen> createState() => _CamerasScreenState();
}

class _CamerasScreenState extends State<CamerasScreen> {
  final CameraService _cameraService = CameraService();
  final AuthService _authService = AuthService();
  
  String? _communityId;
  int _gridSize = 2; // 1=1x1, 2=2x2, 3=3x3
  bool _isLoading = false;
  Map<String, dynamic> _config = {};
  List<dynamic> _channels = [];
  bool _testingConnection = false;
  bool _streamingEnabled = false;
  Timer? _refreshTimer;
  int _refreshCounter = 0; // Para forzar refresh de imágenes
  StreamMode _streamMode = StreamMode.snapshot; // Modo de streaming

  @override
  void initState() {
    super.initState();
    _loadCommunityAndConfig();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _toggleStreaming() {
    setState(() {
      _streamingEnabled = !_streamingEnabled;
      
      if (_streamingEnabled) {
        // Iniciar timer para refrescar cada 2 segundos
        _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
          setState(() => _refreshCounter++);
        });
      } else {
        // Detener timer
        _refreshTimer?.cancel();
        _refreshTimer = null;
      }
    });
  }

  Future<void> _loadCommunityAndConfig() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        _communityId = doc.data()?['communityId'];
        
        if (_communityId != null) {
          final config = await _cameraService.getConfig(_communityId!);
          setState(() => _config = config);
          
          // Auto-cargar canales si hay config
          if (config.isNotEmpty) {
            _loadChannels();
          }
        }
      }
    } catch (e) {
      // Ignorar error si no hay config
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChannels() async {
    if (_communityId == null) return;
    try {
      final channels = await _cameraService.getChannels(_communityId!);
      setState(() => _channels = channels);
    } catch (e) {
      print('Error cargando canales: $e');
    }
  }

  Future<void> _testConnection() async {
    if (_communityId == null) return;
    
    setState(() => _testingConnection = true);
    
    final result = await _cameraService.testConnection(_communityId!);
    
    setState(() => _testingConnection = false);
    
    if (mounted) {
      final status = result['status'] as String?;
      final message = result['message'] as String?;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Resultado desconocido'),
          backgroundColor: status == 'online' ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showConfigDialog() {
    final ipController = TextEditingController(text: _config['nvr_ip']);
    final portController = TextEditingController(text: _config['nvr_port']?.toString() ?? '80');
    final userController = TextEditingController(text: _config['username']);
    final passController = TextEditingController(text: _config['password']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración NVR Hikvision'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Configura la conexión al NVR. Podrás visualizar múltiples cámaras según los canales disponibles en tu dispositivo.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ipController,
                decoration: const InputDecoration(
                  labelText: 'IP / Host NVR',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: portController,
                decoration: const InputDecoration(
                  labelText: 'Puerto HTTP',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: userController,
                decoration: const InputDecoration(
                  labelText: 'Usuario ISAPI',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: _testingConnection ? null : _testConnection,
            child: _testingConnection
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Probar Conexión'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_communityId == null) return;
              
              final newConfig = {
                'nvr_ip': ipController.text,
                'nvr_port': int.tryParse(portController.text) ?? 80,
                'username': userController.text,
                'password': passController.text,
              };

              try {
                await _cameraService.saveConfig(_communityId!, newConfig);
                setState(() => _config = newConfig);
                Navigator.pop(context);
                
                // Auto-cargar canales después de guardar
                _loadChannels();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Configuración guardada exitosamente')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotStream(int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        _streamingEnabled 
            ? '${_cameraService.getSnapshotUrl(_communityId!, _channels[index]['id'])}?t=$_refreshCounter'
            : _cameraService.getSnapshotUrl(_communityId!, _channels[index]['id']),
        key: ValueKey('camera_${_channels[index]['id']}_$_refreshCounter'),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off, color: Colors.grey[700], size: 48),
                const SizedBox(height: 8),
                Text('Sin Señal', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMjpegStream(int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        _cameraService.getMjpegUrl(_communityId!, _channels[index]['id']),
        key: ValueKey('mjpeg_${_channels[index]['id']}'),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off, color: Colors.grey[700], size: 48),
                const SizedBox(height: 8),
                Text('Stream MJPEG No Disponible', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                const SizedBox(height: 4),
                Text('Verifica config del NVR', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Conectando stream...', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCameraPlaceholder(int index) {
    final isConfigured = _config.isNotEmpty;
    final hasChannel = index < _channels.length;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Mostrar snapshot o MJPEG según el modo
          if (isConfigured && hasChannel)
            _streamMode == StreamMode.mjpeg
                ? _buildMjpegStream(index)
                : _buildSnapshotStream(index)
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isConfigured ? Icons.videocam : Icons.videocam_off,
                    color: Colors.grey[700],
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isConfigured ? 'Canal ${index + 1}' : 'No Configurado',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  if (isConfigured && hasChannel)
                    Text(
                      _channels[index]['name'] ?? 'CH${index + 1}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 11),
                    ),
                ],
              ),
            ),
          // Overlay Info
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                hasChannel && _channels[index]['name'] != null
                    ? _channels[index]['name']
                    : 'CAM ${index + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          if (isConfigured && hasChannel)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Monitoreo CCTV'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCommunityAndConfig,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Controles y Filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Text(
                  'Vista de Grid:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<int>(
                    value: _gridSize,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1x1 (1 cámara)')),
                      DropdownMenuItem(value: 2, child: Text('2x2 (4 cámaras)')),
                      DropdownMenuItem(value: 3, child: Text('3x3 (9 cámaras)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _gridSize = val);
                    },
                  ),
                ),
                const Spacer(),
                // Botón Toggle Streaming
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _streamingEnabled ? AppColors.success : Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: _streamingEnabled ? AppColors.success.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _toggleStreaming,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _streamingEnabled ? Icons.videocam : Icons.videocam_off,
                              color: _streamingEnabled ? AppColors.success : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _streamingEnabled ? 'Streaming Activo' : 'Streaming Pausado',
                              style: TextStyle(
                                color: _streamingEnabled ? AppColors.success : Colors.grey,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Selector de Modo (Snapshot vs MJPEG)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Modo:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      SegmentedButton<StreamMode>(
                        segments: const [
                          ButtonSegment(
                            value: StreamMode.snapshot,
                            label: Text('Snapshot', style: TextStyle(fontSize: 12)),
                            icon: Icon(Icons.photo_camera, size: 16),
                          ),
                          ButtonSegment(
                            value: StreamMode.mjpeg,
                            label: Text('MJPEG', style: TextStyle(fontSize: 12)),
                            icon: Icon(Icons.video_camera_back, size: 16),
                          ),
                        ],
                        selected: {_streamMode},
                        onSelectionChanged: (Set<StreamMode> newSelection) {
                          setState(() {
                            _streamMode = newSelection.first;
                            // Si cambia a MJPEG, desactivar timer (MJPEG ya es continuo)
                            if (_streamMode == StreamMode.mjpeg && _streamingEnabled) {
                              _streamingEnabled = false;
                              _refreshTimer?.cancel();
                              _refreshTimer = null;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showConfigDialog,
                  icon: const Icon(Icons.settings),
                  label: const Text('Configurar NVR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Grid de Cámaras
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _gridSize,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 16 / 9,
                          ),
                          itemCount: _gridSize * _gridSize,
                          itemBuilder: (context, index) => _buildCameraPlaceholder(index),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
