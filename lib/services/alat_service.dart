import 'package:supabase_flutter/supabase_flutter.dart';

class AlatService {
  final _supabase = Supabase.instance.client;

  // Fungsi untuk menambah alat baru
  Future<void> tambahAlat(String nama, String merk, String spek, int stok, int idKat) async {
    await _supabase.from('alat').insert({
      'nama_alat': nama,
      'merk': merk,
      'spesifikasi': spek,
      'stok': stok,
      'status': 'tersedia',
      'id_kategori': idKat,
    });
  }

  getAlat() {}
}