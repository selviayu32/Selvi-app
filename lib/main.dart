import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart'; // 👈 TAMBAHKAN INI

void main() async {
  // 1. Pastikan binding Flutter sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi koneksi ke database Supabase
  await Supabase.initialize(
    url: 'https://ythqqlnqgkrvqmulshvt.supabase.co',
    anonKey: 'sb_publishable_bv7hsKE_q8DOZQRA5EQ4Bg_F7Lftb9D',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pinjam Keyboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),

      // 👇 START APLIKASI DARI SPLASH
      home: const SplashScreen(),
    );
  }
}
