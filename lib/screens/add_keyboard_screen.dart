import 'dart:io'; // Penting untuk menangani file gambar
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import library yang baru ditambahkan

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
  
  // Variabel untuk menyimpan foto yang dipilih
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Fungsi untuk mengambil foto dari Galeri
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path); // Update tampilan dengan foto baru
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("tambah Keyboard Admin", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. INPUT MERK
            _buildInputContainer("Merk", "Tambahkan Merk", _merkController, 1),
            const SizedBox(height: 20),

            // 2. INPUT SPESIFIKASI
            _buildInputContainer("Spesifikasi", "Tambahkan Spesifikasi", _specController, 4),
            const SizedBox(height: 20),

            // 3. PILIH KATEGORI
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
                  const Text("Kategori", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

            // 4. TAMBAHKAN FOTO (UPDATE: Sudah Bisa Diklik)
            GestureDetector(
              onTap: _pickImage, // Menjalankan fungsi ambil gambar
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(15),
                  // Menampilkan gambar jika file sudah dipilih
                  image: _selectedImage != null 
                    ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) 
                    : null,
                ),
                child: _selectedImage == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 60, color: Colors.white),
                        SizedBox(height: 10),
                        Text("Tambahkan Foto", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : null, // Sembunyikan icon jika sudah ada foto
              ),
            ),
            const SizedBox(height: 40),

            // 5. TOMBOL BATAL & SIMPAN
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: () {
                      // Logika Simpan ke database akan ditaruh di sini
                    },
                    child: const Text("Simpan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget untuk Box Input
  Widget _buildInputContainer(String title, String hint, TextEditingController controller, int lines) {
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
          TextField(
            controller: controller,
            maxLines: lines,
            decoration: InputDecoration(hintText: hint, border: InputBorder.none),
          ),
        ],
      ),
    );
  }

  // Widget untuk pilihan kategori
  Widget _categoryChip(String label) {
    bool isSelected = _selectedCategory == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: primaryBlue,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      onSelected: (bool selected) {
        setState(() { if (selected) _selectedCategory = label; });
      },
    );
  }
}