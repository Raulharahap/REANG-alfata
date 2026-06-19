class MitraPlesirModel {
  final int? id;
  final int? idUser;
  final String nama;
  final String deskripsi;
  final String alamat;
  final String kontak;
  final String? foto;
  final int? isActive;

  MitraPlesirModel({
    this.id,
    this.idUser,
    required this.nama,
    required this.deskripsi,
    required this.alamat,
    required this.kontak,
    this.foto,
    this.isActive,
  });

  factory MitraPlesirModel.fromJson(Map<String, dynamic> json) {
    return MitraPlesirModel(
      id: json['id'],
      idUser: json['id_user'],
      nama: json['nama'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      alamat: json['alamat'] ?? '',
      kontak: json['kontak'] ?? '',
      foto: json['foto'],
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'nama': nama,
      'deskripsi': deskripsi,
      'alamat': alamat,
      'kontak': kontak,
    };
  }
}
