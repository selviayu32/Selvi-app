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

  /// item: {permintaan: {...}, pengembalian: {...} | null}
  List<Map<String, dynamic>> items = [];

  static const Color primaryBlue = Color(0xFF5371A5);
  static const Color backgroundBlue = Color(0xFFAECBFA);
  static const List<String> _targetStatuses = [
    'menunggu',
    'disetujui',
    'ditolak',
    'pengembalian_diajukan',
    'dikembalikan',
  ];

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  String _fmtDate(dynamic iso) {
    if (iso == null) return '-';
    final s = iso.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  num _toNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<List<Map<String, dynamic>>> _fetchPermintaanByAuthUid(String authUid) async {
    final res = await supabase
        .from('permintaan')
        .select('''
          id_permintaan,
          id_user,
          id_alat,
          tgl_pinjam,
          tgl_kembali_rencana,
          status,
          created_at
        ''')
        .eq('id_user', authUid)
        .inFilter('status', _targetStatuses)
        .order('created_at', ascending: false);

    final rows = res as List;
    return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<int, Map<String, dynamic>>> _fetchAlatByIds(List<int> ids) async {
    if (ids.isEmpty) return {};
    try {
      final res = await supabase
          .from('alat')
          .select('id_alat, merk, image_url')
          .inFilter('id_alat', ids);

      final rows = (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final map = <int, Map<String, dynamic>>{};
      for (final row in rows) {
        final raw = row['id_alat'];
        if (raw is! num) continue;
        map[raw.toInt()] = row;
      }
      return map;
    } on PostgrestException catch (e) {
      debugPrint(
        '[RiwayatPengembalianPage] SELECT alat gagal (kemungkinan RLS). code=${e.code}, message=${e.message}',
      );
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPengembalianByPermintaanIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    try {
      final res = await supabase
          .from('pengembalian')
          .select('''
            id_kembali,
            id_pinjam,
            tgl_kembali_asli,
            kondisi_akhir,
            denda_terlambat,
            biaya_kerusakan,
            catatan_petugas,
            created_at
          ''')
          .inFilter('id_pinjam', ids)
          .order('created_at', ascending: false);

      final rows = res as List;
      return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on PostgrestException catch (e) {
      debugPrint(
        '[RiwayatPengembalianPage] SELECT pengembalian gagal (kemungkinan RLS). code=${e.code}, message=${e.message}',
      );
      return [];
    }
  }

  Map<int, Map<String, dynamic>> _latestPengembalianMap(List<Map<String, dynamic>> rows) {
    final map = <int, Map<String, dynamic>>{};

    for (final row in rows) {
      final idPinjamRaw = row['id_pinjam'];
      if (idPinjamRaw is! num) continue;
      final idPinjam = idPinjamRaw.toInt();

      if (!map.containsKey(idPinjam)) {
        map[idPinjam] = row;
        continue;
      }

      final current = map[idPinjam]!;
      final rowTime = DateTime.tryParse(row['tgl_kembali_asli']?.toString() ?? '') ??
          DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final currentTime = DateTime.tryParse(current['tgl_kembali_asli']?.toString() ?? '') ??
          DateTime.tryParse(current['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);

      if (rowTime.isAfter(currentTime)) {
        map[idPinjam] = row;
      }
    }

    return map;
  }

  Future<void> _loadRiwayat() async {
    setState(() {
      loading = true;
      errorMsg = null;
      items = [];
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User belum login');

      final authUid = user.id;
      debugPrint('[RiwayatPengembalianPage] auth.uid=$authUid');
      final permintaanRowsRaw = await _fetchPermintaanByAuthUid(authUid);

      final alatIds = permintaanRowsRaw
          .map((e) => e['id_alat'])
          .whereType<num>()
          .map((e) => e.toInt())
          .toSet()
          .toList();
      final alatById = await _fetchAlatByIds(alatIds);
      final permintaanRows = permintaanRowsRaw.map((perm) {
        final rawIdAlat = perm['id_alat'];
        final idAlat = rawIdAlat is num ? rawIdAlat.toInt() : null;
        return {
          ...perm,
          'alat': idAlat == null ? null : alatById[idAlat],
        };
      }).toList();

      final permintaanIds = permintaanRows
          .map((e) => e['id_permintaan'])
          .whereType<num>()
          .map((e) => e.toInt())
          .toList();

      final pengembalianRows = await _fetchPengembalianByPermintaanIds(permintaanIds);
      final latestPengembalian = _latestPengembalianMap(pengembalianRows);

      final countByIdPinjam = <int, int>{};
      for (final row in pengembalianRows) {
        final idPinjamRaw = row['id_pinjam'];
        if (idPinjamRaw is! num) continue;
        final idPinjam = idPinjamRaw.toInt();
        countByIdPinjam[idPinjam] = (countByIdPinjam[idPinjam] ?? 0) + 1;
      }

      debugPrint('[RiwayatPengembalianPage] sumber query user: permintaan.id_user = auth.uid ($authUid)');
      debugPrint('[RiwayatPengembalianPage] jumlah permintaan: ${permintaanRows.length}');
      for (int i = 0; i < permintaanRows.length && i < 3; i++) {
        debugPrint('[RiwayatPengembalianPage] contoh permintaan[$i]: ${permintaanRows[i]}');
      }
      debugPrint('[RiwayatPengembalianPage] jumlah pengembalian: ${pengembalianRows.length}');
      for (final idPermintaan in permintaanIds) {
        final count = countByIdPinjam[idPermintaan] ?? 0;
        debugPrint(
          '[RiwayatPengembalianPage] id_permintaan=$idPermintaan, hasil select pengembalian=$count',
        );
        if (count == 0) {
          debugPrint(
            '[RiwayatPengembalianPage] WARNING: pengembalian tidak terbaca (kemungkinan RLS atau belum ada data)',
          );
        }
      }
      if (permintaanRows.isNotEmpty) {
        debugPrint('[RiwayatPengembalianPage] contoh permintaan pertama: ${permintaanRows.first}');
      }
      if (pengembalianRows.isNotEmpty) {
        debugPrint('[RiwayatPengembalianPage] contoh pengembalian pertama: ${pengembalianRows.first}');
      }

      final merged = permintaanRows
          .map((perm) {
            final idPermintaanRaw = perm['id_permintaan'];
            final idPermintaan = idPermintaanRaw is num ? idPermintaanRaw.toInt() : null;
            return {
              'permintaan': perm,
              'pengembalian': idPermintaan == null ? null : latestPengembalian[idPermintaan],
            };
          })
          .toList();

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
    final status = (permintaan?['status'] ?? '').toString().toLowerCase();

    if (status == 'menunggu') return 'Menunggu';
    if (status == 'disetujui') return 'Disetujui';
    if (status == 'ditolak') return 'Ditolak';
    if (status == 'pengembalian_diajukan') return 'Pengembalian Diajukan';
    if (status == 'dikembalikan') return 'Dikembalikan';

    return status.isEmpty ? 'Status' : status;
  }

  Color _chipColor(String chip) {
    final s = chip.toLowerCase();
    if (s.contains('ditolak')) return Colors.red;
    if (s.contains('pengembalian diajukan')) return Colors.blueGrey;
    if (s.contains('menunggu')) return Colors.orange;
    if (s.contains('disetujui')) return Colors.green;
    if (s.contains('dikembalikan')) return Colors.blue;
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
    return 'Rp $buf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text('Riwayat Pengembalian', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadRiwayat,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
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
      child: Text('Belum ada riwayat pengembalian.', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Gagal ambil data.\n$errorMsg', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadRiwayat,
              child: const Text('Coba Lagi'),
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
    final dendaTerlambat = _toNum(pengembalian?['denda_terlambat']);
    final biayaKerusakan = _toNum(pengembalian?['biaya_kerusakan']);
    final totalDenda = dendaTerlambat + biayaKerusakan;

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
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.keyboard, size: 36, color: Colors.grey),
                    )
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
                Text(
                  'Pinjam: $tglPinjam - Rencana: $tglRencana',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  pengembalian == null ? 'Belum ada pengembalian' : 'Kembali: $tglKembaliAsli',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  pengembalian == null
                      ? 'Denda terlambat: - | Kerusakan: -'
                      : 'Denda terlambat: ${_rp(dendaTerlambat)} | Kerusakan: ${_rp(biayaKerusakan)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (pengembalian != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Total Denda: ${_rp(totalDenda)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
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
