import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/alat_service.dart';
import 'dashboard_screen.dart';

class AddKeyboardScreen extends StatefulWidget {
  const AddKeyboardScreen({super.key});

  @override
  State<AddKeyboardScreen> createState() => _AddKeyboardScreenState();
}

class _AddKeyboardScreenState extends State<AddKeyboardScreen> {
  // Warna Tema Figma
  final Color primaryBlue = const Color(0xFF5371A5);
  final Color backgroundBlue = const Color(0xFFAECBFA);

  // Controller & State
  final TextEditingController _merkController = TextEditingController();
  final TextEditingController _specController = TextEditingController();
  String _selectedCategory = 'Gaming';

  // Form key untuk validasi
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Variabel untuk menyimpan foto
  Uint8List? _selectedImageBytes;
  XFile? _selectedXFile;
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;

  // mapping kategori ke id_kategori di tabel alat
  int _mapKategoriToId(String kategori) {
    switch (kategori) {
      case 'Wireless':
        return 1;
      case 'Gaming':
        return 2;
      case 'Kantor':
        return 3;
      default:
        return 2;
    }
  }

  // UPDATE: Generate kode_aset otomatis berdasarkan kategori agar lolos filter di list
  String _generateKodeAset() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    String prefix = "";
    
    if (_selectedCategory == 'Gaming') {
      prefix = "GMN";
    } else if (_selectedCategory == 'Wireless') {
      prefix = "WLS";
    } else if (_selectedCategory == 'Kantor') {
      prefix = "KTR";
    } else {
      prefix = "KB";
    }
    
    return "$prefix-$ts";
  }

  // Fungsi untuk mengambil foto dari Galeri
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedXFile = image;
        _selectedImageBytes = bytes;
      });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _onSavePressed() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedImageBytes == null || _selectedXFile == null) {
      _showSnack("Foto produk wajib diisi.");
      return;
    }

    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Simpan produk?"),
        content: const Text("Pastikan data sudah benar sebelum disimpan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Ya"),
          ),
        ],
      ),
    );

    if (yes != true) return;

    setState(() => _isSubmitting = true);

    try {
      final idKategori = _mapKategoriToId(_selectedCategory);
      final kodeAset = _generateKodeAset();

      // Memanggil Service untuk insert ke Supabase
      final String? err = await AlatService().tambahAlatDenganFoto(
        kodeAset: kodeAset,
        merk: _merkController.text.trim(),
        spesifikasi: _specController.text.trim(),
        idKategori: idKategori,
        imageBytes: _selectedImageBytes!,
        fileName: _selectedXFile!.name,
      );

      if (!mounted) return;

      if (err != null) {
        _showSnack("Gagal menambahkan produk: $err");
        return;
      }

      _showSnack("Berhasil menambahkan produk");

      // Kembali ke Dashboard Admin
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack("Gagal menambahkan produk: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _merkController.dispose();
    _specController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Tambah Keyboard Admin",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInputContainer(
                "Merk",
                "Tambahkan Merk",
                _merkController,
                1,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Merk wajib diisi";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildInputContainer(
                "Spesifikasi",
                "Tambahkan Spesifikasi",
                _specController,
                4,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Spesifikasi wajib diisi";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kategori",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _categoryChip("Wireless"),
                        _categoryChip("Gaming"),
                        _categoryChip("Kantor"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(15),
                    image: _selectedImageBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_selectedImageBytes!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImageBytes == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 60, color: Colors.white),
                            SizedBox(height: 10),
                            Text(
                              "Tambahkan Foto",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              if (_selectedXFile != null) ...[
                const SizedBox(height: 8),
                Text("File: ${_selectedXFile!.name}", style: const TextStyle(color: Colors.black87)),
              ],
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text("Batal", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isSubmitting ? null : _onSavePressed,
                      child: Text(
                        _isSubmitting ? "Menyimpan..." : "Simpan",
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputContainer(String title, String hint, TextEditingController controller, int lines, {String? Function(String?)? validator}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          TextFormField(
            controller: controller,
            maxLines: lines,
            validator: validator,
            decoration: InputDecoration(hintText: hint, border: InputBorder.none, errorStyle: const TextStyle(height: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label) {
    bool isSelected = _selectedCategory == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: primaryBlue,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      onSelected: (bool selected) {
        setState(() {
          if (selected) _selectedCategory = label;
        });
      },
    );
  }
}