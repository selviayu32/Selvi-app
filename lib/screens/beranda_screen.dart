import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'input_alat_screen.dart';
import 'keranjang_page.dart'; // Import halaman keranjang kamu
import '../services/alat_service.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  final alatService = AlatService();
  final supabase = Supabase.instance.client;

  // Fungsi Tambah ke Keranjang
  Future<void> _tambahKeKeranjang(Map<String, dynamic> alat) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('keranjang').insert({
        'id_user': user.id,
        'id_alat': alat['id_alat'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${alat['merk']} berhasil ditambah ke keranjang"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAECBFA), // Sesuaikan warna background Figma
      appBar: AppBar(
        title: const Text("Katalog Keyboard",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5371A5), // Warna biru tua toolbar
        elevation: 0,
        leading: IconButton(
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            icon: const Icon(Icons.logout, color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const KeranjangPage()),
              );
            },
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
          ),
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
                  return const Center(child: Text("Data keyboard tidak ditemukan."));
                }

                final daftarAlat = snapshot.data!;

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: daftarAlat.length,
                  itemBuilder: (context, index) {
                    final alat = daftarAlat[index];
                    bool isTersedia = alat['status'] == 'tersedia';

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(15)),
                              child: alat['image_url'] != null
                                  ? Image.network(
                                      alat['image_url'],
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(
                                          Icons.keyboard,
                                          size: 50),
                                    )
                                  : const Center(child: Icon(Icons.keyboard)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alat['merk'] ?? 'Keyboard',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  alat['status'] ?? 'N/A',
                                  style: TextStyle(
                                      color: isTersedia
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          // --- TOMBOL TAMBAH KE KERANJANG ---
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isTersedia ? const Color(0xFF5371A5) : Colors.grey,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: isTersedia ? () => _tambahKeKeranjang(alat) : null,
                                child: const Icon(Icons.add_shopping_cart, size: 18, color: Colors.white),
                              ),
                            ),
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
      // Tombol Tambah Alat hanya untuk Admin/Petugas (Opsional)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InputAlatScreen()),
          ).then((_) => setState(() {}));
        },
        backgroundColor: const Color(0xFF5371A5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}