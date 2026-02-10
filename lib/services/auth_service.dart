import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Mengambil instance Supabase Client untuk akses Auth dan Database
  final _supabase = Supabase.instance.client;

  // ==========================================================
  // 1. FUNGSI LOGIN (EMAIL & PASSWORD)
  // Menangani proses masuk user sekaligus mengambil profil dari database.
  // ==========================================================
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      // --- LANGKAH 1: Login ke Supabase Auth ---
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = res.user;

      if (user == null) return null;

      // --- LANGKAH 2: Ambil UUID user dari Auth ---
      final String authId = user.id;

      // --- LANGKAH 3: Ambil Data Profil dari Tabel 'users' ---
      final data = await _supabase
          .from('users')
          .select()
          .eq('auth_id', authId)
          .single();

      return data; // Mengembalikan data user (nama, role, nip, dsb)
      
    } on AuthException catch (e) {
      print("❌ Auth Error: ${e.message}");
      return null;
    } catch (e) {
      print("❌ Database Error: $e");
      return null;
    }
  }

  // ==========================================================
  // 2. FUNGSI UPDATE PROFIL LENGKAP (BARU)
  // Mengupdate data detail user di tabel 'users' berdasarkan auth_id.
  // Menghubungkan NIP, Email, No Telp, dan Lokasi Kerja.
  // ==========================================================
  Future<String?> updateProfile({
    required String authId,
    required String nama,
    required String nip,
    required String email,
    required String nomorTelepon,
    required String lokasiKerja,
  }) async {
    try {
      // Melakukan update ke tabel 'users' pada baris yang memiliki auth_id sesuai
      await _supabase.from('users').update({
        'nama': nama,
        'nip': nip,
        'email': email,
        'nomor_telepon': nomorTelepon, // Pastikan nama kolom di database sama
        'lokasi_kerja': lokasiKerja,   // Pastikan nama kolom di database sama
      }).eq('auth_id', authId);

      return null; // Mengembalikan null jika berhasil (tidak ada error)
    } catch (e) {
      print("❌ Update Profil Error: $e");
      return e.toString(); // Mengembalikan pesan error jika gagal
    }
  }

  // ==========================================================
  // 3. FUNGSI LOGOUT
  // Menghapus session aktif user dari aplikasi dan server.
  // ==========================================================
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // ==========================================================
  // 4. GET CURRENT USER (OBJEK LENGKAP)
  // Mengambil informasi mentah user yang sedang login dari Supabase Auth.
  // ==========================================================
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // ==========================================================
  // 5. GET AUTH ID (HANYA UUID)
  // Mengambil string ID (UUID) user untuk digunakan sebagai referensi tabel lain.
  // ==========================================================
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }
}