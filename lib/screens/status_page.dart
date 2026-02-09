import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final supabase = Supabase.instance.client;

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  // ================= TAMBAHAN: flag role (peminjam tidak boleh setujui/tolak) =================
  // Kalau suatu saat kamu bikin halaman status khusus petugas,
  // tinggal ubah jadi true di halaman itu.
  final bool _canApproveReject = false;

  Color getStatusColor(String status) {
    if (status.toString().toLowerCase() == "disetujui") return Colors.green;
    if (status.toString().toLowerCase() == "ditolak") return Colors.red;
    return Colors.orange;
  }

  // ================= TAMBAHAN: list lokal agar UI bisa langsung berubah tanpa refresh =================
  List<dynamic> _items = [];
  bool _initialized = false;

  // ================= TAMBAHAN: konfirmasi umum (untuk setujui/tolak) =================
  Future<bool> _confirmAction(BuildContext context, String title, String message, Color btnColor) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: btnColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ya", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  // ================= TAMBAHAN: update status (setujui / tolak) =================
  Future<void> _updateStatus(
    BuildContext context, {
    required String idPermintaan,
    required String statusBaru,
    required String merkAlat,
  }) async {
    final ok = await _confirmAction(
      context,
      statusBaru == 'disetujui' ? "Setujui Permintaan?" : "Tolak Permintaan?",
      "Yakin ingin ${statusBaru == 'disetujui' ? 'MENYETUJUI' : 'MENOLAK'} peminjaman:\n\n• $merkAlat",
      statusBaru == 'disetujui' ? Colors.green : Colors.red,
    );

    if (!ok) return;

    try {
      // 1) update ke Supabase
      await supabase
          .from('permintaan')
          .update({'status': statusBaru})
          .eq('id_permintaan', idPermintaan);

      // 2) update UI lokal biar langsung berubah tanpa refresh
      if (!mounted) return;
      setState(() {
        final idx = _items.indexWhere((x) => x['id_permintaan'].toString() == idPermintaan);
        if (idx != -1) {
          _items[idx]['status'] = statusBaru;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status diubah menjadi ${statusBaru.toUpperCase()}")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal ubah status: $e")),
      );
    }
  }

  // ================= TAMBAHAN: helper konfirmasi & hapus =================
  Future<void> _confirmAndDelete(
    BuildContext context, {
    required String idPermintaan,
    required String merkAlat,
    required String status,
  }) async {
    // Aturan umum: batal/hapus hanya saat masih menunggu
    if (status.toString().toLowerCase() != 'menunggu') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hanya permintaan MENUNGGU yang bisa dibatalkan.")),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Batalkan Permintaan?"),
        content: Text(
          "Kamu yakin ingin membatalkan permintaan peminjaman:\n\n• $merkAlat\n\nData akan dihapus dari status peminjaman.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Tidak", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ya, Batalkan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      // 1) hapus dari Supabase (database)
      await supabase.from('permintaan').delete().eq('id_permintaan', idPermintaan);

      // 2) hapus langsung dari tampilan (tanpa refresh)
      if (!mounted) return;
      setState(() {
        _items.removeWhere((x) => x['id_permintaan'].toString() == idPermintaan);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permintaan berhasil dibatalkan.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membatalkan: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Status Peminjaman"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: StreamBuilder(
        stream: supabase
            .from('permintaan')
            .stream(primaryKey: ['id_permintaan'])
            .eq('id_user', user!.id)
            .order('created_at', ascending: false),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          // ================= TAMBAHAN: sinkronkan data stream ke list lokal =================
          if (!_initialized) {
            _items = List<dynamic>.from(data);
            _initialized = true;
          } else {
            if (data.length != _items.length) {
              _items = List<dynamic>.from(data);
            }
          }

          if (_items.isEmpty) {
            return const Center(
              child: Text("Belum ada permintaan", style: TextStyle(fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final item = _items[i];
              final status = item['status'];

              return FutureBuilder(
                future: supabase
                    .from('alat')
                    .select()
                    .eq('id_alat', item['id_alat'])
                    .single(),

                builder: (context, alatSnap) {
                  if (!alatSnap.hasData) return const SizedBox();
                  final alat = alatSnap.data!;

                  final String idPermintaan = item['id_permintaan'].toString();
                  final String merkAlat = (alat['merk'] ?? "Keyboard").toString();

                  final bool isMenunggu = status.toString().toLowerCase().trim() == 'menunggu';

                  return Container(
                    key: ValueKey(idPermintaan),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            alat['image_url'] ?? '',
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

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alat['merk'] ?? "Keyboard",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                DateFormat('dd MMM yyyy')
                                    .format(DateTime.parse(item['tgl_pinjam'])),
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),

                        // ================= UPDATE: PEMINJAM TIDAK MENAMPILKAN SETUJU/TOLAK =================
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // kalau role boleh approve/reject barulah tampil tombol
                            if (isMenunggu && _canApproveReject) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () => _updateStatus(
                                      context,
                                      idPermintaan: idPermintaan,
                                      statusBaru: 'disetujui',
                                      merkAlat: merkAlat,
                                    ),
                                    child: const Text("Setujui",
                                        style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () => _updateStatus(
                                      context,
                                      idPermintaan: idPermintaan,
                                      statusBaru: 'ditolak',
                                      merkAlat: merkAlat,
                                    ),
                                    child: const Text("Tolak",
                                        style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // default: tampil status saja
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: getStatusColor(status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status.toString().toUpperCase(),
                                  style: TextStyle(
                                    color: getStatusColor(status.toString()),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 6),

                            InkWell(
                              onTap: () => _confirmAndDelete(
                                context,
                                idPermintaan: idPermintaan,
                                merkAlat: merkAlat,
                                status: status.toString(),
                              ),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: isMenunggu ? Colors.red.shade400 : Colors.grey.shade400,
                                ),
                              ),
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
