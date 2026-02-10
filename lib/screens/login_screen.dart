import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart'; // Pastikan file ini berisi AdminDashboard, PetugasDashboard, dan PeminjamDashboard

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller untuk menangkap input teks dari user
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Memanggil service backend/auth
  final _authService = AuthService();

  // State untuk mengontrol UI (loading dan visibilitas password)
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  /// Fungsi utama untuk menangani proses autentikasi
  void _handleLogin() async {
    // 1. Validasi Input: Mencegah request ke server jika field masih kosong
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email dan Kata Sandi tidak boleh kosong!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mengaktifkan indikator loading
    setState(() => _isLoading = true);

    try {
      // 2. Memanggil fungsi login pada AuthService
      // Menunggu kembalian data berupa Map user dari database
      final user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Cek apakah widget masih ada di layar (cegah error navigasi setelah async)
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        // 3. Ekstraksi Data: Ambil role dan nama dari response database
        // Gunakan toLowerCase agar pengecekan role lebih aman dari typo huruf kapital
        String role = user['role']?.toString().toLowerCase() ?? 'peminjam';
        String nama = user['nama_lengkap'] ?? "User";

        // Feedback visual saat login berhasil
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Selamat Datang, $nama!"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // 4. LOGIKA NAVIGASI ROLE-BASED
        // Mengarahkan user ke halaman dashboard yang sesuai dengan wewenang mereka
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
          // Default untuk 'peminjam' atau jika role tidak terdefinisi spesifik
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PeminjamDashboard()),
          );
        }
      } else {
        // Jika user tidak ditemukan di database atau password salah
        _showErrorSnackBar("Email atau Kata Sandi Salah!");
      }
    } catch (e) {
      // Menangani error tak terduga (masalah jaringan, server down, dll)
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar("Terjadi kesalahan sistem. Silakan coba lagi.");
    }
  }

  /// Fungsi pembantu (helper) untuk menampilkan snackbar error warna merah
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Menghapus controller dari memori saat layar ditutup untuk mencegah memory leak
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAECBFA), // Warna dasar biru aplikasi
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            // SingleChildScrollView agar layout tidak error (overflow) saat keyboard muncul
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Identitas Visual Aplikasi
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
                
                // FIELD INPUT EMAIL
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

                // FIELD INPUT PASSWORD
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible, // Menyembunyikan karakter password
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleLogin(), // Shortcut login dengan tombol 'Done' keyboard
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

                // TOMBOL LOGIN UTAMA
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    // Tombol mati (null) jika sedang dalam proses loading
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF607D8B), // Warna Blue Grey profesional
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