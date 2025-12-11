class IncidentComment {
  final String id;
  final String incidentId;
  final String commentText;
  final String userId;
  final String userName;
  final String userRole;
  final DateTime createdAt;
  final bool isResolutionComment;

  IncidentComment({
    required this.id,
    required this.incidentId,
    required this.commentText,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.createdAt,
    this.isResolutionComment = false,
  });

  factory IncidentComment.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
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

    return IncidentComment(
      id: json['id'] ?? '',
      incidentId: json['incident_id'] ?? '',
      commentText: json['comment_text'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? 'Usuario',
      userRole: json['user_role'] ?? 'resident',
      createdAt: parseDate(json['created_at']),
      isResolutionComment: json['is_resolution_comment'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'incident_id': incidentId,
      'comment_text': commentText,
      'user_id': userId,
      'user_name': userName,
      'user_role': userRole,
      'created_at': createdAt.toIso8601String(),
      'is_resolution_comment': isResolutionComment,
    };
  }
}
