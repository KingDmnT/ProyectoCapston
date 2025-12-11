// Modelo de notificación para VecinApp

enum NotificationType {
  incidentCreated,
  incidentUpdated,
  reservationCreated,
  reservationUpdated,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.incidentCreated:
        return 'incident_created';
      case NotificationType.incidentUpdated:
        return 'incident_updated';
      case NotificationType.reservationCreated:
        return 'reservation_created';
      case NotificationType.reservationUpdated:
        return 'reservation_updated';
    }
  }

  static NotificationType fromString(String typeStr) {
    switch (typeStr) {
      case 'incident_created':
        return NotificationType.incidentCreated;
      case 'incident_updated':
        return NotificationType.incidentUpdated;
      case 'reservation_created':
        return NotificationType.reservationCreated;
      case 'reservation_updated':
        return NotificationType.reservationUpdated;
      default:
        return NotificationType.incidentCreated;
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.incidentCreated:
      case NotificationType.incidentUpdated:
        return '⚠️';
      case NotificationType.reservationCreated:
      case NotificationType.reservationUpdated:
        return '📅';
    }
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String communityId;
  final String userId;
  final String relatedEntityId;
  final String relatedEntityType; // 'incident' or 'reservation'
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.communityId,
    required this.userId,
    required this.relatedEntityId,
    required this.relatedEntityType,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
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
        return DateTime.now();
      }
    }

    return AppNotification(
      id: json['id'] ?? '',
      type: NotificationTypeExtension.fromString(json['type'] ?? 'incident_created'),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      communityId: json['community_id'] ?? '',
      userId: json['user_id'] ?? '',
      relatedEntityId: json['related_entity_id'] ?? '',
      relatedEntityType: json['related_entity_type'] ?? 'incident',
      isRead: json['is_read'] ?? false,
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'message': message,
      'community_id': communityId,
      'user_id': userId,
      'related_entity_id': relatedEntityId,
      'related_entity_type': relatedEntityType,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    String? communityId,
    String? userId,
    String? relatedEntityId,
    String? relatedEntityType,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      communityId: communityId ?? this.communityId,
      userId: userId ?? this.userId,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
