import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Fungsi Login menggunakan Email & Password
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      // 1. Autentikasi ke Supabase Auth
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final User? user = res.user;

      if (user != null) {
        // 2. Ambil data Role dan Nama dari tabel public.users berdasarkan auth_id
        final data = await _supabase
            .from('users')
            .select()
            .eq('auth_id', user.id)
            .single();
        
        return data; // Mengembalikan data user lengkap (nama, role, dll)
      }
      return null;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // Fungsi Logout
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}