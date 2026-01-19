import 'package:supabase_flutter/supabase_flutter.dart';

class KategoriService {
  final _supabase = Supabase.instance.client;

  // Fungsi mengambil semua data kategori
  Future<List<Map<String, dynamic>>> getKategori() async {
    final response = await _supabase.from('kategori').select();
    return List<Map<String, dynamic>>.from(response);
  }
}