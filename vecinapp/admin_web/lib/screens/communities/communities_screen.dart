import 'package:flutter/material.dart';

import 'package:admin_web/models/community.dart';
import 'package:admin_web/services/community_service.dart';
import 'package:admin_web/theme/app_theme.dart';

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

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateCommunityDialog(
        onSuccess: () {
          _loadCommunities(); // Recargar lista
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comunidad creada exitosamente')),
          );
        },
      ),
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
            FilledButton.icon(
              onPressed: _showCreateDialog,
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
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                            onPressed: () {
                              // TODO: Editar
                            },
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

class _CreateCommunityDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const _CreateCommunityDialog({required this.onSuccess});

  @override
  State<_CreateCommunityDialog> createState() => _CreateCommunityDialogState();
}

class _CreateCommunityDialogState extends State<_CreateCommunityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _comunaController = TextEditingController();
  final _regionController = TextEditingController(); // Podría ser un Dropdown
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newCommunity = Community(
        id: '', // Se genera en backend
        name: _nameController.text,
        address: _addressController.text,
        comuna: _comunaController.text,
        region: _regionController.text,
        isActive: true,
      );

      await CommunityService().createCommunity(newCommunity);
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Comunidad'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre del Condominio'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Dirección'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _comunaController,
                      decoration: const InputDecoration(labelText: 'Comuna'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _regionController,
                      decoration: const InputDecoration(labelText: 'Región'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
            ],
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
            : const Text('Crear'),
        ),
      ],
    );
  }
}
