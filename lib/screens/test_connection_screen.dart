import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ================= KOMENTAR: Entry Point Utama =================
// Fungsi main didefinisikan sebagai 'async' karena proses inisialisasi Supabase 
// membutuhkan waktu untuk menghubungi server (asynchronous).
void main() async {
  // 1. Pastikan Flutter sudah siap
  // Memastikan engine Flutter sudah terinisialisasi dengan benar sebelum melakukan
  // operasi asinkron seperti inisialisasi Supabase.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Hubungkan ke Supabase (GANTI DENGAN DATA KAMU)
  // Fungsi ini mendaftarkan URL proyek dan Anonymous Key agar aplikasi 
  // bisa berkomunikasi dengan database dan autentikasi Supabase.
  await Supabase.initialize(
    url: 'https://ythqqlnqgkrvqmulshvt.supabase.co', 
    anonKey: 'sb_publishable_bv7hsKE_q8DOZQRA5EQ4Bg_F7Lftb9D',
  );

  // Menjalankan widget utama aplikasi
  runApp(const MyApp());
}

// ================= KOMENTAR: Konfigurasi Root Aplikasi =================
// MyApp adalah widget utama yang mengatur tema, judul, dan halaman pertama yang muncul.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Menghilangkan banner "DEBUG" di pojok kanan atas
      title: 'Rental Keyboard UKK',
      theme: ThemeData(
        // Mengatur skema warna aplikasi berbasis warna biru
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true, // Mengaktifkan desain Material 3 terbaru
      ),
      // Halaman yang pertama kali ditampilkan saat aplikasi dibuka
      home: const TestConnectionScreen(),
    );
  }
}

// ================= KOMENTAR: Halaman Pengetesan Koneksi =================
// Screen ini berfungsi sebagai indikator visual bahwa setup Supabase di fungsi main() 
// telah berjalan tanpa error (Target 4 dalam rencana pengembangan Anda).
class TestConnectionScreen extends StatelessWidget {
  const TestConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // Mengatur isi halaman agar berada tepat di tengah layar
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Pusatkan elemen secara vertikal
          children: [
            // Ikon centang hijau sebagai simbol sukses
            Icon(Icons.check_circle, color: Colors.green, size: 100),
            
            SizedBox(height: 20), // Memberi jarak antar elemen
            
            // Judul utama informasi koneksi
            Text(
              'Koneksi Berhasil!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            
            // Deskripsi langkah selanjutnya (Halaman Login)
            Text('Siap lanjut ke halaman Login (Target 4)'),
          ],
        ),
      ),
    );
  }
}