// lib/models/detail_transaksi_response.dart

// Model ini akan berisi data 'transaksi' dari backend
// Kita bisa gunakan ulang model RiwayatTransaksiModel, tapi mari kita buat
// model 'transaksi' yang lebih spesifik untuk detail jika diperlukan.
// Untuk saat ini, kita anggap struktur 'transaksi'-nya mirip dengan Riwayat.
import 'package:reang_app/models/riwayat_transaksi_model.dart';

// Model untuk item-item produk di detail
class ItemDetailModel {
  final int id;
  final String noTransaksi;
  final int idProduk;
  final int idToko;
  final int jumlah;
  final double harga;
  final double subtotal;
  final String namaProduk;
  final String? foto;

  ItemDetailModel({
    required this.id,
    required this.noTransaksi,
    required this.idProduk,
    required this.idToko,
    required this.jumlah,
    required this.harga,
    required this.subtotal,
    required this.namaProduk,
    this.foto,
  });

  factory ItemDetailModel.fromJson(Map<String, dynamic> json) {
    double _parseDouble(dynamic value) {
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      } else if (value is num) {
        return value.toDouble();
      }
      return 0.0;
    }

    return ItemDetailModel(
      id: json['id'] as int,
      noTransaksi: json['no_transaksi'] as String,
      idProduk: json['id_produk'] as int,
      idToko: json['id_toko'] as int,
      jumlah: json['jumlah'] as int,
      harga: _parseDouble(json['harga']),
      subtotal: _parseDouble(json['subtotal']),
      namaProduk: json['nama_produk'] as String,
      foto: json['foto'] as String?,
    );
  }
}

// Model ini adalah respons utuh dari endpoint detail
class DetailTransaksiResponse {
  // 'transaksi' di sini memiliki data yang SAMA persis
  // dengan 'RiwayatTransaksiModel'
  final RiwayatTransaksiModel transaksi;
  final List<ItemDetailModel> items;

  DetailTransaksiResponse({required this.transaksi, required this.items});

  factory DetailTransaksiResponse.fromJson(Map<String, dynamic> json) {
    return DetailTransaksiResponse(
      transaksi: RiwayatTransaksiModel.fromJson(json['transaksi']),
      items: (json['items'] as List)
          .map((itemJson) => ItemDetailModel.fromJson(itemJson))
          .toList(),
    );
  }
}
