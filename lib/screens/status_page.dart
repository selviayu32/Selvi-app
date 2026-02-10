import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Inisialisasi instance Supabase untuk melakukan query ke database
final supabase = Supabase.instance.client;

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  // ================= KOMENTAR: Flag Role =================
  // Variabel ini menentukan apakah user memiliki hak akses untuk menyetujui/menolak.
  // Jika false (default), tombol 'Setujui' dan 'Tolak' tidak akan muncul di UI.
  final bool _canApproveReject = false;

  // ================= KOMENTAR: Pewarnaan Status =================
  // Mengonversi string status dari database menjadi warna UI yang relevan.
  Color getStatusColor(String status) {
    if (status.toString().toLowerCase() == "disetujui") return Colors.green;
    if (status.toString().toLowerCase() == "ditolak") return Colors.red;
    return Colors.orange; // Default untuk status 'menunggu'
  }

  // ================= KOMENTAR: State Manajemen Lokal =================
  // _items: Menyimpan data sementara di memori aplikasi agar UI bisa update instan.
  // _initialized: Flag untuk memastikan data stream hanya disinkronkan saat awal atau saat ada perubahan jumlah data.
  List<dynamic> _items = [];
  bool _initialized = false;

  // ================= KOMENTAR: Dialog Konfirmasi =================
  // Fungsi reusable untuk menampilkan popup konfirmasi (Ya/Batal) sebelum mengeksekusi aksi penting.
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

  // ================= KOMENTAR: Logika Update Status =================
  // Digunakan oleh admin/petugas untuk mengubah status permintaan di database.
  Future<void> _updateStatus(
    BuildContext context, {
    required String idPermintaan,
    required String statusBaru,
    required String merkAlat,
  }) async {
    // Menampilkan dialog konfirmasi spesifik berdasarkan aksi (Setuju/Tolak)
    final ok = await _confirmAction(
      context,
      statusBaru == 'disetujui' ? "Setujui Permintaan?" : "Tolak Permintaan?",
      "Yakin ingin ${statusBaru == 'disetujui' ? 'MENYETUJUI' : 'MENOLAK'} peminjaman:\n\n• $merkAlat",
      statusBaru == 'disetujui' ? Colors.green : Colors.red,
    );

    if (!ok) return;

    try {
      // 1) Melakukan update data di tabel 'permintaan' pada database Supabase
      await supabase
          .from('permintaan')
          .update({'status': statusBaru})
          .eq('id_permintaan', idPermintaan);

      // 2) Update UI Lokal: Mencari index item di list memori dan mengubah statusnya secara langsung.
      // Ini membuat user tidak perlu melakukan 'pull to refresh' untuk melihat hasil.
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

  // ================= KOMENTAR: Logika Hapus/Batal =================
  // Menghapus data permintaan dari database, biasanya digunakan oleh peminjam.
  Future<void> _confirmAndDelete(
    BuildContext context, {
    required String idPermintaan,
    required String merkAlat,
    required String status,
  }) async {
    // Validasi: Pembatalan hanya diizinkan jika status database masih 'menunggu'.
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
      // 1) Menghapus baris data dari tabel 'permintaan' di database Supabase.
      await supabase.from('permintaan').delete().eq('id_permintaan', idPermintaan);

      // 2) Update UI Lokal: Menghapus item dari list _items di memori sehingga kartu hilang dari layar.
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
    // Mendapatkan data user yang sedang aktif login
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

      // ================= KOMENTAR: Real-time Listener =================
      // StreamBuilder mendengarkan perubahan pada tabel 'permintaan' secara otomatis.
      body: StreamBuilder(
        stream: supabase
            .from('permintaan')
            .stream(primaryKey: ['id_permintaan'])
            .eq('id_user', user!.id)
            .order('created_at', ascending: false),

        builder: (context, snapshot) {
          // Menampilkan loading spinner selama koneksi awal ke database.
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          // ================= KOMENTAR: Sinkronisasi Stream ke List Lokal =================
          // Logika ini memastikan data dari database (data) masuk ke list memori (_items).
          // Jika jumlah data berubah di database, list lokal akan di-reset.
          if (!_initialized) {
            _items = List<dynamic>.from(data);
            _initialized = true;
          } else {
            if (data.length != _items.length) {
              _items = List<dynamic>.from(data);
            }
          }

          // Jika tidak ada data ditemukan untuk user tersebut.
          if (_items.isEmpty) {
            return const Center(
              child: Text("Belum ada permintaan", style: TextStyle(fontSize: 16)),
            );
          }

          // Menampilkan list kartu peminjaman.
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final item = _items[i];
              final status = item['status'];

              // ================= KOMENTAR: Fetch Detail Alat =================
              // Karena tabel 'permintaan' hanya menyimpan 'id_alat', kita butuh FutureBuilder
              // untuk mengambil nama/merk dan gambar dari tabel 'alat' berdasarkan ID tersebut.
              return FutureBuilder(
                future: supabase
                    .from('alat')
                    .select()
                    .eq('id_alat', item['id_alat'])
                    .single(),

                builder: (context, alatSnap) {
                  // Jika detail alat belum terambil, tampilkan kotak kosong (SizedBox).
                  if (!alatSnap.hasData) return const SizedBox();
                  final alat = alatSnap.data!;

                  final String idPermintaan = item['id_permintaan'].toString();
                  final String merkAlat = (alat['merk'] ?? "Keyboard").toString();

                  // Cek apakah status saat ini adalah 'menunggu' untuk menentukan akses tombol.
                  final bool isMenunggu = status.toString().toLowerCase().trim() == 'menunggu';

                  // Desain Kartu (Container) per item peminjaman.
                  return Container(
                    key: ValueKey(idPermintaan), // Key unik untuk membantu Flutter mengelola list item.
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
                        // Menampilkan Gambar Alat dari URL database.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            alat['image_url'] ?? '',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            // Jika gambar gagal dimuat (URL mati/kosong).
                            errorBuilder: (c, e, s) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: const Icon(Icons.keyboard, size: 30),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Menampilkan informasi teks (Merk dan Tanggal).
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

                        // ================= KOMENTAR: Kontrol Aksi (Admin vs User) =================
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Jika user adalah admin (_canApproveReject = true) & status masih menunggu.
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
                              // Tampilan default untuk peminjam: Label Status (Warna menyesuaikan status).
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

                            // Tombol Sampah untuk fitur pembatalan permintaan.
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
                                  // Ikon berwarna merah hanya jika bisa dihapus (status menunggu).
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