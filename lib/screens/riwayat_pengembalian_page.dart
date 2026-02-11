import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RiwayatPengembalianPage extends StatefulWidget {
  const RiwayatPengembalianPage({super.key});

  @override
  State<RiwayatPengembalianPage> createState() => _RiwayatPengembalianPageState();
}

class _RiwayatPengembalianPageState extends State<RiwayatPengembalianPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  String? errorMsg;

  /// items gabungan: { permintaan: {...}, pengembalian: {...} atau null }
  List<Map<String, dynamic>> items = [];

  static const Color primaryBlue = Color(0xFF5371A5);
  static const Color backgroundBlue = Color(0xFFAECBFA);

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  String _fmtDate(dynamic iso) {
    if (iso == null) return "-";
    final s = iso.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  Future<int?> _tryGetUserIntIdFromAuth() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    // users.auth_id (uuid) -> users.id_user (int)
    final row = await supabase.from('users').select('id_user').eq('auth_id', user.id).maybeSingle();
    if (row == null) return null;
    return (row['id_user'] as num).toInt();
  }

  Future<List<Map<String, dynamic>>> _fetchPermintaanByUserUuid(String authUid) async {
    final res = await supabase.from('permintaan').select('''
      id_permintaan,
      id_user,
      id_alat,
      tgl_pinjam,
      tgl_kembali_rencana,
      status,
      created_at,
      alat:alat!permintaan_id_alat_fkey(
        id_alat,
        merk,
        image_url
      )
    ''').eq('id_user', authUid).order('tgl_pinjam', ascending: false);

    if (res is! List) return [];
    return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchPermintaanByUserInt(int userIntId) async {
    final res = await supabase.from('permintaan').select('''
      id_permintaan,
      id_user,
      id_alat,
      tgl_pinjam,
      tgl_kembali_rencana,
      status,
      created_at,
      alat:alat!permintaan_id_alat_fkey(
        id_alat,
        merk,
        image_url
      )
    ''').eq('id_user', userIntId).order('tgl_pinjam', ascending: false);

    if (res is! List) return [];
    return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchPengembalian() async {
    final res = await supabase.from('pengembalian').select('''
      id_kembali,
      id_pinjam,
      tgl_kembali_asli,
      kondisi_akhir,
      denda_terlambat,
      catatan_petugas
    ''').order('tgl_kembali_asli', ascending: false);

    if (res is! List) return [];
    return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _loadRiwayat() async {
    setState(() {
      loading = true;
      errorMsg = null;
      items = [];
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User belum login");

      final authUid = user.id;

      // 1) coba ambil permintaan pakai UUID dulu (paling umum kalau FK ke auth_id)
      List<Map<String, dynamic>> permintaanList = await _fetchPermintaanByUserUuid(authUid);

      // 2) kalau kosong, fallback ke INT (kalau permintaan.id_user ternyata int)
      if (permintaanList.isEmpty) {
        final userIntId = await _tryGetUserIntIdFromAuth();
        if (userIntId != null) {
          permintaanList = await _fetchPermintaanByUserInt(userIntId);
        }
      }

      // 3) ambil pengembalian (kalau ada)
      final pengembalianList = await _fetchPengembalian();

      // Map pengembalian by id_pinjam (biasanya = id_permintaan)
      final Map<String, Map<String, dynamic>> pengembalianByPinjam = {};
      for (final p in pengembalianList) {
        final key = (p['id_pinjam'] ?? '').toString();
        if (key.isNotEmpty) pengembalianByPinjam[key] = p;
      }

      // Gabungkan permintaan + pengembalian
      final merged = <Map<String, dynamic>>[];
      for (final perm in permintaanList) {
        final idPermintaan = (perm['id_permintaan'] ?? '').toString();
        merged.add({
          'permintaan': perm,
          'pengembalian': pengembalianByPinjam[idPermintaan], // bisa null
        });
      }

      setState(() {
        items = merged;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = e.toString();
      });
    }
  }

  String _chipText(Map<String, dynamic> item) {
    final permintaan = item['permintaan'] as Map<String, dynamic>?;
    final pengembalian = item['pengembalian'] as Map<String, dynamic>?;

    if (pengembalian != null) return 'Di Kembalikan';

    final status = (permintaan?['status'] ?? '').toString().toLowerCase();
    if (status == 'menunggu') return 'Menunggu';
    if (status == 'disetujui') return 'Di Pinjam';
    if (status == 'ditolak') return 'Di Tolak';
    if (status == 'pengembalian_diajukan') return 'Menunggu Dikembalikan';
    if (status == 'dikembalikan' || status == 'selesai') return 'Di Kembalikan';

    return status.isEmpty ? 'Status' : status;
  }

  Color _chipColor(String chip) {
    final s = chip.toLowerCase();
    if (s.contains('tolak')) return Colors.red;
    if (s.contains('menunggu dikembalikan')) return Colors.blueGrey;
    if (s.contains('menunggu')) return Colors.orange;
    if (s.contains('pinjam')) return Colors.green;
    if (s.contains('kembalikan') || s.contains('selesai')) return Colors.blue;
    return Colors.grey;
  }

  String _rp(num value) {
    final s = value.toStringAsFixed(0);
    final chars = s.split('');
    final buf = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      final left = chars.length - i;
      buf.write(chars[i]);
      if (left > 1 && left % 3 == 1) buf.write('.');
    }
    return "Rp $buf";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text("Riwayat Pengembalian", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadRiwayat,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg != null
              ? _buildError()
              : items.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadRiwayat,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, i) => _buildCard(items[i]),
                      ),
                    ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text("Belum ada riwayat pengembalian.", style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Gagal ambil data.\n$errorMsg", textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadRiwayat,
              child: const Text("Coba Lagi"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final permintaan = item['permintaan'] as Map<String, dynamic>?;
    final pengembalian = item['pengembalian'] as Map<String, dynamic>?;

    final alat = permintaan?['alat'] as Map<String, dynamic>?;

    final merk = (alat?['merk'] ?? 'Keyboard').toString();
    final imageUrl = (alat?['image_url'] ?? '').toString();

    final tglPinjam = _fmtDate(permintaan?['tgl_pinjam']);
    final tglRencana = _fmtDate(permintaan?['tgl_kembali_rencana']);

    final tglKembaliAsli = _fmtDate(pengembalian?['tgl_kembali_asli']);
    final denda = (pengembalian?['denda_terlambat'] ?? 0) as num;

    final chip = _chipText(item);
    final chipColor = _chipColor(chip);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 70,
              height: 70,
              color: Colors.grey[200],
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : const Icon(Icons.keyboard, size: 36, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(merk, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Pinjam: $tglPinjam  •  Rencana: $tglRencana",
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  pengembalian == null ? "Belum ada pengembalian" : "Kembali: $tglKembaliAsli",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  pengembalian == null ? "Denda: -" : "Denda: ${_rp(denda)}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: chipColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              chip.toUpperCase(),
              style: TextStyle(color: chipColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
