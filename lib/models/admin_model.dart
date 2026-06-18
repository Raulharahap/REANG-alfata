class AdminModel {
  final int id;
  final String name;
  final String role;

  AdminModel({required this.id, required this.name, required this.role});

  // --- TAMBAHKAN FUNGSI INI ---
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'role': role};
  }

  factory AdminModel.fromMap(Map<String, dynamic> map) {
    return AdminModel(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      role: map['role'] ?? 'user',
    );
  }
}
