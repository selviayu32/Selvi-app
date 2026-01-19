import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'beranda_screen.dart'; // Import halaman Beranda

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  void _handleLogin() async {
    final user = await _authService.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (user != null) {
      String role = user['role'];
      String nama = user['nama_lengkap'];

      // 1. Munculkan notifikasi berhasil
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Selamat Datang $nama ($role)"),
          backgroundColor: Colors.green,
        ),
      );
      
      // 2. PINDAH KE BERANDA (Menyambungkan Login ke Daftar Alat)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BerandaScreen()),
      );
      
    } else {
      // Jika salah username/password
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username atau Password Salah!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login Rental Keyboard"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Agar form di tengah
          children: [
            const Icon(Icons.keyboard_outlined, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController, 
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController, 
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ), 
              obscureText: true,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity, // Tombol selebar layar
              height: 50,
              child: ElevatedButton(
                onPressed: _handleLogin, 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: const Text("Masuk", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}