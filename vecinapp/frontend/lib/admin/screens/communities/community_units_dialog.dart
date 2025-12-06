import 'package:flutter/material.dart';
import 'package:vecinapp/core/models/unit.dart';
import 'package:vecinapp/core/services/unit_service.dart';
import 'package:quickalert/quickalert.dart';
import 'package:vecinapp/core/theme/app_theme.dart';

class CommunityUnitsDialog extends StatefulWidget {
  final String communityId;
  final String communityName;

  const CommunityUnitsDialog({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<CommunityUnitsDialog> createState() => _CommunityUnitsDialogState();
}

class _CommunityUnitsDialogState extends State<CommunityUnitsDialog> {
  final UnitService _service = UnitService();
  late Future<List<Unit>> _unitsFuture;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  void _loadUnits() {
    setState(() {
      _unitsFuture = _service.getUnits(widget.communityId);
    });
  }

  void _showUnitForm({Unit? unit}) {
    showDialog(
      context: context,
      builder: (context) => _UnitFormDialog(
        communityId: widget.communityId,
        unit: unit,
        onSuccess: () {
          _loadUnits();
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            text: unit == null ? 'Unidad creada' : 'Unidad actualizada',
          );
        },
      ),
    );
  }

  void _confirmDelete(Unit unit) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      text: '¿Eliminar unidad "${unit.name}"?',
      confirmBtnText: 'Sí, eliminar',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Navigator.pop(context);
        try {
          await _service.deleteUnit(unit.id);
          _loadUnits();
          if (mounted) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              text: 'Unidad eliminada',
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
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unidades - ${widget.communityName}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gestiona los departamentos, casas y espacios comunes.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 32),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: () => _showUnitForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva Unidad'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table
            Expanded(
              child: FutureBuilder<List<Unit>>(
                future: _unitsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apartment_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No hay unidades registradas.'),
                        ],
                      ),
                    );
                  }

                  final units = snapshot.data!;
                  return SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                        columns: const [
                          DataColumn(label: Text('Nombre/N°')),
                          DataColumn(label: Text('Piso')),
                          DataColumn(label: Text('Tipo')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('M²')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: units.map((unit) {
                          return DataRow(cells: [
                            DataCell(Text(unit.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(unit.floor.toString())),
                            DataCell(Text(unit.type)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: unit.status == 'Disponible' ? Colors.green[50] : Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: unit.status == 'Disponible' ? Colors.green[200]! : Colors.blue[200]!,
                                  ),
                                ),
                                child: Text(
                                  unit.status,
                                  style: TextStyle(
                                    color: unit.status == 'Disponible' ? Colors.green[800] : Colors.blue[800],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text('${unit.m2}')),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                    onPressed: () => _showUnitForm(unit: unit),
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _confirmDelete(unit),
                                    tooltip: 'Eliminar',
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
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

class _UnitFormDialog extends StatefulWidget {
  final String communityId;
  final Unit? unit;
  final VoidCallback onSuccess;

  const _UnitFormDialog({
    required this.communityId,
    this.unit,
    required this.onSuccess,
  });

  @override
  State<_UnitFormDialog> createState() => _UnitFormDialogState();
}

class _UnitFormDialogState extends State<_UnitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _floorController;
  late TextEditingController _alicuotaController;
  late TextEditingController _m2Controller;
  late TextEditingController _descController;
  
  String _type = 'Departamento';
  String _status = 'Disponible';
  bool _isLoading = false;

  final List<String> _types = ['Departamento', 'Casa', 'Bodega', 'Estacionamiento', 'Espacio Común'];
  final List<String> _statuses = ['Disponible', 'Asignado'];

  @override
  void initState() {
    super.initState();
    final u = widget.unit;
    _nameController = TextEditingController(text: u?.name ?? '');
    _floorController = TextEditingController(text: u?.floor.toString() ?? '1');
    _alicuotaController = TextEditingController(text: u?.alicuota.toString() ?? '0.0');
    _m2Controller = TextEditingController(text: u?.m2.toString() ?? '0.0');
    _descController = TextEditingController(text: u?.description ?? '');
    _type = u?.type ?? 'Departamento';
    _status = u?.status ?? 'Disponible';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final unitData = Unit(
        id: widget.unit?.id ?? '',
        name: _nameController.text,
        floor: int.tryParse(_floorController.text) ?? 1,
        type: _type,
        status: _status,
        alicuota: double.tryParse(_alicuotaController.text) ?? 0.0,
        m2: double.tryParse(_m2Controller.text) ?? 0.0,
        description: _descController.text.isEmpty ? null : _descController.text,
        communityId: widget.communityId,
      );

      if (widget.unit == null) {
        await UnitService().createUnit(unitData);
      } else {
        await UnitService().updateUnit(unitData);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        QuickAlert.show(context: context, type: QuickAlertType.error, text: 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.unit == null ? 'Nueva Unidad' : 'Editar Unidad'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nombre/Número *'),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _floorController,
                        decoration: const InputDecoration(labelText: 'Piso'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Tipo de Unidad'),
                  items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _m2Controller,
                        decoration: const InputDecoration(labelText: 'Metros Cuadrados (m²)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _alicuotaController,
                        decoration: const InputDecoration(labelText: 'Alicuota (%)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Guardar'),
        ),
      ],
    );
  }
}
