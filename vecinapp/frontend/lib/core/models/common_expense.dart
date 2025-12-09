import 'package:intl/intl.dart';

// Enums
enum ExpenseStatus {
  draft,
  closed,
  notified;

  String get value {
    switch (this) {
      case ExpenseStatus.draft:
        return 'draft';
      case ExpenseStatus.closed:
        return 'closed';
      case ExpenseStatus.notified:
        return 'notified';
    }
  }

  String get displayName {
    switch (this) {
      case ExpenseStatus.draft:
        return 'Borrador';
      case ExpenseStatus.closed:
        return 'Cerrado';
      case ExpenseStatus.notified:
        return 'Notificado';
    }
  }

  static ExpenseStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'draft':
        return ExpenseStatus.draft;
      case 'closed':
        return ExpenseStatus.closed;
      case 'notified':
        return ExpenseStatus.notified;
      default:
        return ExpenseStatus.draft;
    }
  }
}

enum ExpenseCategory {
  remuneraciones,
  gastosExtraordinarios,
  mantencion,
  serviciosComunes;

  String get value {
    switch (this) {
      case ExpenseCategory.remuneraciones:
        return 'remuneraciones';
      case ExpenseCategory.gastosExtraordinarios:
        return 'gastos_extraordinarios';
      case ExpenseCategory.mantencion:
        return 'mantencion';
      case ExpenseCategory.serviciosComunes:
        return 'servicios_comunes';
    }
  }

  String get displayName {
    switch (this) {
      case ExpenseCategory.remuneraciones:
        return 'Remuneraciones';
      case ExpenseCategory.gastosExtraordinarios:
        return 'Gastos Extraordinarios';
      case ExpenseCategory.mantencion:
        return 'Mantención';
      case ExpenseCategory.serviciosComunes:
        return 'Servicios Comunes';
    }
  }

  static ExpenseCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'remuneraciones':
        return ExpenseCategory.remuneraciones;
      case 'gastos_extraordinarios':
        return ExpenseCategory.gastosExtraordinarios;
      case 'mantencion':
        return ExpenseCategory.mantencion;
      case 'servicios_comunes':
        return ExpenseCategory.serviciosComunes;
      default:
        return ExpenseCategory.remuneraciones;
    }
  }
}

// Modelos
class ExpenseLineItem {
  final String description;
  final double amount;
  final String? docNumber;
  final DateTime? date;
  final List<String>? maintenanceIds;

  ExpenseLineItem({
    required this.description,
    required this.amount,
    this.docNumber,
    this.date,
    this.maintenanceIds,
  });

  factory ExpenseLineItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['date'] != null) {
      try {
        parsedDate = DateTime.parse(json['date']);
      } catch (e) {
        parsedDate = null;
      }
    }

    return ExpenseLineItem(
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      docNumber: json['doc_number'],
      date: parsedDate,
      maintenanceIds: json['maintenance_ids'] != null 
          ? List<String>.from(json['maintenance_ids']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'doc_number': docNumber,
      'date': date?.toIso8601String(),
      'maintenance_ids': maintenanceIds,
    };
  }
}

class UnitExpense {
  final String unitId;
  final String unitName;
  final double alicuota;
  final double amount;
  final String? residentUid;
  final String? residentName;
  final String? residentEmail;
  final String? pdfUrl;

  UnitExpense({
    required this.unitId,
    required this.unitName,
    required this.alicuota,
    required this.amount,
    this.residentUid,
    this.residentName,
    this.residentEmail,
    this.pdfUrl,
  });

  factory UnitExpense.fromJson(Map<String, dynamic> json) {
    return UnitExpense(
      unitId: json['unit_id'] ?? '',
      unitName: json['unit_name'] ?? '',
      alicuota: (json['alicuota'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      residentUid: json['resident_uid'],
      residentName: json['resident_name'],
      residentEmail: json['resident_email'],
      pdfUrl: json['pdf_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unit_id': unitId,
      'unit_name': unitName,
      'alicuota': alicuota,
      'amount': amount,
      'resident_uid': residentUid,
      'resident_name': residentName,
      'resident_email': residentEmail,
      'pdf_url': pdfUrl,
    };
  }
}

class CommonExpense {
  final String id;
  final String communityId;
  final String period;
  final int month;
  final int year;
  final ExpenseStatus status;
  final double totalAmount;
  final Map<String, List<ExpenseLineItem>> items;
  final List<UnitExpense> unitExpenses;
  final String? closedBy;
  final DateTime? closedAt;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommonExpense({
    required this.id,
    required this.communityId,
    required this.period,
    required this.month,
    required this.year,
    required this.status,
    required this.totalAmount,
    required this.items,
    required this.unitExpenses,
    this.closedBy,
    this.closedAt,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommonExpense.fromJson(Map<String, dynamic> json) {
    // Parsear items
    Map<String, List<ExpenseLineItem>> parsedItems = {};
    if (json['items'] != null && json['items'] is Map) {
      (json['items'] as Map<String, dynamic>).forEach((key, value) {
        if (value is List) {
          parsedItems[key] = value
              .map((item) => ExpenseLineItem.fromJson(item))
              .toList();
        }
      });
    }

    // Parsear unit_expenses
    List<UnitExpense> parsedUnitExpenses = [];
    if (json['unit_expenses'] != null && json['unit_expenses'] is List) {
      parsedUnitExpenses = (json['unit_expenses'] as List)
          .map((ue) => UnitExpense.fromJson(ue))
          .toList();
    }

    // Parsear fechas
    DateTime? parsedClosedAt;
    if (json['closed_at'] != null) {
      try {
        parsedClosedAt = DateTime.parse(json['closed_at']);
      } catch (e) {
        parsedClosedAt = null;
      }
    }

    return CommonExpense(
      id: json['id'] ?? '',
      communityId: json['community_id'] ?? '',
      period: json['period'] ?? '',
      month: json['month'] ?? 1,
      year: json['year'] ?? 2025,
      status: ExpenseStatus.fromString(json['status'] ?? 'draft'),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      items: parsedItems,
      unitExpenses: parsedUnitExpenses,
      closedBy: json['closed_by'],
      closedAt: parsedClosedAt,
      createdBy: json['created_by'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> itemsJson = {};
    items.forEach((key, value) {
      itemsJson[key] = value.map((item) => item.toJson()).toList();
    });

    return {
      'id': id,
      'community_id': communityId,
      'period': period,
      'month': month,
      'year': year,
      'status': status.value,
      'total_amount': totalAmount,
      'items': itemsJson,
      'unit_expenses': unitExpenses.map((ue) => ue.toJson()).toList(),
      'closed_by': closedBy,
      'closed_at': closedAt?.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helpers
  bool get isDraft => status == ExpenseStatus.draft;
  bool get isClosed => status == ExpenseStatus.closed;
  bool get isNotified => status == ExpenseStatus.notified;

  double getCategoryTotal(String category) {
    if (!items.containsKey(category)) return 0.0;
    return items[category]!.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Método estático para obtener el nombre del mes
  static String getMonthName(int month) {
    const monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    if (month < 1 || month > 12) return 'Mes inválido';
    return monthNames[month - 1];
  }

  String get periodDisplay {
    final monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${monthNames[month - 1]} $year';
  }

  // Determina si el gasto está vencido (asumiendo vencimiento día 28 del mes siguiente)
  bool get isOverdue {
    if (!isClosed && !isNotified) return false;
    
    final now = DateTime.now();
    int dueMonth = month == 12 ? 1 : month + 1;
    int dueYear = month == 12 ? year + 1 : year;
    final dueDate = DateTime(dueYear, dueMonth, 28);
    
    return now.isAfter(dueDate);
  }

  String get paymentStatus {
    if (isDraft) return 'En preparación';
    if (isOverdue) return 'Vencido';
    return 'Al día';
  }
}
