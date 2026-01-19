import 'package:flutter/material.dart';
import 'input_alat_screen.dart';
import '../services/alat_service.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  final alatService = AlatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Rental Keyboard",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
              onPressed: () {
                // Tambahkan fungsi logout di sini jika perlu
                Navigator.pop(context);
              },
              icon: const Icon(Icons.logout, color: Colors.white))
        ],
      ),
      body: Column(
        children: [
          // Bar Pencarian
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari keyboard...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: alatService.getAlat(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("Belum ada data alat di database."));
                }

                final daftarAlat = snapshot.data!;

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 kolom menyamping
                    childAspectRatio: 0.7, // Disesuaikan agar muat gambar + teks
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: daftarAlat.length,
                  itemBuilder: (context, index) {
                    final alat = daftarAlat[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- BAGIAN GAMBAR ---
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(15)),
                              child: alat['image_url'] != null &&
                                      alat['image_url'].toString().isNotEmpty
                                  ? Image.network(
                                      alat['image_url'],
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        color: Colors.blue[50],
                                        child: const Icon(Icons.broken_image,
                                            size: 40, color: Colors.grey),
                                      ),
                                    )
                                  : Container(
                                      width: double.infinity,
                                      color: Colors.blue[50],
                                      child: const Icon(Icons.keyboard,
                                          size: 50, color: Colors.blueAccent),
                                    ),
                            ),
                          ),

                          // --- INFORMASI KEYBOARD ---
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alat['merk'] ?? 'Keyboard',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  alat['kode_aset'] ?? '-',
                                  style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.circle,
                                        size: 8,
                                        color: alat['status'] == 'tersedia'
                                            ? Colors.green
                                            : Colors.red),
                                    const SizedBox(width: 4),
                                    Text(
                                      alat['status'] ?? 'N/A',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // --- TOMBOL AKSI ---
                          const Divider(height: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                  onPressed: () {
                                    // Fungsi Edit
                                  },
                                  icon: const Icon(Icons.edit_note,
                                      color: Colors.blue, size: 22)),
                              IconButton(
                                  onPressed: () {
                                    // Fungsi Hapus
                                  },
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 22)),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InputAlatScreen()),
          ).then((_) => setState(() {}));
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}