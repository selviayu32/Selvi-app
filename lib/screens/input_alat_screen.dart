import 'package:flutter/material.dart';
import '../services/alat_service.dart';

class InputAlatScreen extends StatefulWidget {
  const InputAlatScreen({super.key});

  @override
  State<InputAlatScreen> createState() => _InputAlatScreenState();
}

class _InputAlatScreenState extends State<InputAlatScreen> {
  // ================= CONTROLLER =================
  // Controller adalah "penampung" apa yang diketik user di kotak input.
  final _kodeAsetController = TextEditingController();
  final _merkController = TextEditingController();
  final _spekController = TextEditingController();

  // Memanggil layanan (service) alat untuk proses simpan ke database.
  final _alatService = AlatService();

  // GlobalKey digunakan untuk memvalidasi apakah semua input sudah diisi atau belum.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Indikator untuk memberi tahu aplikasi sedang dalam proses mengirim data.
  bool _isSubmitting = false;

  // Nilai awal untuk pilihan kategori (default: Wireless).
  int _idKategori = 1;

  // Fungsi praktis untuk memunculkan pesan singkat (Snackbar) di bawah layar.
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= FUNGSI SIMPAN DATA =================
  Future<void> _simpanAlat() async {
    // 1. Cek validasi: Jika ada kotak yang kosong, berhenti di sini.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // 2. Ubah status menjadi 'menyimpan' (tombol akan jadi abu-abu/loading).
    setState(() => _isSubmitting = true);

    try {
      // 3. Mengirim data ke AlatService untuk diteruskan ke Supabase.
      final String? err = await _alatService.tambahAlat(
        kodeAset: _kodeAsetController.text.trim(),
        merk: _merkController.text.trim(),
        spesifikasi: _spekController.text.trim(),
        idKategori: _idKategori,
      );

      // Pastikan halaman masih ada sebelum menjalankan perintah berikutnya.
      if (!mounted) return;

      // 4. Jika ada pesan error dari database, tampilkan.
      if (err != null) {
        _showSnack("Gagal menambahkan alat: $err");
        return;
      }

      // 5. Berhasil! Tampilkan pesan sukses dan tutup halaman ini.
      _showSnack("Alat berhasil ditambahkan!");
      Navigator.pop(context);
    } catch (e) {
      // Menangkap error tak terduga (misal: internet mati).
      if (!mounted) return;
      _showSnack("Gagal menambahkan alat: $e");
    } finally {
      // 6. Apapun hasilnya, kembalikan status tombol ke normal.
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    // Menghapus controller dari memori saat halaman ditutup agar aplikasi tidak berat.
    _kodeAsetController.dispose();
    _merkController.dispose();
    _spekController.dispose();
    super.dispose();
  }

  // ================= TAMPILAN LAYAR =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Input Alat Baru")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey, // Menghubungkan form dengan kunci validasi di atas.
          child: Column(
            children: [
              // Input Kode Aset
              TextFormField(
                controller: _kodeAsetController,
                decoration: const InputDecoration(labelText: "Kode Aset"),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Kode aset wajib diisi";
                  return null;
                },
              ),
              
              // Input Merk Alat
              TextFormField(
                controller: _merkController,
                decoration: const InputDecoration(labelText: "Merk"),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Merk wajib diisi";
                  return null;
                },
              ),

              // Input Spesifikasi (Bisa banyak baris)
              TextFormField(
                controller: _spekController,
                decoration: const InputDecoration(labelText: "Spesifikasi"),
                maxLines: 3,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Spesifikasi wajib diisi";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pilihan Kategori (Dropdown)
              DropdownButtonFormField<int>(
                value: _idKategori,
                items: const [
                  DropdownMenuItem(value: 1, child: Text("Wireless")),
                  DropdownMenuItem(value: 2, child: Text("Gaming")),
                  DropdownMenuItem(value: 3, child: Text("Kantor")),
                ],
                onChanged: (v) => setState(() => _idKategori = v ?? 1),
                decoration: const InputDecoration(labelText: "Kategori"),
              ),

              const SizedBox(height: 20),

              // Tombol Simpan
              ElevatedButton(
                // Tombol otomatis mati (null) jika sedang proses simpan agar tidak klik dua kali.
                onPressed: _isSubmitting ? null : _simpanAlat,
                child: Text(_isSubmitting ? "Menyimpan..." : "Simpan ke Supabase"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}