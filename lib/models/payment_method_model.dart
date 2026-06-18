// Lokasi: lib/models/payment_method_model.dart

class PaymentMethodModel {
  final int id;
  final int idToko;
  final String namaMetode; // "Transfer BCA"
  final String jenis; // "bank"
  final String namaPenerima; // "UMKM Reang"
  final String nomorTujuan; // "1234567890"
  final String? fotoQris;
  final String? keterangan;

  PaymentMethodModel({
    required this.id,
    required this.idToko,
    required this.namaMetode,
    required this.jenis,
    required this.namaPenerima,
    required this.nomorTujuan,
    this.fotoQris,
    this.keterangan,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'],
      idToko: json['id_toko'],
      namaMetode: json['nama_metode'] ?? 'Metode Tidak Diketahui',
      jenis: json['jenis'] ?? 'bank',
      namaPenerima: json['nama_penerima'] ?? '',
      nomorTujuan: json['nomor_tujuan'] ?? '',
      fotoQris: json['foto_qris'],
      keterangan: json['keterangan'],
    );
  }
}
