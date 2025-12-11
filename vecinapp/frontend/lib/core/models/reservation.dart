// Modelo de reserva para VecinApp

enum SpaceType {
  salon,
  piscina,
  cancha,
  quincho,
}

extension SpaceTypeExtension on SpaceType {
  String get value {
    switch (this) {
      case SpaceType.salon:
        return 'salon';
      case SpaceType.piscina:
        return 'piscina';
      case SpaceType.cancha:
        return 'cancha';
      case SpaceType.quincho:
        return 'quincho';
    }
  }

  String get displayName {
    switch (this) {
      case SpaceType.salon:
        return '🏛️ Salón de Eventos';
      case SpaceType.piscina:
        return '🏊 Piscina';
      case SpaceType.cancha:
        return '⚽ Cancha Deportiva';
      case SpaceType.quincho:
        return '🍖 Quincho';
    }
  }

  static SpaceType fromString(String typeStr) {
    switch (typeStr) {
      case 'salon':
        return SpaceType.salon;
      case 'piscina':
        return SpaceType.piscina;
      case 'cancha':
        return SpaceType.cancha;
      case 'quincho':
        return SpaceType.quincho;
      default:
        return SpaceType.salon;
    }
  }
}

enum ReservationStatus {
  pendiente,
  aprobada,
  rechazada,
  cancelada,
}

extension ReservationStatusExtension on ReservationStatus {
  String get value {
    switch (this) {
      case ReservationStatus.pendiente:
        return 'pendiente';
      case ReservationStatus.aprobada:
        return 'aprobada';
      case ReservationStatus.rechazada:
        return 'rechazada';
      case ReservationStatus.cancelada:
        return 'cancelada';
    }
  }

  String get displayName {
    switch (this) {
      case ReservationStatus.pendiente:
        return 'Pendiente';
      case ReservationStatus.aprobada:
        return 'Aprobada';
      case ReservationStatus.rechazada:
        return 'Rechazada';
      case ReservationStatus.cancelada:
        return 'Cancelada';
    }
  }

  static ReservationStatus fromString(String statusStr) {
    switch (statusStr) {
      case 'pendiente':
        return ReservationStatus.pendiente;
      case 'aprobada':
        return ReservationStatus.aprobada;
      case 'rechazada':
        return ReservationStatus.rechazada;
      case 'cancelada':
        return ReservationStatus.cancelada;
      default:
        return ReservationStatus.pendiente;
    }
  }
}

class Reservation {
  final String id;
  final SpaceType spaceType;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String purpose;
  final int attendees;
  final ReservationStatus status;
  final String communityId;
  final String createdBy;
  final String? adminNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Reservation({
    required this.id,
    required this.spaceType,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.purpose,
    required this.attendees,
    required this.status,
    required this.communityId,
    required this.createdBy,
    this.adminNotes,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status == ReservationStatus.pendiente;
  bool get isApproved => status == ReservationStatus.aprobada;
  bool get isRejected => status == ReservationStatus.rechazada;
  bool get isCanceled => status == ReservationStatus.cancelada;

  factory Reservation.fromJson(Map<String, dynamic> json) {
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

    TimeOfDay parseTime(String timeStr) {
      try {
        final parts = timeStr.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (e) {
        return const TimeOfDay(hour: 0, minute: 0);
      }
    }

    return Reservation(
      id: json['id'] ?? '',
      spaceType: SpaceTypeExtension.fromString(json['space_type'] ?? 'salon'),
      date: parseDate(json['date']) ?? DateTime.now(),
      startTime: parseTime(json['start_time'] ?? '00:00:00'),
      endTime: parseTime(json['end_time'] ?? '00:00:00'),
      purpose: json['purpose'] ?? '',
      attendees: json['attendees'] ?? 0,
      status: ReservationStatusExtension.fromString(json['status'] ?? 'pendiente'),
      communityId: json['community_id'] ?? '',
      createdBy: json['created_by'] ?? '',
      adminNotes: json['admin_notes'],
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    String formatTime(TimeOfDay time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute:00';
    }

    return {
      'id': id,
      'space_type': spaceType.value,
      'date': date.toIso8601String().split('T')[0],
      'start_time': formatTime(startTime),
      'end_time': formatTime(endTime),
      'purpose': purpose,
      'attendees': attendees,
      'status': status.value,
      'community_id': communityId,
      'created_by': createdBy,
      'admin_notes': adminNotes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Reservation copyWith({
    String? id,
    SpaceType? spaceType,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? purpose,
    int? attendees,
    ReservationStatus? status,
    String? communityId,
    String? createdBy,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      spaceType: spaceType ?? this.spaceType,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      purpose: purpose ?? this.purpose,
      attendees: attendees ?? this.attendees,
      status: status ?? this.status,
      communityId: communityId ?? this.communityId,
      createdBy: createdBy ?? this.createdBy,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});
  
  @override
  String toString() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
