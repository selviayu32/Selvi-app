import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // 1. Pastikan Flutter sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Hubungkan ke Supabase (GANTI DENGAN DATA KAMU)
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
      title: 'Rental Keyboard UKK',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TestConnectionScreen(),
    );
  }
}

class TestConnectionScreen extends StatelessWidget {
  const TestConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 100),
            SizedBox(height: 20),
            Text(
              'Koneksi Berhasil!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Siap lanjut ke halaman Login (Target 4)'),
          ],
        ),
      ),
    );
  }
}