import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    // 1. Mengatur Timer untuk durasi tampilan splash
    // Delay selama 3 detik sebelum mengeksekusi perpindahan halaman
    Timer(const Duration(seconds: 3), () {
      // 2. Navigasi ke LoginScreen
      // Menggunakan pushReplacement agar user tidak bisa kembali ke Splash saat menekan tombol back
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan warna latar belakang yang konsisten dengan tema aplikasi
      backgroundColor: const Color(0xFFAECbFA), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 3. Menampilkan Logo Aplikasi
            Image.asset(
              'assets/logo.png', // Pastikan file ini terdaftar di pubspec.yaml
              width: 180,
            ),
            const SizedBox(height: 20),
            // 4. Menampilkan Nama Aplikasi atau Slogan
            const Text(
              "PINJAM KEYBOARD",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5, // Memberikan sedikit jarak antar huruf agar elegan
              ),
            )
          ],
        ),
      ),
    );
  }
}