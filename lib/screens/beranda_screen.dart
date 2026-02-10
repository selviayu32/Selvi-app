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
  // Inisialisasi service dan supabase biar bisa ambil data dari database
  final alatService = AlatService();
  final supabase = Supabase.instance.client;

  // --- FUNGSI TAMBAH KE KERANJANG ---
  // Penjelasan: Fungsi ini buat masukin barang yang dipilih ke tabel 'keranjang' di Supabase
  Future<void> _tambahKeKeranjang(Map<String, dynamic> alat) async {
    final user = supabase.auth.currentUser; // Cek siapa user yang lagi login
    if (user == null) return;

    try {
      // Masukin ID User dan ID Alat ke tabel keranjang
      await supabase.from('keranjang').insert({
        'id_user': user.id,
        'id_alat': alat['id_alat'],
      });

      if (mounted) {
        // Kasih notifikasi hijau kalau berhasil
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${alat['merk']} berhasil ditambah ke keranjang"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Kasih notifikasi merah kalau gagal (misal: koneksi error)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAECBFA), // Background biru muda sesuai desain
      appBar: AppBar(
        title: const Text("Katalog Keyboard",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5371A5), // Header biru tua
        elevation: 0,
        // Tombol Logout di kiri atas
        leading: IconButton(
            onPressed: () async {
              await supabase.auth.signOut(); // Proses keluar dari akun
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login'); // Tendang balik ke login
              }
            },
            icon: const Icon(Icons.logout, color: Colors.white)),
        actions: [
          // Tombol Keranjang di kanan atas
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
          // --- BAR PENCARIAN ---
          // Penjelasan: Kotak buat user ngetik nama keyboard yang dicari
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

          // --- AREA DAFTAR BARANG (GRID) ---
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              // Ambil data dari tabel 'alat' lewat service
              future: alatService.getAlat(),
              builder: (context, snapshot) {
                // Tampilan pas lagi loading (muter-muter)
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Tampilan kalau ada error database
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                // Tampilan kalau datanya kosong
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Data keyboard tidak ditemukan."));
                }

                final daftarAlat = snapshot.data!;

                // Bikin tampilan kotak-kotak (Grid) 2 kolom
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 kolom kesamping
                    childAspectRatio: 0.75, // Ngatur tinggi kotak barang
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: daftarAlat.length,
                  itemBuilder: (context, index) {
                    final alat = daftarAlat[index];
                    // Cek status, kalau 'tersedia' nanti teksnya jadi hijau
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
                          // Tampilan Gambar Barang dari URL Supabase Storage
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(15)),
                              child: alat['image_url'] != null
                                  ? Image.network(
                                      alat['image_url'],
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      // Kalau gambar gagal dimuat, munculin icon keyboard
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
                                // Tampilan Merk Keyboard
                                Text(
                                  alat['merk'] ?? 'Keyboard',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Tampilan Status (Tersedia / Tidak)
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
                                  // Kalau barang habis (tidak tersedia), tombol jadi abu-abu
                                  backgroundColor: isTersedia ? const Color(0xFF5371A5) : Colors.grey,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                // Klik tombol panggil fungsi tambah ke keranjang
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
      // --- TOMBOL TAMBAH BARANG (Floating) ---
      // Penjelasan: Tombol melayang buat admin kalau mau nambah list keyboard baru
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InputAlatScreen()),
          ).then((_) => setState(() {})); // Refresh data kalau balik dari input barang
        },
        backgroundColor: const Color(0xFF5371A5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}