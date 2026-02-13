import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class KonfirmasiPetugasPage extends StatelessWidget {
  const KonfirmasiPetugasPage({super.key});

  static const String _statusUtama = 'menunggu';
  static const List<String> _statusKandidat = ['menunggu', 'diajukan', 'pending'];

  Color getStatusColor(String status) {
    if (status.toLowerCase() == "disetujui") return Colors.green;
    if (status.toLowerCase() == "ditolak") return Colors.red;
    return Colors.orange;
  }

  Future<bool> _confirm(BuildContext context, String title, String message, Color btnColor) async {
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

  Future<void> _updateStatus(
    BuildContext context, {
    required String idPermintaan,
    required String statusBaru,
    required String userIdPeminjam,
    required String merkAlat,
  }) async {
    final bool ok = await _confirm(
      context,
      statusBaru == 'disetujui' ? "Setujui Permintaan?" : "Tolak Permintaan?",
      "Yakin ingin ${statusBaru == 'disetujui' ? 'MENYETUJUI' : 'MENOLAK'} peminjaman:\n\n- $merkAlat",
      statusBaru == 'disetujui' ? Colors.green : Colors.red,
    );

    if (!ok) return;

    try {
      await supabase.from('permintaan').update({'status': statusBaru}).eq('id_permintaan', idPermintaan);

      await supabase.from('notifications').insert({
        'user_id': userIdPeminjam,
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

  bool _looksLikeUuid(String value) {
    final v = value.trim();
    return v.length == 36 && v.contains('-');
  }

  Future<String> _getNamaPeminjam(dynamic idUserRaw) async {
    if (idUserRaw == null) return "Peminjam";
    final raw = idUserRaw.toString().trim();
    if (raw.isEmpty) return "Peminjam";

    try {
      Map<String, dynamic>? userRow;
      if (_looksLikeUuid(raw)) {
        userRow = await supabase.from('users').select('nama_lengkap').eq('auth_id', raw).maybeSingle();
      } else {
        final int? idUserInt = int.tryParse(raw);
        if (idUserInt != null) {
          userRow = await supabase.from('users').select('nama_lengkap').eq('id_user', idUserInt).maybeSingle();
        }
      }

      final nama = userRow?['nama_lengkap']?.toString().trim();
      return (nama != null && nama.isNotEmpty) ? nama : "Peminjam";
    } on PostgrestException catch (e) {
      debugPrint(
        '[KonfirmasiPetugasPage] users blocked by RLS (code=${e.code}, message=${e.message})',
      );
      return "Peminjam";
    } catch (e) {
      debugPrint('[KonfirmasiPetugasPage] users lookup error: $e');
      return "Peminjam";
    }
  }

  Future<Map<String, dynamic>?> _getAlatDetail(Map<String, dynamic> item) async {
    final idPermintaan = item['id_permintaan'];

    if (idPermintaan != null) {
      try {
        final row = await supabase
            .from('permintaan')
            .select('id_permintaan, alat(*)')
            .eq('id_permintaan', idPermintaan)
            .maybeSingle();
        final alat = row?['alat'];
        if (alat is Map<String, dynamic>) return alat;
        if (alat is Map) return Map<String, dynamic>.from(alat);
      } catch (_) {
        // Fallback ke query tabel alat langsung jika relasi join tidak tersedia.
      }
    }

    final idAlat = item['id_alat'];
    if (idAlat == null) return null;

    try {
      return await supabase
          .from('alat')
          .select('id_alat, merk, image_url')
          .eq('id_alat', idAlat)
          .maybeSingle();
    } catch (e) {
      debugPrint('[KonfirmasiPetugasPage] alat lookup error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _loadCardDetail(Map<String, dynamic> item) async {
    final results = await Future.wait<dynamic>([
      _getAlatDetail(item),
      _getNamaPeminjam(item['id_user']),
    ]);

    return {
      'alat': results[0] as Map<String, dynamic>?,
      'nama_peminjam': (results[1] as String?) ?? "Peminjam",
    };
  }

  Widget _buildPermintaanCard(
    BuildContext context, {
    required Map<String, dynamic> item,
    required Map<String, dynamic>? alat,
    required String namaPeminjam,
  }) {
    final String idPermintaan = item['id_permintaan'].toString();
    final String status = (item['status'] ?? 'menunggu').toString();
    final String userIdPeminjam = item['id_user'].toString();

    final String tglPinjam = item['tgl_pinjam'] == null
        ? '-'
        : DateFormat('dd MMM yyyy').format(DateTime.parse(item['tgl_pinjam'].toString()).toLocal());

    final String merk = (alat?['merk'] ?? item['id_alat']?.toString() ?? "Keyboard").toString();
    final String imageUrl = (alat?['image_url'] ?? '').toString();

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
                const SizedBox(height: 4),
                Text("Peminjam: ${namaPeminjam.isEmpty ? "Peminjam" : namaPeminjam}"),
                const SizedBox(height: 4),
                Text("Tanggal: $tglPinjam", style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 6),
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('permintaan')
            .stream(primaryKey: ['id_permintaan'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
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

          final rows = snapshot.data!;
          final menungguRows = rows.where((x) {
            final s = (x['status'] ?? '').toString().toLowerCase().trim();
            return s == _statusUtama;
          }).toList();
          final kandidatRows = rows.where((x) {
            final s = (x['status'] ?? '').toString().toLowerCase().trim();
            return _statusKandidat.contains(s);
          }).toList();
          final dataMenunggu = menungguRows.isNotEmpty ? menungguRows : kandidatRows;
          final statusDipakai = menungguRows.isNotEmpty ? [_statusUtama] : _statusKandidat;

          debugPrint('[KonfirmasiPetugasPage] status filter dipakai: $statusDipakai');
          debugPrint('[KonfirmasiPetugasPage] jumlah rows permintaan: ${dataMenunggu.length}');
          if (dataMenunggu.isNotEmpty) {
            debugPrint('[KonfirmasiPetugasPage] contoh row permintaan: ${dataMenunggu.first}');
          }

          if (rows.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada permintaan.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            );
          }

          if (dataMenunggu.isEmpty) {
            return const Center(
              child: Text(
                "Tidak ada permintaan yang perlu dikonfirmasi.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: dataMenunggu.length,
            itemBuilder: (context, i) {
              final item = dataMenunggu[i];

              return FutureBuilder<Map<String, dynamic>>(
                future: _loadCardDetail(item),
                builder: (context, detailSnap) {
                  final detail = detailSnap.data;
                  final alat = detail?['alat'] as Map<String, dynamic>?;
                  final namaPeminjam = (detail?['nama_peminjam'] ?? "Peminjam").toString();

                  return _buildPermintaanCard(
                    context,
                    item: item,
                    alat: alat,
                    namaPeminjam: namaPeminjam,
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
