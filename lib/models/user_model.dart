class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'ADMIN' or 'CASHIER'
  final String shopName;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.shopName = 'ម៉ាត សាមគ្គី (BBU Mart)',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'shopName': shopName,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? 'បុគ្គលិក',
      email: map['email'] ?? '',
      role: map['role'] ?? 'CASHIER',
      shopName: map['shopName'] ?? 'ម៉ាត សាមគ្គី (BBU Mart)',
    );
  }
}
