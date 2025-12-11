import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/models/announcement.dart';
import 'package:vecinapp/core/services/announcement_service.dart';
import 'package:vecinapp/core/services/auth_service.dart';
import 'package:intl/intl.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _announcementService = AnnouncementService();
  List<Announcement> _allAnnouncements = [];
  bool _isLoading = true;
  String? _error;
  String? _communityId;
  bool? _filterActive;
  
  String _searchQuery = '';
  int _rowsPerPage = 10;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getCurrentUserData();
      
      _communityId = userData?.communityId ?? 
                     (userData?.memberships.isNotEmpty == true 
                       ? userData!.memberships[0].communityId 
                       : '');

      // Obtener token de autenticación
      final token = await authService.currentUser?.getIdToken();

      final announcements = await _announcementService.getAll(
        communityId: _communityId!,
        isActive: _filterActive,
        token: token,
      );

      setState(() {
        _allAnnouncements = announcements;
        _isLoading = false;
        _currentPage = 0;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  List<Announcement> get _filteredAnnouncements {
    var filtered = _allAnnouncements.where((announcement) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return announcement.title.toLowerCase().contains(query) ||
             announcement.message.toLowerCase().contains(query);
    }).toList();
    
    return filtered;
  }
  
  List<Announcement> get _paginatedAnnouncements {
    final filtered = _filteredAnnouncements;
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end);
  }
  
  int get _totalPages => (_filteredAnnouncements.length / _rowsPerPage).ceil();

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => _AnnouncementFormDialog(
        communityId: _communityId!,
        onSave: _loadAnnouncements,
      ),
    );
  }

  void _showEditDialog(Announcement announcement) {
    showDialog(
      context: context,
      builder: (context) => _AnnouncementFormDialog(
        communityId: _communityId!,
        announcement: announcement,
        onSave: _loadAnnouncements,
      ),
    );
  }

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de eliminar "${announcement.title}"?'),
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

    if (confirm == true) {
      try {
        // Obtener token
        final authService = Provider.of<AuthService>(context, listen: false);
        final token = await authService.currentUser?.getIdToken();
        
        await _announcementService.delete(
          communityId: _communityId!,
          announcementId: announcement.id,
          token: token,
        );
        _loadAnnouncements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anuncio eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Color _getPriorityColor(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.info:
        return Colors.blue;
      case AnnouncementPriority.warning:
        return Colors.orange;
      case AnnouncementPriority.urgent:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header section
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.campaign, size: 32, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Anuncios',
                        style: GoogleFonts.lato(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showCreateDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Crear Anuncio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Search bar
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar por título o mensaje...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _currentPage = 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filter por estado
                    DropdownButton<bool?>(
                      value: _filterActive,
                      hint: const Text('Estado'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todos')),
                        DropdownMenuItem(value: true, child: Text('Activos')),
                        DropdownMenuItem(value: false, child: Text('Inactivos')),
                      ],
                      onChanged: (value) {
                        setState(() => _filterActive = value);
                        _loadAnnouncements();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error: $_error'),
                            ElevatedButton(
                              onPressed: _loadAnnouncements,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _buildDataTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                  dataRowHeight: 70,
                  columns: const [
                    DataColumn(label: Text('Título')),
                    DataColumn(label: Text('Prioridad')),
                    DataColumn(label: Text('En Banner')),
                    DataColumn(label: Text('Creado Por')),
                    DataColumn(label: Text('Fecha Creación')),
                    DataColumn(label: Text('Expira')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: _paginatedAnnouncements.map((announcement) {
                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 200,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  announcement.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  announcement.message,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Chip(
                            label: Text(
                              '${announcement.priority.emoji} ${announcement.priority.displayName}',
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                            backgroundColor: _getPriorityColor(announcement.priority),
                          ),
                        ),
                        DataCell(
                          Icon(
                            announcement.showInBanner ? Icons.check_circle : Icons.cancel,
                            color: announcement.showInBanner ? Colors.green : Colors.grey,
                          ),
                        ),
                        DataCell(Text(announcement.createdByName)),
                        DataCell(Text(announcement.formattedCreatedAt)),
                        DataCell(
                          Text(
                            announcement.formattedExpiresAt,
                            style: TextStyle(
                              color: announcement.isExpired ? Colors.red : Colors.black87,
                            ),
                          ),
                        ),
                        DataCell(
                          Chip(
                            label: Text(
                              announcement.isActive ? 'Activo' : 'Inactivo',
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                            backgroundColor: announcement.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showEditDialog(announcement),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () => _deleteAnnouncement(announcement),
                                tooltip: 'Eliminar',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          // Pagination
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  Text('Página ${_currentPage + 1} de $_totalPages'),
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
    );
  }
}

// Dialog para crear/editar anuncio
class _AnnouncementFormDialog extends StatefulWidget {
  final String communityId;
  final Announcement? announcement;
  final VoidCallback onSave;

  const _AnnouncementFormDialog({
    required this.communityId,
    this.announcement,
    required this.onSave,
  });

  @override
  State<_AnnouncementFormDialog> createState() => _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<_AnnouncementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _announcementService = AnnouncementService();
  
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  late AnnouncementPriority _selectedPriority;
  late bool _showInBanner;
  DateTime? _expiresAt;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement?.title ?? '');
    _messageController = TextEditingController(text: widget.announcement?.message ?? '');
    _selectedPriority = widget.announcement?.priority ?? AnnouncementPriority.info;
    _showInBanner = widget.announcement?.showInBanner ?? false;
    _expiresAt = widget.announcement?.expiresAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Obtener token de autenticación
      final authService = AuthService();
      final token = await authService.currentUser?.getIdToken();
      
      if (widget.announcement == null) {
        // Crear
        await _announcementService.create(
          communityId: widget.communityId,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          priority: _selectedPriority,
          showInBanner: _showInBanner,
          expiresAt: _expiresAt,
          token: token,
        );
      } else {
        // Actualizar
        await _announcementService.update(
          communityId: widget.communityId,
          announcementId: widget.announcement!.id,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          priority: _selectedPriority,
          showInBanner: _showInBanner,
          expiresAt: _expiresAt,
          token: token,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.announcement == null
                ? 'Anuncio creado exitosamente'
                : 'Anuncio actualizado exitosamente'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.announcement == null ? 'Crear Anuncio' : 'Editar Anuncio',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El título es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El mensaje es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<AnnouncementPriority>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Prioridad',
                    border: OutlineInputBorder(),
                  ),
                  items: AnnouncementPriority.values.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text('${priority.emoji} ${priority.displayName}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedPriority = value);
                  },
                ),
                const SizedBox(height: 16),
                
                SwitchListTile(
                  title: const Text('Mostrar en Banner/Carousel'),
                  value: _showInBanner,
                  onChanged: (value) => setState(() => _showInBanner = value),
                ),
                const SizedBox(height: 16),
                
                ListTile(
                  title: const Text('Fecha de Expiración (Opcional)'),
                  subtitle: Text(_expiresAt == null
                      ? 'Sin expiración'
                      : DateFormat('dd/MM/yyyy HH:mm').format(_expiresAt!)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_expiresAt != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _expiresAt = null),
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(_expiresAt ?? DateTime.now()),
                            );
                            if (time != null) {
                              setState(() {
                                _expiresAt = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.announcement == null ? 'Crear' : 'Actualizar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
