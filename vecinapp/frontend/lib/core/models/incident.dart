// Modelo de incidente para VecinApp

import 'incident_comment.dart';

enum IncidentCategory {
  instalaciones,
  seguridad,
  limpieza,
  ruido,
  otro,
}

extension IncidentCategoryExtension on IncidentCategory {
  String get value {
    switch (this) {
      case IncidentCategory.instalaciones:
        return 'instalaciones';
      case IncidentCategory.seguridad:
        return 'seguridad';
      case IncidentCategory.limpieza:
        return 'limpieza';
      case IncidentCategory.ruido:
        return 'ruido';
      case IncidentCategory.otro:
        return 'otro';
    }
  }

  String get displayName {
    switch (this) {
      case IncidentCategory.instalaciones:
        return '🏗️ Instalaciones';
      case IncidentCategory.seguridad:
        return '🔐 Seguridad';
      case IncidentCategory.limpieza:
        return '🧹 Limpieza';
      case IncidentCategory.ruido:
        return '🔊 Ruido';
      case IncidentCategory.otro:
        return '📋 Otro';
    }
  }

  static IncidentCategory fromString(String categoryStr) {
    switch (categoryStr) {
      case 'instalaciones':
        return IncidentCategory.instalaciones;
      case 'seguridad':
        return IncidentCategory.seguridad;
      case 'limpieza':
        return IncidentCategory.limpieza;
      case 'ruido':
        return IncidentCategory.ruido;
      case 'otro':
        return IncidentCategory.otro;
      default:
        return IncidentCategory.otro;
    }
  }
}

enum IncidentPriority {
  baja,
  media,
  alta,
  critica,
}

extension IncidentPriorityExtension on IncidentPriority {
  String get value {
    switch (this) {
      case IncidentPriority.baja:
        return 'baja';
      case IncidentPriority.media:
        return 'media';
      case IncidentPriority.alta:
        return 'alta';
      case IncidentPriority.critica:
        return 'critica';
    }
  }

  String get displayName {
    switch (this) {
      case IncidentPriority.baja:
        return 'Baja';
      case IncidentPriority.media:
        return 'Media';
      case IncidentPriority.alta:
        return 'Alta';
      case IncidentPriority.critica:
        return 'Crítica';
    }
  }

  static IncidentPriority fromString(String priorityStr) {
    switch (priorityStr.toLowerCase()) {
      case 'baja':
        return IncidentPriority.baja;
      case 'media':
        return IncidentPriority.media;
      case 'alta':
        return IncidentPriority.alta;
      case 'critica':
        return IncidentPriority.critica;
      default:
        return IncidentPriority.media;
    }
  }
}

enum IncidentStatus {
  pendiente,
  enProceso,
  resuelto,
}

extension IncidentStatusExtension on IncidentStatus {
  String get value {
    switch (this) {
      case IncidentStatus.pendiente:
        return 'pendiente';
      case IncidentStatus.enProceso:
        return 'en_proceso';
      case IncidentStatus.resuelto:
        return 'resuelto';
    }
  }

  String get displayName {
    switch (this) {
      case IncidentStatus.pendiente:
        return 'Pendiente';
      case IncidentStatus.enProceso:
        return 'En Proceso';
      case IncidentStatus.resuelto:
        return 'Resuelto';
    }
  }

  static IncidentStatus fromString(String statusStr) {
    switch (statusStr) {
      case 'pendiente':
        return IncidentStatus.pendiente;
      case 'en_proceso':
        return IncidentStatus.enProceso;
      case 'resuelto':
        return IncidentStatus.resuelto;
      default:
        return IncidentStatus.pendiente;
    }
  }
}

class Incident {
  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final IncidentPriority priority;
  final String? location;
  final IncidentStatus status;
  final String communityId;
  final String createdBy;
  final String? adminNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Traceability Fields
  final String? reportedById;
  final String? reportedByName;
  final String? reportedByUnit;
  final DateTime? resolvedAt;
  final String? resolvedById;
  final String? resolvedByName;
  final bool isSecurity;
  final List<IncidentComment> comments;

  Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    this.location,
    required this.status,
    required this.communityId,
    required this.createdBy,
    this.adminNotes,
    this.createdAt,
    this.updatedAt,
    this.reportedById,
    this.reportedByName,
    this.reportedByUnit,
    this.resolvedAt,
    this.resolvedById,
    this.resolvedByName,
    this.isSecurity = false,
    this.comments = const [],
  });

  bool get isPending => status == IncidentStatus.pendiente;
  bool get isInProgress => status == IncidentStatus.enProceso;
  bool get isResolved => status == IncidentStatus.resuelto;

  factory Incident.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      if (value is Map && value.containsKey('seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(
          (value['seconds'] as int) * 1000,
        );
      }
      try {
        return value.toDate();
      } catch (e) {
        return null;
      }
    }

    return Incident(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: IncidentCategoryExtension.fromString(json['category'] ?? 'otro'),
      priority: IncidentPriorityExtension.fromString(json['priority'] ?? 'media'),
      location: json['location'],
      status: IncidentStatusExtension.fromString(json['status'] ?? 'pendiente'),
      communityId: json['community_id'] ?? '',
      createdBy: json['created_by'] ?? '',
      adminNotes: json['admin_notes'],
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      reportedById: json['reported_by_id'],
      reportedByName: json['reported_by_name'],
      reportedByUnit: json['reported_by_unit'],
      resolvedAt: parseDate(json['resolved_at']),
      resolvedById: json['resolved_by_id'],
      resolvedByName: json['resolved_by_name'],
      isSecurity: json['is_security'] ?? false,
      comments: (json['comments'] as List<dynamic>?)
              ?.map((c) => IncidentComment.fromJson(c))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.value,
      'priority': priority.value,
      'location': location,
      'status': status.value,
      'community_id': communityId,
      'created_by': createdBy,
      'admin_notes': adminNotes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'reported_by_id': reportedById,
      'reported_by_name': reportedByName,
      'reported_by_unit': reportedByUnit,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by_id': resolvedById,
      'resolved_by_name': resolvedByName,
      'is_security': isSecurity,
      'comments': comments.map((c) => c.toJson()).toList(),
    };
  }

  Incident copyWith({
    String? id,
    String? title,
    String? description,
    IncidentCategory? category,
    IncidentPriority? priority,
    String? location,
    IncidentStatus? status,
    String? communityId,
    String? createdBy,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reportedById,
    String? reportedByName,
    String? reportedByUnit,
    DateTime? resolvedAt,
    String? resolvedById,
    String? resolvedByName,
    bool? isSecurity,
    List<IncidentComment>? comments,
  }) {
    return Incident(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      location: location ?? this.location,
      status: status ?? this.status,
      communityId: communityId ?? this.communityId,
      createdBy: createdBy ?? this.createdBy,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reportedById: reportedById ?? this.reportedById,
      reportedByName: reportedByName ?? this.reportedByName,
      reportedByUnit: reportedByUnit ?? this.reportedByUnit,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedById: resolvedById ?? this.resolvedById,
      resolvedByName: resolvedByName ?? this.resolvedByName,
      isSecurity: isSecurity ?? this.isSecurity,
      comments: comments ?? this.comments,
    );
  }
}
