import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Fungsi Login menggunakan Email & Password
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      // 1. Autentikasi ke Supabase Auth (Gunakan .trim() untuk hapus spasi tak sengaja)
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = res.user;

      if (user != null) {
        // 2. Ambil data profil dari tabel public.users
        // Karena query SQL tadi sudah sukses, kolom 'email' sekarang sudah ada
        final data = await _supabase
            .from('users')
            .select()
            .eq('email', email.trim()) 
            .single();
        
        return data; 
      }
      return null;
    } on AuthException catch (e) {
      // Menangkap error khusus dari Supabase Auth (misal: Password salah)
      print("Auth Error: ${e.message}");
      return null;
    } catch (e) {
      // Menangkap error lainnya (misal: kolom email tidak ditemukan di tabel)
      print("Database/General Error: $e");
      return null;
    }
  }

  // Fungsi Logout
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Opsional: Fungsi untuk mendapatkan user yang sedang login saat ini
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
}