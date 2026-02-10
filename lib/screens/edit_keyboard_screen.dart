import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditKeyboardScreen extends StatefulWidget {
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
    super.initState();
    merkController = TextEditingController(text: widget.merk);
    spesifikasiController = TextEditingController(text: widget.spesifikasi);

    // Normalisasi status awal
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

    // Validasi status (harus sesuai opsi)
    if (!_statusOptions.contains(selectedStatus)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Status tidak valid")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await supabase.from('alat').update({
        'merk': merk,
        'spesifikasi': spesifikasi,
        'status': selectedStatus, // sudah lowercase & konsisten
      }).eq('id_alat', widget.idAlat);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Produk berhasil diperbarui!"),
          backgroundColor: Colors.green,
        ),
      );

      // INI PENTING: kirim true agar halaman sebelumnya setState() dan update
      Navigator.pop(context, true);
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
  Widget build(BuildContext context) {
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
            // Preview gambar
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
                          widget.imageUrl,
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
              decoration: InputDecoration(
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
                labelText: "Spesifikasi",
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
                labelText: "Status",
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
                onPressed: isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5371A5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3),
                      )
                    : const Text(
                        "Simpan Perubahan",
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
    merkController.dispose();
    spesifikasiController.dispose();
    super.dispose();
  }
}
