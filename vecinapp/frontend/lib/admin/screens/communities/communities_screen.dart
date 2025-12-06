import 'package:flutter/material.dart';
import 'package:vecinapp/core/models/community.dart';
import 'package:vecinapp/core/services/community_service.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:vecinapp/core/utils/chile_data.dart';
import 'package:vecinapp/admin/screens/communities/community_units_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vecinapp/core/services/bulk_upload_service.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final CommunityService _service = CommunityService();
  late Future<List<Community>> _communitiesFuture;

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  void _loadCommunities() {
    setState(() {
      _communitiesFuture = _service.getCommunities();
    });
  }

  Future<void> _handleBulkUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result != null) {
        if (!mounted) return;
        QuickAlert.show(
          context: context,
          type: QuickAlertType.loading,
          title: 'Procesando...',
          text: 'Leyendo archivo Excel y creando registros.',
          barrierDismissible: false,
        );

        final bytes = result.files.first.bytes;
        if (bytes == null) throw Exception("No se pudo leer el archivo");

        final service = BulkUploadService();
        final report = await service.processExcel(bytes);

        if (mounted) Navigator.pop(context); // Cerrar loading

        if (mounted) {
          if (report['errors'].isNotEmpty) {
             QuickAlert.show(
              context: context,
              type: QuickAlertType.warning,
              title: 'Proceso completado con errores',
              text: 'Comunidades: ${report['communities']}, Unidades: ${report['units']}.\nErrores:\n${(report['errors'] as List).take(3).join('\n')}',
            );
          } else {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              title: 'Carga Exitosa',
              text: 'Se crearon ${report['communities']} comunidades y ${report['units']} unidades.',
            );
          }
          _loadCommunities();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: e.toString(),
        );
      }
    }
  }

  void _showCommunityDialog({Community? community}) {
    showDialog(
      context: context,
      builder: (context) => _CommunityDialog(
        community: community,
        onSuccess: () {
          _loadCommunities();
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            text: community == null 
              ? 'Comunidad creada exitosamente' 
              : 'Comunidad actualizada exitosamente',
          );
        },
      ),
    );
  }

  void _showUnitsDialog(Community community) {
    showDialog(
      context: context,
      builder: (context) => CommunityUnitsDialog(
        communityId: community.id,
        communityName: community.name,
      ),
    );
  }

  void _confirmDelete(Community community) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      text: '¿Estás seguro de desactivar la comunidad "${community.name}"?',
      confirmBtnText: 'Sí, desactivar',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Navigator.pop(context); // Cerrar alerta
        try {
          await _service.deleteCommunity(community.id);
          _loadCommunities();
          if (mounted) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              text: 'Comunidad desactivada',
            );
          }
        } catch (e) {
          if (mounted) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              text: 'Error: $e',
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Acciones
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: _handleBulkUpload,
              icon: const Icon(Icons.upload_file),
              label: const Text('Carga Masiva (Excel)'),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: () => _showCommunityDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Nueva Comunidad'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Tabla
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: FutureBuilder<List<Community>>(
              future: _communitiesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay comunidades registradas.'));
                }

                final communities = snapshot.data!;
                return SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                    columns: const [
                      DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Dirección', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Ubicación', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: communities.map((community) {
                      return DataRow(cells: [
                        DataCell(Text(community.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Text(community.address)),
                        DataCell(Text('${community.comuna}, ${community.region}')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: community.isActive ? Colors.green[50] : Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: community.isActive ? Colors.green[200]! : Colors.red[200]!),
                            ),
                            child: Text(
                              community.isActive ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                color: community.isActive ? Colors.green[800] : Colors.red[800],
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
                              IconButton(
                                icon: const Icon(Icons.apartment, color: Colors.blue),
                                onPressed: () => _showUnitsDialog(community),
                                tooltip: 'Ver Unidades',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                onPressed: () => _showCommunityDialog(community: community),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _confirmDelete(community),
                                tooltip: 'Desactivar',
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CommunityDialog extends StatefulWidget {
  final Community? community;
  final VoidCallback onSuccess;

  const _CommunityDialog({this.community, required this.onSuccess});

  @override
  State<_CommunityDialog> createState() => _CommunityDialogState();
}

class _CommunityDialogState extends State<_CommunityDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _constructoraController;
  late TextEditingController _inmobiliariaController;
  late TextEditingController _descriptionController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  DateTime? _fechaEntrega;

  // Dropdowns
  String? _selectedRegion;
  String? _selectedComuna;
  List<String> _comunas = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.community;
    _nameController = TextEditingController(text: c?.name ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _latController = TextEditingController(text: c?.latitude?.toString() ?? '');
    _lngController = TextEditingController(text: c?.longitude?.toString() ?? '');
    _constructoraController = TextEditingController(text: c?.constructora ?? '');
    _inmobiliariaController = TextEditingController(text: c?.inmobiliaria ?? '');
    _descriptionController = TextEditingController(text: c?.description ?? '');
    _emailController = TextEditingController(text: c?.contactEmail ?? '');
    _phoneController = TextEditingController(text: c?.contactPhone ?? '');
    
    if (c?.fechaEntregaInicial != null) {
      try {
        _fechaEntrega = DateTime.parse(c!.fechaEntregaInicial!);
      } catch (_) {}
    }

    // Inicializar Región y Comuna
    if (c != null) {
      // Intentar encontrar la región exacta
      final regionData = ChileData.regiones.firstWhere(
        (r) => r['region'] == c.region,
        orElse: () => {},
      );
      
      if (regionData.isNotEmpty) {
        _selectedRegion = c.region;
        _comunas = List<String>.from(regionData['comunas']);
        if (_comunas.contains(c.comuna)) {
          _selectedComuna = c.comuna;
        }
      }
    }
  }

  void _onRegionChanged(String? newRegion) {
    if (newRegion == null) return;
    setState(() {
      _selectedRegion = newRegion;
      final regionData = ChileData.regiones.firstWhere((r) => r['region'] == newRegion);
      _comunas = List<String>.from(regionData['comunas']);
      _selectedComuna = null; // Reset comuna
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaEntrega ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _fechaEntrega = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRegion == null || _selectedComuna == null) {
      QuickAlert.show(context: context, type: QuickAlertType.warning, text: 'Seleccione Región y Comuna');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final communityData = Community(
        id: widget.community?.id ?? '',
        name: _nameController.text,
        address: _addressController.text,
        comuna: _selectedComuna!,
        region: _selectedRegion!,
        isActive: widget.community?.isActive ?? true,
        latitude: double.tryParse(_latController.text),
        longitude: double.tryParse(_lngController.text),
        constructora: _constructoraController.text.isEmpty ? null : _constructoraController.text,
        inmobiliaria: _inmobiliariaController.text.isEmpty ? null : _inmobiliariaController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        contactEmail: _emailController.text.isEmpty ? null : _emailController.text,
        contactPhone: _phoneController.text.isEmpty ? null : _phoneController.text,
        fechaEntregaInicial: _fechaEntrega != null ? DateFormat('yyyy-MM-dd').format(_fechaEntrega!) : null,
      );

      if (widget.community == null) {
        await CommunityService().createCommunity(communityData);
      } else {
        await CommunityService().updateCommunity(communityData);
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'Error: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.community != null;
    
    // Mapa Preview
    Widget mapPreview = Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(child: Text('Ingrese Latitud y Longitud para ver el mapa')),
    );

    double? lat = double.tryParse(_latController.text);
    double? lng = double.tryParse(_lngController.text);

    if (lat != null && lng != null) {
      mapPreview = Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        clipBehavior: Clip.antiAlias,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(lat, lng),
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.vecinapp.admin',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(lat, lng),
                  width: 80,
                  height: 80,
                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AlertDialog(
      title: Text(isEditing ? 'Editar Comunidad' : 'Nueva Comunidad'),
      content: SizedBox(
        width: 800, // Diálogo más ancho
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sección 1: Datos Básicos
                Text('Información General', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nombre del Condominio *'),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Dirección *'),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRegion,
                        decoration: const InputDecoration(labelText: 'Región *'),
                        items: ChileData.regiones.map<DropdownMenuItem<String>>((r) {
                          return DropdownMenuItem(
                            value: r['region'],
                            child: Text(r['region'], overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: _onRegionChanged,
                        isExpanded: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedComuna,
                        decoration: const InputDecoration(labelText: 'Comuna *'),
                        items: _comunas.map<DropdownMenuItem<String>>((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedComuna = v),
                        isExpanded: true,
                        disabledHint: const Text('Seleccione Región primero'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                // Sección 2: Ubicación y Mapa
                Text('Ubicación Geográfica', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _latController,
                            decoration: const InputDecoration(labelText: 'Latitud'),
                            keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                            onChanged: (_) => setState(() {}), // Actualizar mapa
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _lngController,
                            decoration: const InputDecoration(labelText: 'Longitud'),
                            keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                            onChanged: (_) => setState(() {}), // Actualizar mapa
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: mapPreview,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                // Sección 3: Datos Inmobiliarios y Contacto
                Text('Detalles Adicionales', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _constructoraController,
                        decoration: const InputDecoration(labelText: 'Constructora'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _inmobiliariaController,
                        decoration: const InputDecoration(labelText: 'Inmobiliaria'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Fecha Entrega Inicial'),
                          child: Text(
                            _fechaEntrega != null 
                              ? DateFormat('dd/MM/yyyy').format(_fechaEntrega!) 
                              : 'Seleccionar fecha',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Container()), // Spacer
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email de Contacto'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Teléfono de Contacto'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(isEditing ? 'Guardar Cambios' : 'Crear'),
        ),
      ],
    );
  }
}
