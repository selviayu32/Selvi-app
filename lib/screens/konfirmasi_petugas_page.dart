import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Inisialisasi client Supabase
final supabase = Supabase.instance.client;

class KonfirmasiPetugasPage extends StatelessWidget {
  const KonfirmasiPetugasPage({super.key});

  // Fungsi untuk menentukan warna UI berdasarkan status transaksi
  Color getStatusColor(String status) {
    if (status.toLowerCase() == "disetujui") return Colors.green; // STATUS BILA DI SETUJUI 
    if (status.toLowerCase() == "ditolak") return Colors.red;
    return Colors.orange; // Untuk status 'menunggu'
  }

  // Fungsi Dialog Konfirmasi: Memastikan petugas tidak salah tekan tombol aksi
  Future<bool> _confirm(BuildContext context, String title, String message, Color btnColor) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // UNTUK MEMBATALKAN PERINTAH PEMINJAMAN 
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: btnColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ya", style: TextStyle(color: Colors.white)), //UNTUK MELANJUTKAN PERINTAH PEMINJAMAN KE HALAMAN SELANJUTNYA 
          ),
        ],
      ),
    );
    return ok == true;
  }

  // Fungsi Update Status: Mengubah status di DB dan mengirim notifikasi ke user
  Future<void> _updateStatus( //UNTUK MENGUPDATE STATUS PEMINJAMAN DARI PETUGAS KE DATABASE 
    BuildContext context, {
    required String idPermintaan,
    required String statusBaru,
    required String userIdPeminjam,
    required String merkAlat,
  }) async {
    final bool ok = await _confirm(// MENAMPILKAN DI ALOG KONFIRMASI SETELAH PETUGAS KLIK TOMBOL SETUJUI ATAU TOLAK
      context,
      statusBaru == 'disetujui' ? "Setujui Permintaan?" : "Tolak Permintaan?",
      "Yakin ingin ${statusBaru == 'disetujui' ? 'MENYETUJUI' : 'MENOLAK'} peminjaman:\n\n• $merkAlat",
      statusBaru == 'disetujui' ? Colors.green : Colors.red,
    );

    if (!ok) return;

    try {
      // Step 1: Update status pada tabel permintaan peminjaman
      await supabase // UNTUK MENGUPDATE DATA DI TABEL PERMINTAAN BERDASRKAN ID PERMINTAAN 
          .from('permintaan')
          .update({'status': statusBaru})
          .eq('id_permintaan', idPermintaan);

      // Step 2: Masukkan pesan ke tabel notifikasi agar bisa dibaca oleh Peminjam
      await supabase.from('notifications').insert({
        'user_id': userIdPeminjam, //UNTUK MENGIRIM NOTIFIKASI KE PEMINJAM BERDASARKAN USER ID  YANG TADI MEMEINJAM 
        'title': 'Status Peminjaman',
        'message': statusBaru == 'disetujui'
            ? 'Permintaan peminjaman $merkAlat telah DISETUJUI petugas.'
            : 'Permintaan peminjaman $merkAlat telah DITOLAK petugas.',
        'is_read': false,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Berhasil: ${statusBaru.toUpperCase()}")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal update status: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAECBFA),
      appBar: AppBar(
        title: const Text("Konfirmasi Petugas"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder(
        // StreamBuilder: Aplikasi akan otomatis refresh jika ada data baru di tabel 'permintaan'
        stream: supabase
            .from('permintaan')
            .stream(primaryKey: ['id_permintaan'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          // Validasi error (sangat berguna untuk cek Row Level Security / RLS di Supabase)
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "ERROR STREAM:\n${snapshot.error}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final List data = snapshot.data as List;

          // Cek jika tabel permintaan benar-benar kosong
          if (data.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada permintaan.", //JIKA TIDAK ADA PERMINTAAN YANG AKAN DI KONFIRMASI 
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            );
          }

          // Logika Filter: Hanya menampilkan permintaan yang statusnya 'menunggu'
          final dataMenunggu = data.where((x) { // UNTUK MENAMPILKAN DATA YANG BERSTATUS MEUNGGU SAJA YANG LAIN TIDAK TAMPIL
            final s = (x['status'] ?? '').toString().toLowerCase().trim();
            return s.contains('menunggu');
          }).toList();

          // Cek jika tidak ada permintaan yang berstatus 'menunggu'
          if (dataMenunggu.isEmpty) {
            return const Center(
              child: Text(
                "Tidak ada permintaan yang perlu dikonfirmasi.", //MENGKONFIRMASI JIKA SELESAI DI PROSES JADI TIDAK ADA YANG PERLU DI KONFIRMASI 
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: dataMenunggu.length,
            itemBuilder: (context, i) {
              final item = dataMenunggu[i]; //MENGAMBIL DATA YANG BERTATUS MENUNGGU

              final String idPermintaan = item['id_permintaan'].toString(); //MEMPROSES AGAR MEENGGANTI JADI SETUJU
              final String status = (item['status'] ?? 'menunggu').toString();
              final String userIdPeminjam = item['id_user'].toString();

              // Memformat tanggal dari String DB ke format yang mudah dibaca
              final String tglPinjam = DateFormat('dd MMM yyyy')
                  .format(DateTime.parse(item['tgl_pinjam']).toLocal());

              return FutureBuilder(
                // Mengambil detail Merk dan Gambar dari tabel 'alat' berdasarkan id_alat di tabel permintaan
                future: supabase
                    .from('alat')
                    .select()
                    .eq('id_alat', item['id_alat'])
                    .single(),
                builder: (context, alatSnap) {
                  if (!alatSnap.hasData) return const SizedBox();
                  final alat = alatSnap.data as Map;

                  final String merk = (alat['merk'] ?? "Keyboard").toString();
                  final String imageUrl = (alat['image_url'] ?? '').toString();

                  return Container(
                    key: ValueKey(idPermintaan),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        // Bagian Gambar Alat
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: const Icon(Icons.keyboard, size: 30),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Bagian Informasi (Nama Barang & Tanggal)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                merk,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text("Tanggal: $tglPinjam", style: TextStyle(color: Colors.grey[700])),
                              const SizedBox(height: 6),
                              // Badge Status
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: getStatusColor(status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: getStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Bagian Tombol Aksi Petugas
                        Column(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _updateStatus(
                                context,
                                idPermintaan: idPermintaan,
                                statusBaru: 'disetujui',
                                userIdPeminjam: userIdPeminjam,
                                merkAlat: merk,
                              ),
                              child: const Text("Setujui", style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _updateStatus(
                                context,
                                idPermintaan: idPermintaan,
                                statusBaru: 'ditolak',
                                userIdPeminjam: userIdPeminjam,
                                merkAlat: merk,
                              ),
                              child: const Text("Tolak", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}