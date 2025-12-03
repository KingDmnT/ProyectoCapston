class Community {
  final String id;
  final String name;
  final String address;
  final String comuna;
  final String region;
  final bool isActive;

  Community({
    required this.id,
    required this.name,
    required this.address,
    required this.comuna,
    required this.region,
    required this.isActive,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      comuna: json['comuna'] ?? '',
      region: json['region'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'comuna': comuna,
      'region': region,
    };
  }
}
