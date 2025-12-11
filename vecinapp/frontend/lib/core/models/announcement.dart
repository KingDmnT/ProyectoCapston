import 'package:intl/intl.dart';

enum AnnouncementPriority {
  info,
  warning,
  urgent;

  String get value {
    switch (this) {
      case AnnouncementPriority.info:
        return 'info';
      case AnnouncementPriority.warning:
        return 'warning';
      case AnnouncementPriority.urgent:
        return 'urgent';
    }
  }

  String get displayName {
    switch (this) {
      case AnnouncementPriority.info:
        return 'Información';
      case AnnouncementPriority.warning:
        return 'Advertencia';
      case AnnouncementPriority.urgent:
        return 'Urgente';
    }
  }

  String get emoji {
    switch (this) {
      case AnnouncementPriority.info:
        return '📢';
      case AnnouncementPriority.warning:
        return '⚠️';
      case AnnouncementPriority.urgent:
        return '🚨';
    }
  }

  static AnnouncementPriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'info':
        return AnnouncementPriority.info;
      case 'warning':
        return AnnouncementPriority.warning;
      case 'urgent':
        return AnnouncementPriority.urgent;
      default:
        return AnnouncementPriority.info;
    }
  }
}

class Announcement {
  final String id;
  final String title;
  final String message;
  final AnnouncementPriority priority;
  final bool showInBanner;
  final String communityId;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final bool isActive;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.showInBanner,
    required this.communityId,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.isActive = true,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      priority: AnnouncementPriority.fromString(json['priority'] ?? 'info'),
      showInBanner: json['show_in_banner'] ?? false,
      communityId: json['community_id'] ?? '',
      createdBy: json['created_by'] ?? '',
      createdByName: json['created_by_name'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'priority': priority.value,
      'show_in_banner': showInBanner,
      'community_id': communityId,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  String get formattedCreatedAt {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }

  String get formattedExpiresAt {
    if (expiresAt == null) return 'Sin expiración';
    return DateFormat('dd/MM/yyyy HH:mm').format(expiresAt!);
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}
