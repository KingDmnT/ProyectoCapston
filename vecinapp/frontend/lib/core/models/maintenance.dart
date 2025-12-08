// Modelo de mantenimiento para VecinApp

enum MaintenanceType {
  preventivo,
  correctivo,
  extraordinario,
}

extension MaintenanceTypeExtension on MaintenanceType {
  String get value {
    switch (this) {
      case MaintenanceType.preventivo:
        return 'preventivo';
      case MaintenanceType.correctivo:
        return 'correctivo';
      case MaintenanceType.extraordinario:
        return 'extraordinario';
    }
  }

  String get displayName {
    switch (this) {
      case MaintenanceType.preventivo:
        return 'Preventivo';
      case MaintenanceType.correctivo:
        return 'Correctivo';
      case MaintenanceType.extraordinario:
        return 'Extraordinario';
    }
  }

  static MaintenanceType fromString(String typeStr) {
    switch (typeStr) {
      case 'preventivo':
        return MaintenanceType.preventivo;
      case 'correctivo':
        return MaintenanceType.correctivo;
      case 'extraordinario':
        return MaintenanceType.extraordinario;
      default:
        return MaintenanceType.preventivo;
    }
  }
}

enum MaintenanceStatus {
  pendiente,
  enProgreso,
  completado,
  aprobado,
  rechazado,
}

extension MaintenanceStatusExtension on MaintenanceStatus {
  String get value {
    switch (this) {
      case MaintenanceStatus.pendiente:
        return 'pendiente';
      case MaintenanceStatus.enProgreso:
        return 'en_progreso';
      case MaintenanceStatus.completado:
        return 'completado';
      case MaintenanceStatus.aprobado:
        return 'aprobado';
      case MaintenanceStatus.rechazado:
        return 'rechazado';
    }
  }

  String get displayName {
    switch (this) {
      case MaintenanceStatus.pendiente:
        return 'Pendiente';
      case MaintenanceStatus.enProgreso:
        return 'En Progreso';
      case MaintenanceStatus.completado:
        return 'Completado';
      case MaintenanceStatus.aprobado:
        return 'Aprobado';
      case MaintenanceStatus.rechazado:
        return 'Rechazado';
    }
  }

  static MaintenanceStatus fromString(String statusStr) {
    switch (statusStr) {
      case 'pendiente':
        return MaintenanceStatus.pendiente;
      case 'en_progreso':
        return MaintenanceStatus.enProgreso;
      case 'completado':
        return MaintenanceStatus.completado;
      case 'aprobado':
        return MaintenanceStatus.aprobado;
      case 'rechazado':
        return MaintenanceStatus.rechazado;
      default:
        return MaintenanceStatus.pendiente;
    }
  }
}

enum MaintenanceFrequency {
  unicaVez,
  diaria,
  semanal,
  mensual,
  trimestral,
  semestral,
  anual,
}

extension MaintenanceFrequencyExtension on MaintenanceFrequency {
  String get value {
    switch (this) {
      case MaintenanceFrequency.unicaVez:
        return 'unica_vez';
      case MaintenanceFrequency.diaria:
        return 'diaria';
      case MaintenanceFrequency.semanal:
        return 'semanal';
      case MaintenanceFrequency.mensual:
        return 'mensual';
      case MaintenanceFrequency.trimestral:
        return 'trimestral';
      case MaintenanceFrequency.semestral:
        return 'semestral';
      case MaintenanceFrequency.anual:
        return 'anual';
    }
  }

  String get displayName {
    switch (this) {
      case MaintenanceFrequency.unicaVez:
        return 'Única Vez';
      case MaintenanceFrequency.diaria:
        return 'Diaria';
      case MaintenanceFrequency.semanal:
        return 'Semanal';
      case MaintenanceFrequency.mensual:
        return 'Mensual';
      case MaintenanceFrequency.trimestral:
        return 'Trimestral';
      case MaintenanceFrequency.semestral:
        return 'Semestral';
      case MaintenanceFrequency.anual:
        return 'Anual';
    }
  }

  static MaintenanceFrequency fromString(String freqStr) {
    switch (freqStr) {
      case 'unica_vez':
        return MaintenanceFrequency.unicaVez;
      case 'diaria':
        return MaintenanceFrequency.diaria;
      case 'semanal':
        return MaintenanceFrequency.semanal;
      case 'mensual':
        return MaintenanceFrequency.mensual;
      case 'trimestral':
        return MaintenanceFrequency.trimestral;
      case 'semestral':
        return MaintenanceFrequency.semestral;
      case 'anual':
        return MaintenanceFrequency.anual;
      default:
        return MaintenanceFrequency.unicaVez;
    }
  }
}

class ChecklistItem {
  final String title;
  final bool isCompleted;

  ChecklistItem({
    required this.title,
    this.isCompleted = false,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      title: json['title'] ?? '',
      isCompleted: json['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'is_completed': isCompleted,
    };
  }

  ChecklistItem copyWith({
    String? title,
    bool? isCompleted,
  }) {
    return ChecklistItem(
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class Maintenance {
  final String id;
  final String title;
  final String description;
  final MaintenanceType type;
  final MaintenanceFrequency frequency;
  final String providerName;
  final String? providerContact;
  final double cost;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final MaintenanceStatus status;
  final String communityId;
  final String? assignedTo;
  final String? approvedBy;
  final DateTime? approvalDate;
  final String? notes;
  final List<ChecklistItem> checklistItems;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Maintenance({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.frequency,
    required this.providerName,
    this.providerContact,
    required this.cost,
    required this.scheduledDate,
    this.completedDate,
    required this.status,
    required this.communityId,
    this.assignedTo,
    this.approvedBy,
    this.approvalDate,
    this.notes,
    this.checklistItems = const [],
    this.createdAt,
    this.updatedAt,
  });

  // Helpers
  bool get isPending => status == MaintenanceStatus.pendiente;
  bool get isCompleted => status == MaintenanceStatus.completado;
  bool get isApproved => status == MaintenanceStatus.aprobado;
  bool get isRejected => status == MaintenanceStatus.rechazado;
  bool get isInProgress => status == MaintenanceStatus.enProgreso;

  bool get isOverdue {
    if (isCompleted || isApproved) return false;
    return DateTime.now().isAfter(scheduledDate);
  }

  int get checklistProgress {
    if (checklistItems.isEmpty) return 0;
    final completed = checklistItems.where((item) => item.isCompleted).length;
    return ((completed / checklistItems.length) * 100).round();
  }

  // Convertir desde JSON (API)
  factory Maintenance.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parseando fecha: $e');
          return null;
        }
      }
      // Firestore Timestamp
      try {
        return value.toDate();
      } catch (e) {
        // Ignorar
      }
      // Map con seconds
      if (value is Map && value.containsKey('seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(
          (value['seconds'] as int) * 1000,
        );
      }
      return null;
    }

    return Maintenance(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: MaintenanceTypeExtension.fromString(json['type'] ?? 'preventivo'),
      frequency: MaintenanceFrequencyExtension.fromString(
        json['frequency'] ?? 'unica_vez',
      ),
      providerName: json['provider_name'] ?? '',
      providerContact: json['provider_contact'],
      cost: (json['cost'] ?? 0).toDouble(),
      scheduledDate: parseDate(json['scheduled_date']) ?? DateTime.now(),
      completedDate: parseDate(json['completed_date']),
      status: MaintenanceStatusExtension.fromString(
        json['status'] ?? 'pendiente',
      ),
      communityId: json['community_id'] ?? '',
      assignedTo: json['assigned_to'],
      approvedBy: json['approved_by'],
      approvalDate: parseDate(json['approval_date']),
      notes: json['notes'],
      checklistItems: (json['checklist_items'] as List<dynamic>?)
              ?.map((item) => ChecklistItem.fromJson(item))
              .toList() ??
          [],
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.value,
      'frequency': frequency.value,
      'provider_name': providerName,
      'provider_contact': providerContact,
      'cost': cost,
      'scheduled_date': scheduledDate.toIso8601String(),
      'completed_date': completedDate?.toIso8601String(),
      'status': status.value,
      'community_id': communityId,
      'assigned_to': assignedTo,
      'approved_by': approvedBy,
      'approval_date': approvalDate?.toIso8601String(),
      'notes': notes,
      'checklist_items': checklistItems.map((item) => item.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Maintenance copyWith({
    String? id,
    String? title,
    String? description,
    MaintenanceType? type,
    MaintenanceFrequency? frequency,
    String? providerName,
    String? providerContact,
    double? cost,
    DateTime? scheduledDate,
    DateTime? completedDate,
    MaintenanceStatus? status,
    String? communityId,
    String? assignedTo,
    String? approvedBy,
    DateTime? approvalDate,
    String? notes,
    List<ChecklistItem>? checklistItems,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Maintenance(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      providerName: providerName ?? this.providerName,
      providerContact: providerContact ?? this.providerContact,
      cost: cost ?? this.cost,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      status: status ?? this.status,
      communityId: communityId ?? this.communityId,
      assignedTo: assignedTo ?? this.assignedTo,
      approvedBy: approvedBy ?? this.approvedBy,
      approvalDate: approvalDate ?? this.approvalDate,
      notes: notes ?? this.notes,
      checklistItems: checklistItems ?? this.checklistItems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
