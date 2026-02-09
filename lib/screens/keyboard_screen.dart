import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_keyboard_screen.dart';

class KeyboardScreen extends StatefulWidget {
  final String role; // admin | petugas | peminjam

  const KeyboardScreen({super.key, required this.role});

  @override
  State<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<KeyboardScreen> {
  final supabase = Supabase.instance.client;

  String selectedCategory = 'GMN';
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    String userRole = widget.role;

    return Scaffold(
      backgroundColor: const Color(0xFFAECBFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Data Keyboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              onChanged: (value) {
                setState(() => searchQuery = value.toLowerCase());
              },
              decoration: InputDecoration(
                hintText: "Cari Produk....",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // FILTER TABS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
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

          // LIST DATA MENGGUNAKAN STREAM
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('alat').stream(primaryKey: ['id_alat']),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // UPDATE: Logika Filter yang lebih aman
                final filteredData = snapshot.data!.where((item) {
                  final String kodeAset = (item['kode_aset'] ?? "").toString().toUpperCase();
                  final String merk = (item['merk'] ?? "").toString().toLowerCase();

                  final matchesCategory = kodeAset.startsWith(selectedCategory.toUpperCase());
                  final matchesSearch = merk.contains(searchQuery);

                  return matchesCategory && matchesSearch;
                }).toList();

                if (filteredData.isEmpty) {
                  return const Center(
                    child: Text("Produk tidak ditemukan", style: TextStyle(color: Colors.white)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    final item = filteredData[index];
                    return _buildProductCard(
                      item['id_alat'],
                      item['merk'] ?? "Tanpa Merk",
                      item['status'] ?? "Tidak Diketahui",
                      item['image_url'] ?? "",
                      userRole,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: userRole == "admin"
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF5371A5),
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddKeyboardScreen()),
                );
              },
            )
          : null,
    );
  }

  Widget _buildFilterTab(String label, String code) {
    bool isSelected = selectedCategory == code;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = code),
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

  Widget _buildProductCard(
      dynamic id, String name, String status, String imageUrl, String userRole) {
    bool isAvailable = status.toLowerCase() == 'tersedia';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 100,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 50),
                  )
                : const Icon(Icons.image, size: 50),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (userRole == "peminjam" && isAvailable)
                      IconButton(
                        icon: const Icon(Icons.shopping_cart, color: Colors.blue, size: 24),
                        onPressed: () => _addToCart(id),
                      ),
                    if (userRole == "petugas")
                      IconButton(
                        icon: const Icon(Icons.notifications_active, color: Colors.orange, size: 24),
                        onPressed: () => _approveRequest(id),
                      ),
                    if (userRole == "admin")
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                        onPressed: () => _deleteKeyboard(id),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= DATABASE FUNCTIONS =================

  Future<void> _addToCart(dynamic idAlat) async {
    try {
      await supabase.from('keranjang').insert({
        'id_alat': idAlat,
        'id_user': supabase.auth.currentUser!.id,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Masuk keranjang")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    }
  }

  Future<void> _approveRequest(dynamic idAlat) async {
    await supabase.from('permintaan').update({'status': 'disetujui'}).eq('id_alat', idAlat);
  }

  Future<void> _deleteKeyboard(dynamic idAlat) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus?"),
        content: const Text("Data ini akan dihapus permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.from('alat').delete().eq('id_alat', idAlat);
    }
  }
}