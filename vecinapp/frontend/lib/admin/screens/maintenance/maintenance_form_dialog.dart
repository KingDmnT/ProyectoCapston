import 'package:flutter/material.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/models/maintenance.dart';
import 'package:vecinapp/core/services/maintenance_service.dart';
import 'package:intl/intl.dart';

class MaintenanceFormDialog extends StatefulWidget {
  final String communityId;
  final Maintenance? maintenance;

  const MaintenanceFormDialog({
    super.key,
    required this.communityId,
    this.maintenance,
  });

  @override
  State<MaintenanceFormDialog> createState() => _MaintenanceFormDialogState();
}

class _MaintenanceFormDialogState extends State<MaintenanceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final MaintenanceService _maintenanceService = MaintenanceService();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _providerNameController;
  late TextEditingController _providerContactController;
  late TextEditingController _costController;
  late TextEditingController _notesController;
  
  MaintenanceType _selectedType = MaintenanceType.preventivo;
  MaintenanceFrequency _selectedFrequency = MaintenanceFrequency.unicaVez;
  MaintenanceStatus _selectedStatus = MaintenanceStatus.pendiente;
  DateTime _scheduledDate = DateTime.now();
  List<ChecklistItem> _checklistItems = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.maintenance != null) {
      _titleController = TextEditingController(text: widget.maintenance!.title);
      _descriptionController = TextEditingController(text: widget.maintenance!.description);
      _providerNameController = TextEditingController(text: widget.maintenance!.providerName);
      _providerContactController = TextEditingController(text: widget.maintenance!.providerContact ?? '');
      _costController = TextEditingController(text: widget.maintenance!.cost.toString());
      _notesController = TextEditingController(text: widget.maintenance!.notes ?? '');
      _selectedType = widget.maintenance!.type;
      _selectedFrequency = widget.maintenance!.frequency;
      _selectedStatus = widget.maintenance!.status;
      _scheduledDate = widget.maintenance!.scheduledDate;
      _checklistItems = List.from(widget.maintenance!.checklistItems);
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _providerNameController = TextEditingController();
      _providerContactController = TextEditingController();
      _costController = TextEditingController(text: '0');
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _providerNameController.dispose();
    _providerContactController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _scheduledDate) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  void _addChecklistItem() {
    showDialog(
      context: context,
      builder: (context) {
        String itemTitle = '';
        return AlertDialog(
          title: const Text('Agregar Item'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Descripción del item',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => itemTitle = value,
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _checklistItems.add(ChecklistItem(title: value));
                });
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (itemTitle.isNotEmpty) {
                  setState(() {
                    _checklistItems.add(ChecklistItem(title: itemTitle));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _removeChecklistItem(int index) {
    setState(() {
      _checklistItems.removeAt(index);
    });
  }

  void _toggleChecklistItem(int index) {
    setState(() {
      _checklistItems[index] = _checklistItems[index].copyWith(
        isCompleted: !_checklistItems[index].isCompleted,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final maintenanceData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'type': _selectedType.value,
        'frequency': _selectedFrequency.value,
        'provider_name': _providerNameController.text,
        'provider_contact': _providerContactController.text.isEmpty 
            ? null 
            : _providerContactController.text,
        'cost': double.tryParse(_costController.text) ?? 0.0,
        'scheduled_date': _scheduledDate.toIso8601String(),
        'community_id': widget.communityId,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'checklist_items': _checklistItems.map((item) => item.toJson()).toList(),
      };

      if (widget.maintenance != null) {
        // Actualizar existente
        maintenanceData['status'] = _selectedStatus.value;
        await _maintenanceService.updateMaintenance(
          communityId: widget.communityId,
          maintenanceId: widget.maintenance!.id,
          updates: maintenanceData,
        );
      } else {
        // Crear nuevo
        final maintenance = Maintenance(
          id: '',
          title: _titleController.text,
          description: _descriptionController.text,
          type: _selectedType,
          frequency: _selectedFrequency,
          providerName: _providerNameController.text,
          providerContact: _providerContactController.text.isEmpty 
              ? null 
              : _providerContactController.text,
          cost: double.tryParse(_costController.text) ?? 0.0,
          scheduledDate: _scheduledDate,
          status: MaintenanceStatus.pendiente,
          communityId: widget.communityId,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          checklistItems: _checklistItems,
        );
        
        await _maintenanceService.createMaintenance(maintenance);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.maintenance != null
                  ? 'Mantenimiento actualizado'
                  : 'Mantenimiento creado',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.build, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    widget.maintenance != null
                        ? 'Editar Mantenimiento'
                        : 'Nuevo Mantenimiento',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Título *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El título es obligatorio';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Descripción
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción *',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La descripción es obligatoria';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Tipo y Frecuencia
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<MaintenanceType>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Tipo *',
                                border: OutlineInputBorder(),
                              ),
                              items: MaintenanceType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type.displayName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedType = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<MaintenanceFrequency>(
                              value: _selectedFrequency,
                              decoration: const InputDecoration(
                                labelText: 'Frecuencia *',
                                border: OutlineInputBorder(),
                              ),
                              items: MaintenanceFrequency.values.map((freq) {
                                return DropdownMenuItem(
                                  value: freq,
                                  child: Text(freq.displayName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedFrequency = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Proveedor
                      TextFormField(
                        controller: _providerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Proveedor *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El proveedor es obligatorio';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Contacto del Proveedor
                      TextFormField(
                        controller: _providerContactController,
                        decoration: const InputDecoration(
                          labelText: 'Contacto del Proveedor',
                          hintText: 'Teléfono o email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Costo y Fecha
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _costController,
                              decoration: const InputDecoration(
                                labelText: 'Costo',
                                prefixText: '\$ ',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Fecha Programada *',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(_scheduledDate),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      if (widget.maintenance != null) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<MaintenanceStatus>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            border: OutlineInputBorder(),
                          ),
                          items: MaintenanceStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status.displayName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedStatus = value);
                            }
                          },
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Notas
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notas Adicionales',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Checklist
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Checklist de Tareas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addChecklistItem,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Agregar Item'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      if (_checklistItems.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'No hay items en el checklist',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _checklistItems.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _checklistItems[index];
                              return ListTile(
                                leading: Checkbox(
                                  value: item.isCompleted,
                                  onChanged: (_) => _toggleChecklistItem(index),
                                ),
                                title: Text(
                                  item.title,
                                  style: TextStyle(
                                    decoration: item.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeChecklistItem(index),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer con botones
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.maintenance != null ? 'Actualizar' : 'Crear'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
