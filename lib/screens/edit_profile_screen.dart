import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// STATEFUL WIDGET DIGUNAKAN KARENA HALAMAN INI AKAN BERUBAH TAMPILANNYA 
// (CONTOH: SAAT MENGETIK DI TEXTFIELD ATAU SAAT LOADING)
class EditProfileScreen extends StatefulWidget {
  // VARIABEL UNTUK MENERIMA DATA USER YANG DIKIRIM DARI HALAMAN SEBELUMNYA
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // MEMANGGIL CLASS AUTHSERVICE UNTUK MENANGANI LOGIKA DATABASE/AUTH
  final AuthService _authService = AuthService();
  
  // TEXT EDITING CONTROLLER: BERFUNGSI SEBAGAI "PENAMPUNG" TEKS YANG DIKETIK USER
  // LATE BERARTI VARIABEL AKAN DIINISIALISASI NANTI DI INITSTATE
  late TextEditingController _namaController; // MENGEDIT NAMA LENGKAP 
  late TextEditingController _nipController; // MENGEDIT NMIP
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _lokasiController;

  // VARIABEL BOOLEAN UNTUK MENANDAI APAKAH PROSES UPDATE SEDANG BERJALAN (LOADING)
  bool _isLoading = false; // JADI DI SIMPAN ATAU TIDAK

  @override
  void initState() {
    super.initState(); 
    // INITSTATE: FUNGSI YANG DIJALANKAN PERTAMA KALI SAAT HALAMAN DIBUKA.
    // DI SINI KITA MENGISI TEKS AWAL CONTROLLER DENGAN DATA DARI DATABASE (widget.userData)
    // AGAR USER TIDAK PERLU MENGETIK ULANG DARI KOSONG.
    _namaController = TextEditingController(text: widget.userData['nama'] ?? ''); //MENGISI NAMA LENGKAP DARI DATA USER YANG DI KIRIM DARI HALAMAN SEBELUMNYA 
    _nipController = TextEditingController(text: widget.userData['nip'] ?? '');
    _emailController = TextEditingController(text: widget.userData['email'] ?? '');
    _phoneController = TextEditingController(text: widget.userData['nomor_telepon'] ?? '');
    _lokasiController = TextEditingController(text: widget.userData['lokasi_kerja'] ?? '');
  }

  // FUNGSI ASYNC: FUNGSI YANG BERJALAN DI BALIK LAYAR UNTUK MENGIRIM DATA KE SUPABASE
  Future<void> _processUpdate() async {
    // MENGUBAH STATUS LOADING MENJADI TRUE (TAMPILKAN LOADING SPIN)
    setState(() => _isLoading = true);
    
    // MENGAMBIL ID USER YANG SEDANG LOGIN DARI AUTH SERVICE
    final authId = _authService.getCurrentUserId(); 
    
    if (authId != null) {
      // MENJALANKAN FUNGSI UPDATEPROFILE DI AUTH_SERVICE DENGAN DATA DARI INPUTAN USER
      final error = await _authService.updateProfile( //MENGIRIM DATA YANG SUDAH DI EDIT KE AUTH SERVICE
        authId: authId,
        nama: _namaController.text,
        nip: _nipController.text,
        email: _emailController.text,
        nomorTelepon: _phoneController.text,
        lokasiKerja: _lokasiController.text,
      );

      // SETELAH PROSES SELESAI, MATIKAN LOADING
      setState(() => _isLoading = false); //MATIKAN LOADING AGAR TOMBOL BISA DI KLIK

      if (error == null) {
        // JIKA TIDAK ADA ERROR, TAMPILKAN SNACKBAR (PESAN DI BAWAH LAYAR) BERHASIL
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil Berhasil Diperbarui!")),//MENAMPILJKAN PESAN AGAR USER TAHU PROFIL BERHASIL DI UPDATE 
        );
        // NAVIGATOR.POP(CONTEXT, TRUE): KEMBALI KE HALAMAN PROFIL DAN MEMBERI TAHU BAHWA DATA BERUBAH
        Navigator.pop(context, true); 
      } else {
        // JIKA ADA ERROR (MISAL KONEKSI), TAMPILKAN PESAN GAGAL
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal update: $error")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // SCAFFOLD: STRUKTUR DASAR HALAMAN (ADA APPBAR DAN BODY)
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profil Petugas"),
        centerTitle: true, // BIAR JUDUL DI TENGAH
      ),
      // LISTVIEW: AGAR HALAMAN BISA DI-SCROLL JIKA KEYBOARD MUNCUL
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // MEMANGGIL FUNGSI _BUILDINPUT UNTUK MEMBUAT FORM INPUT SECARA EFISIEN
          _buildInput("Nama Lengkap", _namaController, Icons.person),
          _buildInput("NIP", _nipController, Icons.badge),
          _buildInput("E-mail", _emailController, Icons.email),
          _buildInput("Nomor Telepon", _phoneController, Icons.phone_android),
          _buildInput("Lokasi Kerja", _lokasiController, Icons.map),
          
          const SizedBox(height: 30),
          
          // TOMBOL SIMPAN
          ElevatedButton(
            // JIKA SEDANG LOADING, TOMBOL DINONAKTIFKAN (NULL) AGAR TIDAK DI-SPAM USER
            onPressed: _isLoading ? null : _processUpdate,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: Colors.blue,
            ),
            // TAMPILAN ISI TOMBOL: JIKA LOADING TAMPILKAN MUTER, JIKA TIDAK TAMPILKAN TEKS
            child: _isLoading 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text("Simpan Perubahan", style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // WIDGET HELPER: FUNGSI UNTUK MEMBUAT TEXTFORMFIELD SUPAYA KODE TIDAK BERULANG-ULANG (REUSABLE)
  Widget _buildInput(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller, // MENGHUBUNGKAN INPUTAN DENGAN CONTROLLER
        decoration: InputDecoration(
          labelText: label, // NAMA LABEL DI ATAS INPUTAN
          prefixIcon: Icon(icon), // ICON DI SEBELAH KIRI INPUTAN
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // MEMBUAT SUDUT INPUTAN MELENGKUNG
          ),
        ),
      ),
    );
  }
}