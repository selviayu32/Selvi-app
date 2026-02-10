import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PermintaanPage extends StatefulWidget {
  const PermintaanPage({super.key});

  @override
  State<PermintaanPage> createState() => _PermintaanPageState();
}

class _PermintaanPageState extends State<PermintaanPage> {
  // Inisialisasi client Supabase untuk akses database
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          "Konfirmasi Petugas",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Menggunakan Stream agar daftar permintaan update secara real-time tanpa refresh
        stream: supabase
            .from('permintaan')
            .stream(primaryKey: ['id_permintaan'])
            .order('id_permintaan', ascending: false),
        builder: (context, snapshot) {
          // Penanganan jika terjadi error pada koneksi atau query
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          }

          // Loading state saat data sedang diambil pertama kali
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final listPermintaan = snapshot.data!;
          
          // Tampilan jika tabel permintaan di database kosong
          if (listPermintaan.isEmpty) {
            return const Center(
              child: Text("Tidak ada permintaan masuk", style: TextStyle(color: Colors.white)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: listPermintaan.length,
            itemBuilder: (context, index) {
              final item = listPermintaan[index];

              return FutureBuilder(
                // Mengambil detail user (nama) dan alat karena data awal hanya berisi ID (Foreign Key)
                future: _getDetailPermintaan(item['id_permintaan']),
                builder: (context, AsyncSnapshot<Map<String, dynamic>> snap) {
                  if (!snap.hasData) return const SizedBox();

                  final data = snap.data!;
                  final alat = data['alat'] ?? {};
                  final user = data['user'] ?? {'nama_lengkap': 'User'};

                  // Parsing tanggal ke format yang mudah dibaca
                  String tglPinjam = _formatDate(data['tgl_pinjam']);
                  String tglKembali = _formatDate(data['tgl_kembali_rencana']);

                  // Penentuan warna UI berdasarkan status transaksi
                  Color statusColor = data['status'] == 'disetujui'
                      ? Colors.green
                      : (data['status'] == 'ditolak' ? Colors.red : Colors.orange);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: alat['image_url'] != null
                                    ? Image.network(alat['image_url'], fit: BoxFit.cover)
                                    : const Icon(Icons.keyboard),
                              ),
                            ),
                            title: Text(alat['merk'] ?? 'Alat Tidak Diketahui',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Peminjam: ${user['nama_lengkap']}"),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                data['status'].toString().toUpperCase(),
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _infoTanggal("Rencana Pinjam", tglPinjam),
                              _infoTanggal("Rencana Kembali", tglKembali),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Tombol Aksi hanya muncul jika status masih 'menunggu'
                          if (data['status'] == 'menunggu')
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _prosesKeputusan(data['id_permintaan'], 'ditolak', data['id_alat']),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    child: const Text("Tolak"),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _prosesKeputusan(data['id_permintaan'], 'disetujui', data['id_alat']),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text("Setujui"),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
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

  // ================== AMBIL DATA PERMINTAAN + USER ===================
  // Fungsi join manual untuk mendapatkan info lengkap peminjam dan alat
  Future<Map<String, dynamic>> _getDetailPermintaan(int id) async {
    // Ambil data permintaan dan joinkan dengan tabel alat
    final permintaan = await supabase
        .from('permintaan')
        .select('*, alat(*)')
        .eq('id_permintaan', id)
        .single();

    // Ambil nama user dari tabel profil kustom (users) berdasarkan UUID auth
    final user = await supabase
        .from('users')
        .select('nama_lengkap')
        .eq('auth_id', permintaan['id_user']) // UUID MATCH
        .maybeSingle();

    permintaan['user'] = user;
    return permintaan;
  }

  // Helper format tanggal
  String _formatDate(String? dateStr) {
    if (dateStr == null) return "-";
    return DateFormat('d MMM yyyy').format(DateTime.parse(dateStr));
  }

  // Helper UI untuk menampilkan label tanggal
  Widget _infoTanggal(String label, String tgl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(tgl, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF5371A5))),
      ],
    );
  }

  // ================== PROSES LOGIKA SETUJU / TOLAK ===================
  Future<void> _prosesKeputusan(int idPermintaan, String status, int idAlat) async {
    try {
      // 1. Update status di tabel permintaan
      await supabase.from('permintaan').update({'status': status}).eq('id_permintaan', idPermintaan);

      // 2. Jika disetujui, jalankan alur peminjaman alat
      if (status == 'disetujui') {
        // Tandai alat sebagai 'dipinjam' agar tidak bisa dipesan orang lain
        await supabase.from('alat').update({'status': 'dipinjam'}).eq('id_alat', idAlat);

        // Ambil data asli permintaan untuk dipindahkan ke tabel peminjaman
        final reqData = await supabase.from('permintaan').select().eq('id_permintaan', idPermintaan).single();

        // Masukkan data ke tabel peminjaman (History & Aktif)
        await supabase.from('peminjaman').insert({
          'id_user': reqData['id_user'], // UUID Peminjam
          'id_alat': reqData['id_alat'],
          'tgl_pinjam': reqData['tgl_pinjam'],
          'tgl_kembali_rencana': reqData['tgl_kembali_rencana'],
          'kondisi_awal': 'Baik',
          'status_pinjam': 'dipinjam',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Permintaan $status")),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Terjadi kesalahan")));
      }
    }
  }
}