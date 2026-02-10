import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlatService {
  // Inisialisasi client Supabase untuk akses database dan storage
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================================
  // KONFIGURASI NAMA TABEL & STORAGE
  // ==========================================================
  
  // Nama Bucket di Supabase Storage untuk menyimpan file gambar
  final String _produkBucket = 'produk_images';

  // Konfigurasi untuk Tabel 'keyboard'
  final String _keyboardTable = 'keyboard';
  final String _imageColumnKeyboard = 'image_url';

  // Konfigurasi untuk Tabel 'alat'
  final String _imageColumnAlat = 'image_url';

  // ==========================================================
  // 1. TAMBAH ALAT (TANPA FOTO)
  // Digunakan untuk input data aset alat ke tabel 'alat' 
  // tanpa menyertakan file gambar.
  // ==========================================================
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
        'status': 'tersedia', // Status default saat alat baru didaftarkan
        'id_kategori': idKategori,
      });
      return null; // Mengembalikan null jika operasi berhasil
    } catch (e) {
      return e.toString(); // Mengembalikan pesan error jika gagal
    }
  }

  // ==========================================================
  // 2. TAMBAH KEYBOARD ADMIN (DENGAN FOTO)
  // Fungsi khusus untuk mengupload gambar ke storage terlebih dahulu,
  // lalu menyimpan URL gambar tersebut ke dalam tabel 'keyboard'.
  // ==========================================================
  Future<String?> addKeyboardAdmin({
    required String merk,
    required String spesifikasi,
    required String kategori,
    required Uint8List imageBytes, // Data biner gambar
    required String fileName,      // Nama asli file
  }) async {
    try {
      // 1) Proses Upload Foto ke Storage
      // Menghilangkan spasi pada nama file agar URL tidak error
      final String safeName = fileName.replaceAll(' ', '_');
      // Membuat nama file unik menggunakan timestamp agar tidak duplikat
      final String path =
          'keyboard_${DateTime.now().millisecondsSinceEpoch}_$safeName';

      final storage = _supabase.storage.from(_produkBucket);

      await storage.uploadBinary(
        path,
        imageBytes,
        fileOptions: const FileOptions(
          upsert: false, // Jangan timpa jika file sudah ada (karena nama unik)
          contentType: 'image/jpeg',
        ),
      );

      // 2) Mendapatkan Link/URL Gambar yang bisa diakses publik
      final String publicUrl = storage.getPublicUrl(path);

      // 3) Insert data teks dan URL gambar ke tabel 'keyboard'
      await _supabase.from(_keyboardTable).insert({
        'merk': merk,
        'spesifikasi': spesifikasi,
        'kategori': kategori,
        _imageColumnKeyboard: publicUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      return null; 
    } catch (e) {
      return e.toString();
    }
  }

  // ==========================================================
  // 3. TAMBAH ALAT DENGAN FOTO (REKOMENDASI UNTUK TABEL ALAT)
  // Menangani upload gambar ke storage dan memasukkan datanya ke
  // tabel 'alat' sesuai struktur (kode_aset, merk, dll).
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
      // 1) Proses Upload Foto ke Storage
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

      // 2) Mendapatkan Link/URL Gambar publik
      final String publicUrl = storage.getPublicUrl(path);

      // 3) Insert data lengkap ke tabel 'alat'
      await _supabase.from('alat').insert({
        'kode_aset': kodeAset,
        'merk': merk,
        'spesifikasi': spesifikasi,
        'status': 'tersedia',
        'id_kategori': idKategori,
        _imageColumnAlat: publicUrl,
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ==========================================================
  // 4. AMBIL SEMUA DATA ALAT
  // Mengambil daftar alat terbaru dari database.
  // ==========================================================
  Future<List<Map<String, dynamic>>> getAlat() async {
    final data = await _supabase
        .from('alat')
        .select()
        .order('id_alat', ascending: false); // Urutkan dari yang terbaru (ID terbesar)

    return List<Map<String, dynamic>>.from(data);
  }

  // ==========================================================
  // 5. AMBIL SEMUA DATA KEYBOARD
  // Fungsi opsional untuk mengambil daftar dari tabel 'keyboard'.
  // ==========================================================
  Future<List<Map<String, dynamic>>> getKeyboard() async {
    final data = await _supabase
        .from(_keyboardTable)
        .select()
        .order('id', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }
}