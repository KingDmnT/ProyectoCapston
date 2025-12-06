class Community {
  final String id;
  final String name;
  final String address;
  final String comuna;
  final String region;
  final bool isActive;
  
  // Nuevos campos
  final double? latitude;
  final double? longitude;
  final String? constructora;
  final String? inmobiliaria;
  final String? fechaEntregaInicial; // String YYYY-MM-DD
  final String? description;
  final String? contactEmail;
  final String? contactPhone;

  Community({
    required this.id,
    required this.name,
    required this.address,
    required this.comuna,
    required this.region,
    required this.isActive,
    this.latitude,
    this.longitude,
    this.constructora,
    this.inmobiliaria,
    this.fechaEntregaInicial,
    this.description,
    this.contactEmail,
    this.contactPhone,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      comuna: json['comuna'] ?? '',
      region: json['region'] ?? '',
      isActive: json['is_active'] ?? false,
      latitude: json['latitude'],
      longitude: json['longitude'],
      constructora: json['constructora'],
      inmobiliaria: json['inmobiliaria'],
      fechaEntregaInicial: json['fecha_entrega_inicial'],
      description: json['description'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'comuna': comuna,
      'region': region,
      'latitude': latitude,
      'longitude': longitude,
      'constructora': constructora,
      'inmobiliaria': inmobiliaria,
      'fecha_entrega_inicial': fechaEntregaInicial,
      'description': description,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
    };
  }
}
