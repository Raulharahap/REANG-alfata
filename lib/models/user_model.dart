import 'dart:convert';

// Helper di luar kelas (dipakai oleh SecureService)
String userModelToJson(UserModel data) => json.encode(data.toMap());
UserModel userModelFromJson(String str) => UserModel.fromMap(json.decode(str));

class UserModel {
  int id;
  String name;
  String email;
  String? alamat;
  String phone;
  String noKtp;
  int? idToko;

  // --- INI PERUBAHAN UTAMA ---
  // Role bukan lagi String, tapi sebuah List dari RoleModel
  List<RoleModel> role;
  // -----------------------------

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.alamat,
    required this.phone,
    required this.noKtp,
    this.idToko,
    required this.role, // Diperbarui
  });

  // --- FUNGSI 'fromMap' (MEMPERBAIKI ERROR ANDA) ---
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Parsing 'role' dengan aman
    List<RoleModel> roles = [];
    if (map['role'] != null && map['role'] is List) {
      roles = List<RoleModel>.from(
        map['role'].map((x) => RoleModel.fromMap(x)),
      );
    }

    return UserModel(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      alamat: map['alamat'],
      phone: map['phone'] ?? '',
      noKtp: map['no_ktp'] ?? '',
      idToko: (map['id_toko'] as num?)?.toInt(),
      role: roles, // Gunakan list yang sudah diparsing
    );
  }

  // --- FUNGSI 'toMap' (MEMPERBAIKI ERROR ANDA) ---
  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "email": email,
    "alamat": alamat,
    "phone": phone,
    "no_ktp": noKtp,
    "id_toko": idToko,
    // Mengubah List<RoleModel> kembali menjadi list JSON
    "role": List<dynamic>.from(role.map((x) => x.toMap())),
  };

  // Fungsi helper (tidak wajib, tapi baik untuk ada)
  String toJson() => json.encode(toMap());
  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));
}

// --- SUB-MODEL UNTUK ROLE ---
class RoleModel {
  int id;
  String name;
  PivotModel pivot;

  RoleModel({required this.id, required this.name, required this.pivot});

  factory RoleModel.fromMap(Map<String, dynamic> map) => RoleModel(
    id: map["id"] ?? 0,
    name: map["name"] ?? '',
    pivot: PivotModel.fromMap(map["pivot"] ?? {}),
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "pivot": pivot.toMap(),
  };
}

// --- SUB-MODEL UNTUK PIVOT ---
class PivotModel {
  int userId;
  int roleId;

  PivotModel({required this.userId, required this.roleId});

  factory PivotModel.fromMap(Map<String, dynamic> map) =>
      PivotModel(userId: map["user_id"] ?? 0, roleId: map["role_id"] ?? 0);

  Map<String, dynamic> toMap() => {"user_id": userId, "role_id": roleId};
}
