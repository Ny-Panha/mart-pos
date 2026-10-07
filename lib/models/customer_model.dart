class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final int points;
  final String address;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.points = 0,
    this.address = 'បាត់ដំបង',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'points': points,
      'address': address,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map, String docId) {
    return CustomerModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      points: (map['points'] is num) ? (map['points'] as num).toInt() : 0,
      address: map['address'] ?? 'បាត់ដំបង',
    );
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    int? points,
    String? address,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      points: points ?? this.points,
      address: address ?? this.address,
    );
  }
}
