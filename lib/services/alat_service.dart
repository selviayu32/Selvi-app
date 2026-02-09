import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================
  // STORAGE BUCKET (sesuai Supabase kamu)
  // ==========================================
  final String _produkBucket = 'produk_images';

  // ==========================================
  // KEYBOARD TABLE (punya kamu)
  // ==========================================
  final String _keyboardTable = 'keyboard';
  final String _imageColumnKeyboard = 'image_url';

  // ==========================================
  // ALAT TABLE (sesuai Supabase kamu)
  // kolom gambar: image_url
  // ==========================================
  final String _imageColumnAlat = 'image_url';

  // =========================
  // ALAT (tanpa foto) - UPDATE sesuai tabel supabase kamu
  // Tabel alat tidak punya: nama_alat, stok
  // Tabel alat punya: kode_aset, merk, spesifikasi, status, id_kategori, image_url
  // =========================
  Future<String?> tambahAlat({
    required String kodeAset,
    required String merk,
    required String spesifikasi,
    required int idKategori,
  }) async {
    try {
      await _supabase.from('alat').insert({
        'kode_aset': kodeAset,
        'merk': merk,
        'spesifikasi': spesifikasi,
        'status': 'tersedia',
        'id_kategori': idKategori,
      });
      return null; // sukses
    } catch (e) {
      return e.toString();
    }
  }

  // ==========================================
  // KEYBOARD ADMIN (UPLOAD FOTO + INSERT KEYBOARD)
  // ==========================================
  Future<String?> addKeyboardAdmin({
    required String merk,
    required String spesifikasi,
    required String kategori,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // 1) Upload foto ke Storage
      final String safeName = fileName.replaceAll(' ', '_');
      final String path =
          'keyboard_${DateTime.now().millisecondsSinceEpoch}_$safeName';

      final storage = _supabase.storage.from(_produkBucket);

      await storage.uploadBinary(
        path,
        imageBytes,
        fileOptions: const FileOptions(
          upsert: false,
          contentType: 'image/jpeg',
        ),
      );

      // 2) Ambil URL public
      final String publicUrl = storage.getPublicUrl(path);

      // 3) Insert ke tabel keyboard
      await _supabase.from(_keyboardTable).insert({
        'merk': merk,
        'spesifikasi': spesifikasi,
        'kategori': kategori,
        _imageColumnKeyboard: publicUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      return null; // sukses
    } catch (e) {
      return e.toString();
    }
  }

  // ==========================================================
  // ✅ ALAT DENGAN FOTO (UPLOAD FOTO + INSERT KE 'alat')
  // sesuai tabel supabase kamu (kode_aset, merk, spesifikasi, id_kategori, image_url)
  // ==========================================================
  Future<String?> tambahAlatDenganFoto({
    required String kodeAset,
    required String merk,
    required String spesifikasi,
    required int idKategori,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // 1) Upload foto ke Storage
      final String safeName = fileName.replaceAll(' ', '_');
      final String path =
          'alat_${DateTime.now().millisecondsSinceEpoch}_$safeName';

      final storage = _supabase.storage.from(_produkBucket);

      await storage.uploadBinary(
        path,
        imageBytes,
        fileOptions: const FileOptions(
          upsert: false,
          contentType: 'image/jpeg',
        ),
      );

      // 2) Ambil URL public
      final String publicUrl = storage.getPublicUrl(path);

      // 3) Insert ke tabel 'alat'
      await _supabase.from('alat').insert({
        'kode_aset': kodeAset,
        'merk': merk,
        'spesifikasi': spesifikasi,
        'status': 'tersedia',
        'id_kategori': idKategori,
        _imageColumnAlat: publicUrl,
      });

      return null; // sukses
    } catch (e) {
      return e.toString();
    }
  }

  // =========================
  // GET DATA ALAT
  // =========================
  Future<List<Map<String, dynamic>>> getAlat() async {
    final data = await _supabase
        .from('alat')
        .select()
        .order('id_alat', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // =========================
  // GET DATA KEYBOARD (opsional)
  // =========================
  Future<List<Map<String, dynamic>>> getKeyboard() async {
    final data = await _supabase
        .from(_keyboardTable)
        .select()
        .order('id', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }
}
