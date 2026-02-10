import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart'; // 👈 TAMBAHKAN INI: Mengimpor halaman splash sebagai pintu masuk utama

// ==========================================================
// 1. FUNGSI MAIN (ENTRY POINT)
// Tempat pertama kali aplikasi dijalankan. 
// Menggunakan 'async' karena butuh menunggu koneksi ke database.
// ==========================================================
void main() async {
  // --- LANGKAH 1: Persiapan Binding ---
  // Memastikan framework Flutter benar-benar siap sebelum mengeksekusi kode lainnya.
  WidgetsFlutterBinding.ensureInitialized();

  // --- LANGKAH 2: Inisialisasi Supabase ---
  // Menghubungkan aplikasi Flutter dengan server Supabase Anda menggunakan URL dan Key.
  await Supabase.initialize(
    url: 'https://ythqqlnqgkrvqmulshvt.supabase.co',
    anonKey: 'sb_publishable_bv7hsKE_q8DOZQRA5EQ4Bg_F7Lftb9D',
  );

  // --- LANGKAH 3: Menjalankan Widget Utama ---
  runApp(const MyApp());
}

// ==========================================================
// 2. CLASS MYAPP (KONFIGURASI APLIKASI)
// Mengatur tema global, judul aplikasi, dan navigasi awal.
// ==========================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Menyembunyikan label 'debug' di layar
      title: 'Pinjam Keyboard',
      
      // Konfigurasi Tema Aplikasi
      theme: ThemeData(
        // Menggunakan skema warna otomatis berbasis warna biru
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true, // Mengaktifkan komponen Material Design 3 (terbaru)
      ),

      // 👇 START APLIKASI DARI SPLASH
      // Menentukan bahwa saat aplikasi pertama kali dibuka, 
      // yang muncul adalah SplashScreen (Halaman Animasi/Loading awal).
      home: const SplashScreen(),
    );
  }
}