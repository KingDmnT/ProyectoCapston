class Unit {
  final String id;
  final String name;
  final int floor;
  final String type;
  final String status;
  final double alicuota;
  final double m2;
  final String? description;
  final String communityId;

  Unit({
    required this.id,
    required this.name,
    required this.floor,
    required this.type,
    required this.status,
    required this.alicuota,
    required this.m2,
    this.description,
    required this.communityId,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      floor: json['floor'] ?? 0,
      type: json['type'] ?? 'Departamento',
      status: json['status'] ?? 'Disponible',
      alicuota: (json['alicuota'] ?? 0).toDouble(),
      m2: (json['m2'] ?? 0).toDouble(),
      description: json['description'],
      communityId: json['community_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'floor': floor,
      'type': type,
      'status': status,
      'alicuota': alicuota,
      'm2': m2,
      'description': description,
      'community_id': communityId,
    };
  }
}
