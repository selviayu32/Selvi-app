import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart'; // Pastikan file ini berisi AdminDashboard, PetugasDashboard, dan PeminjamDashboard

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  /// Fungsi untuk menangani proses login
  void _handleLogin() async {
    // 1. Validasi: Pastikan input tidak kosong
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email dan Kata Sandi tidak boleh kosong!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Proses login melalui AuthService
      final user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        // 3. Ambil data profil (nama dan role) dari Map yang dikembalikan database
        // Gunakan .toString() dan .toLowerCase() agar perbandingan role tidak sensitif huruf besar/kecil
        String role = user['role']?.toString().toLowerCase() ?? 'peminjam';
        String nama = user['nama_lengkap'] ?? "User";

        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Selamat Datang, $nama!"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // 4. LOGIKA NAVIGASI BERDASARKAN ROLE
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else if (role == 'petugas') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PetugasDashboard()),
          );
        } else {
          // Default untuk role 'peminjam' atau 'siswa'
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PeminjamDashboard()),
          );
        }
      } else {
        // Jika AuthService mengembalikan null (Auth gagal atau Profil tidak ditemukan)
        _showErrorSnackBar("Email atau Kata Sandi Salah!");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar("Terjadi kesalahan sistem. Silakan coba lagi.");
    }
  }

  /// Helper untuk menampilkan pesan error
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAECBFA), // Biru latar belakang
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Aplikasi
                Image.asset('assets/logo.png', width: 150),
                const SizedBox(height: 20),
                const Text(
                  "Selamat Datang!!",
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1))],
                  ),
                ),
                const SizedBox(height: 30),
                
                // INPUT FIELD EMAIL
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: "Email",
                    hintText: "nama@contoh.com",
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 15),

                // INPUT FIELD PASSWORD
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleLogin(), // Bisa login lewat tombol enter di keyboard
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: "Kata Sandi",
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // TOMBOL LOGIN
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF607D8B), // Warna Blue Grey
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text(
                          "MASUK", 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}