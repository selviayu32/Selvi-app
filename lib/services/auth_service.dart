import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Fungsi Login
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('username', username)
          .eq('password', password)
          .maybeSingle(); // Mengambil 1 data saja
      
      return response;
    } catch (e) {
      return null;
    }
  }
}