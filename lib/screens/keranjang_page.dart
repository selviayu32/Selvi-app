import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// TAMBAH IMPORT STATUS PAGE: Menghubungkan ke halaman riwayat status
import 'status_page.dart';

class KeranjangPage extends StatefulWidget {
  const KeranjangPage({super.key});

  @override
  State<KeranjangPage> createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {
  final supabase = Supabase.instance.client;
  
  // Variabel untuk menyimpan tanggal yang dipilih user
  DateTime tglPinjam = DateTime.now();
  DateTime tglKembali = DateTime.now().add(const Duration(days: 2));
  bool isLoading = false;

  // ================= FUNGSI PILIH TANGGAL =================
  // Menampilkan kalender saat user ingin mengubah tanggal pinjam atau kembali.
  Future<void> _selectDate(BuildContext context, bool isPinjam) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPinjam ? tglPinjam : tglKembali,
      firstDate: DateTime.now(), // Tidak bisa pilih tanggal yang sudah lewat
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isPinjam) {
          tglPinjam = picked;
          // Validasi otomatis: tgl kembali tidak boleh sebelum tgl pinjam
          if (tglKembali.isBefore(tglPinjam)) {
            tglKembali = tglPinjam.add(const Duration(days: 1));
          }
        } else {
          tglKembali = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mengecek apakah user sudah login atau belum
    final user = supabase.auth.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Belum login")));

    return Scaffold(
      backgroundColor: const Color(0xFFAECBFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Keranjang Peminjam", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                // ================= DAFTAR ALAT DI KERANJANG =================
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    // Stream: Memantau database secara real-time (jika hapus barang, langsung hilang)
                    stream: supabase
                        .from('keranjang')
                        .stream(primaryKey: ['id_keranjang'])
                        .eq('id_user', user.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final data = snapshot.data ?? [];
                      if (data.isEmpty) {
                        return const Center(
                          child: Text("Keranjang Kosong", 
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final item = data[index];
                          // FutureBuilder: Mengambil detail nama alat berdasarkan ID dari tabel alat
                          return FutureBuilder(
                            future: supabase
                                .from('alat')
                                .select()
                                .eq('id_alat', item['id_alat'])
                                .single(),
                            builder: (context, alatSnap) {
                              if (!alatSnap.hasData) return const SizedBox();
                              final alat = alatSnap.data!;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(10),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      alat['image_url'] ?? '',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(Icons.keyboard, size: 40),
                                    ),
                                  ),
                                  title: Text(alat['merk'] ?? 'Alat', 
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: const Text("Kondisi Awal: Baik", 
                                    style: TextStyle(color: Colors.green, fontSize: 12)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () async {
                                      // Fungsi menghapus item dari keranjang
                                      await supabase
                                          .from('keranjang')
                                          .delete()
                                          .eq('id_keranjang', item['id_keranjang']);
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),

                // ================= BAGIAN PANEL BAWAH (INPUT TANGGAL & TOMBOL) =================
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35), 
                      topRight: Radius.circular(35)
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
                    ]
                  ),
                  child: Column(
                    children: [
                      // Komponen pilih tanggal pinjam
                      _buildDateTile("Tanggal Pinjam", tglPinjam, () => _selectDate(context, true)),
                      const SizedBox(height: 12),
                      // Komponen pilih rencana tanggal kembali
                      _buildDateTile("Rencana Kembali", tglKembali, () => _selectDate(context, false)),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 0,
                          ),
                          onPressed: _ajukanPermintaan,
                          child: const Text("Ajukan Permintaan", 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }

  // Widget kecil untuk menampilkan baris tanggal yang bisa diklik
  Widget _buildDateTile(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: Color(0xFF5371A5), size: 20),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.grey)),
                Text(DateFormat('EEEE, d MMMM yyyy').format(date), 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ================= FUNGSI PROSES PINJAM =================
  // Memindahkan data dari tabel 'keranjang' ke tabel 'permintaan'
  Future<void> _ajukanPermintaan() async {
    final user = supabase.auth.currentUser;
    final keranjangCek = await supabase.from('keranjang').select().eq('id_user', user!.id);

    // Cek jika tombol ditekan saat keranjang kosong
    if (keranjangCek.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Keranjang Anda masih kosong!")));
      return;
    }

    setState(() => isLoading = true);
    try {
      final keranjangData = await supabase.from('keranjang').select().eq('id_user', user.id);

      // Looping: Memasukkan setiap item di keranjang ke tabel permintaan peminjaman
      for (var item in keranjangData) {
        await supabase.from('permintaan').insert({
          'id_user': user.id,
          'id_alat': item['id_alat'],
          'status': 'menunggu', // Status awal adalah menunggu konfirmasi petugas
          'tgl_pinjam': tglPinjam.toIso8601String(),
          'tgl_kembali_rencana': tglKembali.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Hapus semua isi keranjang karena sudah berubah jadi permintaan
      await supabase.from('keranjang').delete().eq('id_user', user.id);

      if (mounted) {
        // Pindah ke halaman sukses dan hapus riwayat halaman sebelumnya (biar tidak bisa back ke keranjang)
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (context) => const SuksesPage()),
          (route) => false
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}

// ================= HALAMAN SUKSES =================
// Tampilan setelah user berhasil mengajukan peminjaman.
class SuksesPage extends StatelessWidget {
  const SuksesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAECBFA),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikon Centang Hijau
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, size: 100, color: Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 30),
            const Text("Pesanan Di Kirim!", 
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 15),
            const Text(
              "Permintaan Peminjamanmu telah di kirim ke petugas. Silahkan menunggu konfirmasi",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 40),
            // Tombol untuk lanjut melihat status/riwayat pinjam
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5371A5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  // Membuka StatusPage (Pastikan StatusPage sudah dibuat)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const StatusPage()),
                  );
                },
                child: const Text("Lihat Status", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}