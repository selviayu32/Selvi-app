import 'package:flutter/material.dart';
import '../services/alat_service.dart';

class InputAlatScreen extends StatefulWidget {
  const InputAlatScreen({super.key});

  @override
  State<InputAlatScreen> createState() => _InputAlatScreenState();
}

class _InputAlatScreenState extends State<InputAlatScreen> {
  final _namaController = TextEditingController();
  final _merkController = TextEditingController();
  final _stokController = TextEditingController();
  final _alatService = AlatService();

  void _simpanAlat() async {
    await _alatService.tambahAlat(
      _namaController.text, 
      _merkController.text, 
      "Keyboard Mechanical RGB", // Contoh spek
      int.parse(_stokController.text), 
      1, // Contoh id_kategori 1 (Mechanical)
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Alat Berhasil Ditambahkan!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Input Alat Baru")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _namaController, decoration: const InputDecoration(labelText: "Nama Keyboard")),
            TextField(controller: _merkController, decoration: const InputDecoration(labelText: "Merk")),
            TextField(controller: _stokController, decoration: const InputDecoration(labelText: "Jumlah Stok"), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _simpanAlat, child: const Text("Simpan ke Supabase")),
          ],
        ),
      ),
    );
  }
}