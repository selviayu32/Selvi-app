import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PermintaanPage extends StatefulWidget {
  const PermintaanPage({super.key});

  @override
  State<PermintaanPage> createState() => _PermintaanPageState();
}

class _PermintaanPageState extends State<PermintaanPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAECBFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Konfirmasi Petugas", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Menggunakan Stream agar daftar permintaan update otomatis (Realtime)
        stream: supabase
            .from('permintaan')
            .stream(primaryKey: ['id_permintaan'])
            .order('id_permintaan', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Tidak ada permintaan masuk", style: TextStyle(color: Colors.white)));
          }

          final listPermintaan = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: listPermintaan.length,
            itemBuilder: (context, index) {
              final item = listPermintaan[index];

              // Load detail Alat dan User menggunakan FutureBuilder (Join Manual)
              return FutureBuilder(
                future: supabase
                    .from('permintaan')
                    .select('*, alat(*), users(nama_lengkap)')
                    .eq('id_permintaan', item['id_permintaan'])
                    .single(),
                builder: (context, AsyncSnapshot<Map<String, dynamic>> joinSnap) {
                  if (!joinSnap.hasData) return const SizedBox();

                  final data = joinSnap.data!;
                  final alat = data['alat'];
                  final user = data['users'];
                  
                  // Format Tanggal agar enak dibaca
                  String tglPinjam = DateFormat('d MMM yyyy').format(DateTime.parse(data['tgl_pinjam']));
                  String tglKembali = DateFormat('d MMM yyyy').format(DateTime.parse(data['tgl_kembali_rencana']));

                  Color statusColor = data['status'] == 'disetujui' 
                      ? Colors.green 
                      : (data['status'] == 'ditolak' ? Colors.red : Colors.orange);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(alat['image_url'], width: 50, height: 50, fit: BoxFit.cover),
                            ),
                            title: Text(alat['merk'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Peminjam: ${user['nama_lengkap']}"),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Text(data['status'].toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _infoTanggal("Pinjam", tglPinjam),
                              _infoTanggal("Kembali", tglKembali),
                            ],
                          ),
                          const SizedBox(height: 10),
                          
                          // Tombol Aksi Petugas (Hanya muncul jika status masih 'menunggu')
                          if (data['status'] == 'menunggu')
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _prosesKeputusan(data['id_permintaan'], 'ditolak', data['id_alat']),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                    child: const Text("Tolak"),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _prosesKeputusan(data['id_permintaan'], 'disetujui', data['id_alat']),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text("Setujui", style: TextStyle(color: Colors.white)),
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

  Widget _infoTanggal(String label, String tgl) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(tgl, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  // FUNGSI TERSEMBUNYI: UPDATE STATUS PERMINTAAN & UPDATE STATUS ALAT
  Future<void> _prosesKeputusan(int idPermintaan, String status, int idAlat) async {
    try {
      // 1. Update status di tabel permintaan
      await supabase.from('permintaan').update({'status': status}).eq('id_permintaan', idPermintaan);

      // 2. Jika disetujui, update status alat di tabel 'alat' menjadi 'dipinjam'
      if (status == 'disetujui') {
        await supabase.from('alat').update({'status': 'dipinjam'}).eq('id_alat', idAlat);
        
        // 3. Masukkan ke tabel 'peminjaman' (Transaksi Resmi)
        final reqData = await supabase.from('permintaan').select().eq('id_permintaan', idPermintaan).single();
        await supabase.from('peminjaman').insert({
          'id_user': reqData['id_user'],
          'id_alat': reqData['id_alat'],
          'tgl_pinjam': reqData['tgl_pinjam'],
          'tgl_kembali_rencana': reqData['tgl_kembali_rencana'],
          'kondisi_awal': 'Baik',
          'status_pinjam': 'dipinjam'
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Permintaan telah $status")));
      }
    } catch (e) {
      print("Error: $e");
    }
  }
}