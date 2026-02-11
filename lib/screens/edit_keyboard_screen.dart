import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditKeyboardScreen extends StatefulWidget { //MENGIRIM DATA DARI HALAMAN SEBELUMNYA
  final dynamic idAlat;
  final String merk;
  final String status;
  final String spesifikasi;
  final String imageUrl;

  const EditKeyboardScreen({
    super.key,
    required this.idAlat,
    required this.merk,
    required this.status,
    required this.spesifikasi,
    required this.imageUrl,
  });

  @override
  State<EditKeyboardScreen> createState() => _EditKeyboardScreenState();
}

class _EditKeyboardScreenState extends State<EditKeyboardScreen> {
  final supabase = Supabase.instance.client;

  late TextEditingController merkController;
  late TextEditingController spesifikasiController;

  bool isLoading = false;

  // Pakai dropdown biar status selalu valid & konsisten
  final List<String> _statusOptions = const [
    'tersedia',
    'dipinjam',
    'rusak',
    'perbaikan',
  ];

  late String selectedStatus;

  @override
  void initState() {
    super.initState();//INISIALISASI DATA DARI HALAMAN SEBELUMNYA 
    merkController = TextEditingController(text: widget.merk);
    spesifikasiController = TextEditingController(text: widget.spesifikasi);

    // UNTUK SET NILAI STATUS AWAL DI DROPDOWN MISAL SEBELUMNYA TERSEDIA DI PILIH JADI  TERSEDIA
    final initial = widget.status.trim().toLowerCase();
    selectedStatus = _statusOptions.contains(initial) ? initial : 'tersedia';
  }

  Future<void> _saveChanges() async {
    final merk = merkController.text.trim();
    final spesifikasi = spesifikasiController.text.trim();

    if (merk.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Merk tidak boleh kosong")),
      );
      return;
    }

    // Validasi status (harus sesuai opsi) //HARUS SESUAI OPSI YANG ADA MAKA BARU BISA DI SIMPAN 
    if (!_statusOptions.contains(selectedStatus)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Status tidak valid")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await supabase.from('alat').update({ //UPDATE KEYBOARD DI SUPABASE SESUAI DENGAN YANG DI EDIT 
        'merk': merk,
        'spesifikasi': spesifikasi,
        'status': selectedStatus, // sudah lowercase & konsisten
      }).eq('id_alat', widget.idAlat); //MEMBANTU MENGUPDATE DATA BERDASARKAN ID YANG DI KIRIMKAN 

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Produk berhasil diperbarui!"),
          backgroundColor: Colors.green,
        ),
      );

      // INI PENTING: kirim true agar halaman sebelumnya setState() dan update
      Navigator.pop(context, true); //MEMBERITAHJU HALAMAN SELANJUTNYA JIKA TERJADI PERUBAHN JADI AUTOREFRESH DAN TIDAK PERLU RELOAD MANUAL 
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menyimpan: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) { //MENGGAMBAR HALAMAN EDIT KEYBOARD JADI BISA MENGEDIT DAN MENYIMPAN PERUBAHAN 
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Edit Produk"),
        backgroundColor: const Color(0xFF5371A5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview gambar KEYBOARD  ATAU LOGO JADI BISA MELIHAT GAMBAR YANG SUDAH DI UPLOAD SEBELUMNYA 
            Center(
              child: Container(
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16), 
                  child: widget.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.imageUrl, //MENAMPILKAN GAMBAR DARI URL YANG DI KIRIMKAN PER HALAMAN SEBELUMNYA 
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.image_not_supported,
                                size: 60, color: Colors.grey),
                          ),
                        )
                      : const Icon(Icons.keyboard,
                          size: 80, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 32),

            TextField(
              controller: merkController,
              decoration: InputDecoration( //UNTUK MENGEDIT MERK KEYBOARD 
                labelText: "Merk",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: spesifikasiController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: "Spesifikasi", //UNTUK MENGEDIT SPESIFIKASI KEYBOARD 
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // DROPDOWN STATUS (lebih aman daripada ketik manual)
            InputDecorator(
              decoration: InputDecoration(
                labelText: "Status", //UNTUK MENGEDT STATUS KEYBOARD TERSEDIA 
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedStatus,
                  isExpanded: true,
                  items: _statusOptions
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ),
                      )
                      .toList(),
                  onChanged: isLoading
                      ? null
                      : (val) {
                          if (val == null) return;
                          setState(() => selectedStatus = val);
                        },
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveChanges, //MENYIMPAN PERUBAHAN YANG SUDAH DI EDIT 
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5371A5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading //MENUNGGU PROSES SIMPAN JADI TIDAK BISA DI KLIK LAGI
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3),
                      )
                    : const Text(
                        "Simpan Perubahan", //TOMBOL SIMPAN PERUBAHAN
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    merkController.dispose(); //MEMBUANG DATA YANG TIDAK DI PAKAI LAGI
    spesifikasiController.dispose();
    super.dispose();
  }
}
