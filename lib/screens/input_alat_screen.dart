import 'package:flutter/material.dart';
import '../services/alat_service.dart';

class InputAlatScreen extends StatefulWidget {
  const InputAlatScreen({super.key});

  @override
  State<InputAlatScreen> createState() => _InputAlatScreenState();
}

class _InputAlatScreenState extends State<InputAlatScreen> {
  final _kodeAsetController = TextEditingController();
  final _merkController = TextEditingController();
  final _spekController = TextEditingController();

  final _alatService = AlatService();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // contoh mapping kategori (silakan sesuaikan)
  int _idKategori = 1;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _simpanAlat() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      final String? err = await _alatService.tambahAlat(
        kodeAset: _kodeAsetController.text.trim(),
        merk: _merkController.text.trim(),
        spesifikasi: _spekController.text.trim(),
        idKategori: _idKategori,
      );

      if (!mounted) return;

      if (err != null) {
        _showSnack("Gagal menambahkan alat: $err");
        return;
      }

      _showSnack("Alat berhasil ditambahkan!");
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack("Gagal menambahkan alat: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _kodeAsetController.dispose();
    _merkController.dispose();
    _spekController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Input Alat Baru")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _kodeAsetController,
                decoration: const InputDecoration(labelText: "Kode Aset"),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Kode aset wajib diisi";
                  return null;
                },
              ),
              TextFormField(
                controller: _merkController,
                decoration: const InputDecoration(labelText: "Merk"),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Merk wajib diisi";
                  return null;
                },
              ),
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

              // kategori (opsional) — kalau kamu punya tabel kategori, nanti kita sambung stream
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
              ElevatedButton(
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
