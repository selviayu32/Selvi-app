import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Pastikan kamu sudah membuat file ini
import 'add_keyboard_screen.dart'; 

class KeyboardScreen extends StatefulWidget {
  const KeyboardScreen({super.key});

  @override
  State<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<KeyboardScreen> {
  final supabase = Supabase.instance.client;
  
  // State untuk filter dan pencarian
  String selectedCategory = 'GMN'; 
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAECBFA), // Biru Muda Figma
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Data Keyboard Admin", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1. SEARCH BAR (Fungsi pencarian aktif)
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Cari Produk....",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30), 
                  borderSide: BorderSide.none
                ),
              ),
            ),
          ),

          // 2. TOMBOL KATEGORI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterTab("Gaming", "GMN"),
                _buildFilterTab("Wireless", "WLS"),
                _buildFilterTab("Kantor", "KTR"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. LIST DATA DARI SUPABASE
          Expanded(
            child: StreamBuilder(
              stream: supabase.from('alat').stream(primaryKey: ['id_alat']),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // Filter berdasarkan kategori DAN ketikan pencarian
                final filteredData = snapshot.data!.where((item) {
                  final matchesCategory = item['kode_aset'].toString().startsWith(selectedCategory);
                  final matchesSearch = item['merk'].toString().toLowerCase().contains(searchQuery);
                  return matchesCategory && matchesSearch;
                }).toList();

                if (filteredData.isEmpty) {
                  return const Center(child: Text("Produk tidak ditemukan"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    final item = filteredData[index];
                    return _buildProductCard(
                      item['merk'], 
                      item['status'], 
                      item['image_url']
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // 4. FLOATING ACTION BUTTON (Membuka halaman tambah)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddKeyboardScreen()),
          );
        },
        backgroundColor: const Color(0xFF5371A5), // Biru Tua Figma
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  // Widget Tab Kategori
  Widget _buildFilterTab(String label, String categoryCode) {
    bool isSelected = selectedCategory == categoryCode;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = categoryCode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5371A5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Widget Card Produk
  Widget _buildProductCard(String name, String status, String imageUrl) {
    bool isAvailable = status.toLowerCase() == 'tersedia';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 100,
              height: 70,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 50),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green : Colors.yellow[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}