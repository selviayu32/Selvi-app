import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // ================= LOGIN =================
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      // 1. Login ke Supabase Auth
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = res.user;

      if (user == null) return null;

      // 2. Ambil UUID user dari Supabase Auth
      final String authId = user.id;

      // 3. Ambil data profil dari tabel public.users berdasarkan auth_id (UUID)
      final data = await _supabase
          .from('users')
          .select()
          .eq('auth_id', authId)
          .single();

      return data; // return data user (nama, role, dll)
    } on AuthException catch (e) {
      print("❌ Auth Error: ${e.message}");
      return null;
    } catch (e) {
      print("❌ Database Error: $e");
      return null;
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // ================= GET CURRENT USER UUID =================
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // ================= GET AUTH UUID =================
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }
}
