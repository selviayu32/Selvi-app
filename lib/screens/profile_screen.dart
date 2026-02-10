import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart'; // Import halaman edit profil

class ProfileScreen extends StatelessWidget {
  // ==========================
  // DATA USER DARI DASHBOARD / SESSION
  // ==========================
  final String role; // "admin" | "petugas" | "peminjam"
  final String nama; // nama user yang ditampilkan
  final Map<String, dynamic> fullUserData; // data lengkap user (untuk edit profile)

  const ProfileScreen({
    super.key,
    required this.role,
    required this.nama,
    required this.fullUserData,
  });

  @override
  Widget build(BuildContext context) {
    // ==========================
    // CEK AKSES: HANYA ADMIN BOLEH EDIT
    // ==========================
    final bool isAdmin = role.toLowerCase() == "admin";
    // Kalau role admin -> tombol edit tampil
    // Kalau role petugas/peminjam -> tombol edit disembunyikan

    return Scaffold(
      // Background biru muda sesuai tema aplikasi
      backgroundColor: const Color(0xFFAECBFA),

      appBar: AppBar(
        // AppBar transparan biar nyatu sama background
        backgroundColor: Colors.transparent,
        elevation: 0,

        // Tombol kembali ke halaman sebelumnya
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Center(
        child: Container(
          // Margin biar card tidak nempel pinggir
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(30),

          // Card putih dengan sudut membulat + bayangan
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                // Bayangan tipis agar terlihat mengangkat
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),

          child: Column(
            // mainAxisSize.min -> tinggi card ngikut isi konten
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==========================
              // FOTO PROFIL / LOGO
              // ==========================
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/logo.png'),
              ),

              const SizedBox(height: 20),

              // ==========================
              // NAMA USER
              // ==========================
              Text(
                nama,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              // ==========================
              // ROLE USER (ADMIN/PETUGAS/PEMINJAM)
              // ==========================
              Text(
                role.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  letterSpacing: 1.1,
                ),
              ),

              const SizedBox(height: 40),

              // =========================================================
              // TOMBOL EDIT PROFIL
              // HANYA MUNCUL JIKA ROLE = ADMIN
              // =========================================================
              if (isAdmin)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    // Icon pensil menandakan edit
                    icon: const Icon(Icons.edit, color: Colors.blue),

                    // Tulisan tombol
                    label: const Text(
                      "Edit Profil",
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ),

                    // Style tombol outline (garis pinggir)
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    // Aksi saat tombol ditekan
                    onPressed: () {
                      // Navigasi ke halaman edit profil
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditProfileScreen(userData: fullUserData),
                        ),
                      );
                    },
                  ),
                ),

              // Spasi hanya muncul jika tombol edit tampil
              if (isAdmin) const SizedBox(height: 15),

              // =========================================================
              // TOMBOL LOG OUT
              // MUNCUL UNTUK SEMUA ROLE
              // =========================================================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  // Icon logout
                  icon: const Icon(Icons.logout, color: Colors.white),

                  // Tulisan tombol
                  label: const Text(
                    "Log Out",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Style tombol (warna + sudut)
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF607D8B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  // Aksi logout: balik ke LoginScreen dan hapus riwayat halaman
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false, // false artinya hapus semua halaman sebelumnya
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
