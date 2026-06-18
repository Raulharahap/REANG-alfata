class TokoModel {
  final int id;
  final int idUser; // <--- PENTING: Ini ID Pemilik untuk tujuan Chat
  final String nama;
  final String? deskripsi;
  final String alamat;
  final String noHp;
  final String? foto;
  final String? emailToko;
  final String? namaPemilik;
  final String? tahunBerdiri;

  TokoModel({
    required this.id,
    required this.idUser,
    required this.nama,
    this.deskripsi,
    required this.alamat,
    required this.noHp,
    this.foto,
    this.emailToko,
    this.namaPemilik,
    this.tahunBerdiri,
  });

  factory TokoModel.fromJson(Map<String, dynamic> json) {
    return TokoModel(
      id: json['id'] ?? 0,
      // Pastikan key JSON sesuai dengan kolom di database Laravel ('id_user')
      idUser: json['id_user'] is int
          ? json['id_user']
          : int.tryParse(json['id_user'].toString()) ?? 0,
      nama: json['nama'] ?? '',
      deskripsi: json['deskripsi'],
      alamat: json['alamat'] ?? '',
      noHp: json['no_hp'] ?? '',
      foto: json['foto'],
      emailToko: json['email_toko'],
      namaPemilik: json['nama_pemilik'],
      tahunBerdiri: json['tahun_berdiri'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_user': idUser,
      'nama': nama,
      'deskripsi': deskripsi,
      'alamat': alamat,
      'no_hp': noHp,
      'foto': foto,
    };
  }
}
