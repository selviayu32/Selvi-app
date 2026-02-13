import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RiwayatPengembalianPetugasPage extends StatefulWidget {
  const RiwayatPengembalianPetugasPage({super.key});

  @override
  State<RiwayatPengembalianPetugasPage> createState() =>
      _RiwayatPengembalianPetugasPageState();
}

class _RiwayatPengembalianPetugasPageState
    extends State<RiwayatPengembalianPetugasPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  static const Color primaryBlue = Color(0xFF5371A5);
  static const Color backgroundBlue = Color(0xFFAECBFA);

  late TabController _tab;
  final TextEditingController _search = TextEditingController();

  bool _loading = true;
  String? _error;
  bool _isDemoMode = false;
  List<Map<String, dynamic>> _details = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tab.dispose();
    _search.dispose();
    super.dispose();
  }

  String _fmtDate(dynamic iso) {
    if (iso == null) return "-";
    final s = iso.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  num _toNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
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

  bool _looksLikeUuid(String value) {
    return value.length == 36 && value.contains('-');
  }

  Map<int, Map<String, dynamic>> _latestPengembalianMap(
    List<Map<String, dynamic>> rows,
  ) {
    final map = <int, Map<String, dynamic>>{};

    for (final row in rows) {
      final raw = row['id_pinjam'];
      if (raw is! num) continue;
      final idPinjam = raw.toInt();

      if (!map.containsKey(idPinjam)) {
        map[idPinjam] = row;
        continue;
      }

      final current = map[idPinjam]!;
      final rowTime = DateTime.tryParse(row['tgl_kembali_asli']?.toString() ?? '') ??
          DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final currentTime =
          DateTime.tryParse(current['tgl_kembali_asli']?.toString() ?? '') ??
              DateTime.tryParse(current['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);

      if (rowTime.isAfter(currentTime)) {
        map[idPinjam] = row;
      }
    }

    return map;
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
        '[RiwayatPengembalianPetugasPage] SELECT alat gagal (kemungkinan RLS). code=${e.code}, message=${e.message}',
      );
      return {};
    }
  }

  List<Map<String, dynamic>> _buildDummyDetails() {
    return [
      {
        'permintaan': {
          'id_permintaan': 901,
          'id_user': 101,
          'id_alat': 11,
          'tgl_pinjam': '2026-02-10',
          'tgl_kembali_rencana': '2026-02-13',
          'status': 'pengembalian_diajukan',
          'alat': {
            'id_alat': 11,
            'merk': 'Keychron K2',
            'image_url': '',
          },
        },
        'user': {
          'nama_lengkap': 'Peminjam Demo 1',
          'id_user': 101,
        },
        'pengembalian': null,
      },
      {
        'permintaan': {
          'id_permintaan': 902,
          'id_user': 102,
          'id_alat': 12,
          'tgl_pinjam': '2026-02-05',
          'tgl_kembali_rencana': '2026-02-09',
          'status': 'dikembalikan',
          'alat': {
            'id_alat': 12,
            'merk': 'Logitech MX Mechanical',
            'image_url': '',
          },
        },
        'user': {
          'nama_lengkap': 'Peminjam Demo 2',
          'id_user': 102,
        },
        'pengembalian': {
          'id_kembali': 5001,
          'id_pinjam': 902,
          'tgl_kembali_asli': '2026-02-09',
          'kondisi_akhir': 'Baik',
          'denda_terlambat': 0,
          'biaya_kerusakan': 0,
          'catatan_petugas': null,
        },
      },
      {
        'permintaan': {
          'id_permintaan': 903,
          'id_user': 103,
          'id_alat': 13,
          'tgl_pinjam': '2026-02-01',
          'tgl_kembali_rencana': '2026-02-06',
          'status': 'selesai',
          'alat': {
            'id_alat': 13,
            'merk': 'Razer BlackWidow V4',
            'image_url': '',
          },
        },
        'user': {
          'nama_lengkap': 'Peminjam Demo 3',
          'id_user': 103,
        },
        'pengembalian': {
          'id_kembali': 5002,
          'id_pinjam': 903,
          'tgl_kembali_asli': '2026-02-07',
          'kondisi_akhir': 'Rusak Ringan',
          'denda_terlambat': 10000,
          'biaya_kerusakan': 25000,
          'catatan_petugas': 'Keycap enter lecet ringan',
        },
      },
    ];
  }

  void _activateDemoMode(String reason) {
    debugPrint('[RiwayatPengembalianPetugasPage] DEMO mode aktif: $reason');
    _details = _buildDummyDetails();
    _isDemoMode = true;
    _loading = false;
    _error = null;
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
      _isDemoMode = false;
    });

    try {
      final permintaanRes = await supabase
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
          .inFilter('status', ['pengembalian_diajukan', 'dikembalikan', 'selesai'])
          .order('id_permintaan', ascending: false);

      final permintaanRowsRaw = (permintaanRes as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

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

      List<Map<String, dynamic>> pengembalianRows = [];
      if (permintaanIds.isNotEmpty) {
        try {
          final pengembalianRes = await supabase
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
              .inFilter('id_pinjam', permintaanIds)
              .order('created_at', ascending: false);

          pengembalianRows = (pengembalianRes as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        } on PostgrestException catch (e) {
          debugPrint(
            '[RiwayatPengembalianPetugasPage] SELECT pengembalian gagal (kemungkinan RLS). code=${e.code}, message=${e.message}',
          );
        }

        final countByIdPinjam = <int, int>{};
        for (final row in pengembalianRows) {
          final raw = row['id_pinjam'];
          if (raw is! num) continue;
          final idPinjam = raw.toInt();
          countByIdPinjam[idPinjam] = (countByIdPinjam[idPinjam] ?? 0) + 1;
        }

        for (final idPermintaan in permintaanIds) {
          final count = countByIdPinjam[idPermintaan] ?? 0;
          debugPrint(
            '[RiwayatPengembalianPetugasPage] id_permintaan=$idPermintaan, jumlah hasil select pengembalian=$count',
          );
          if (count == 0) {
            debugPrint(
              '[RiwayatPengembalianPetugasPage] WARNING: pengembalian tidak terbaca (kemungkinan RLS)',
            );
          }
        }
      }

      final rawUserIds = permintaanRows.map((e) => e['id_user']).where((e) => e != null).toList();
      final uuidIds = <String>{};
      final intIds = <int>{};
      for (final raw in rawUserIds) {
        final s = raw.toString();
        final asInt = int.tryParse(s);
        if (asInt != null) {
          intIds.add(asInt);
        } else if (_looksLikeUuid(s)) {
          uuidIds.add(s);
        }
      }

      final usersByAuth = <String, Map<String, dynamic>>{};
      final usersById = <String, Map<String, dynamic>>{};

      if (uuidIds.isNotEmpty) {
        try {
          final usersByAuthRes = await supabase
              .from('users')
              .select('nama_lengkap, auth_id, id_user')
              .inFilter('auth_id', uuidIds.toList());
          final rows = (usersByAuthRes as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          for (final row in rows) {
            final key = row['auth_id']?.toString();
            if (key != null && key.isNotEmpty) usersByAuth[key] = row;
          }
        } on PostgrestException catch (e) {
          debugPrint(
            '[RiwayatPengembalianPetugasPage] SELECT users by auth_id gagal (kemungkinan RLS). code=${e.code}, message=${e.message}',
          );
        }
      }

      if (intIds.isNotEmpty) {
        try {
          final usersByIdRes = await supabase
              .from('users')
              .select('nama_lengkap, auth_id, id_user')
              .inFilter('id_user', intIds.toList());
          final rows = (usersByIdRes as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          for (final row in rows) {
            final key = row['id_user']?.toString();
            if (key != null && key.isNotEmpty) usersById[key] = row;
          }
        } on PostgrestException catch (e) {
          debugPrint(
            '[RiwayatPengembalianPetugasPage] SELECT users by id_user gagal (kemungkinan RLS). code=${e.code}, message=${e.message}',
          );
        }
      }

      final latestPengembalian = _latestPengembalianMap(pengembalianRows);

      final merged = permintaanRows.map((permintaan) {
        final idPermintaan = (permintaan['id_permintaan'] as num?)?.toInt();
        final rawUser = permintaan['id_user'];
        final userKey = rawUser?.toString() ?? '';

        final userRow = usersByAuth[userKey] ?? usersById[userKey];

        return {
          'permintaan': permintaan,
          'user': userRow,
          'pengembalian': idPermintaan == null ? null : latestPengembalian[idPermintaan],
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        if (merged.isEmpty) {
          _activateDemoMode('merged kosong dari Supabase');
        } else {
          _details = merged;
          _loading = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _activateDemoMode('query error: $e');
      });
    }
  }

  bool _matchSearch(Map<String, dynamic> detail) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;

    final permintaan = (detail['permintaan'] ?? {}) as Map<String, dynamic>;
    final alat = (permintaan['alat'] ?? {}) as Map<String, dynamic>;
    final user = (detail['user'] ?? {}) as Map<String, dynamic>;

    final merk = (alat['merk'] ?? '').toString().toLowerCase();
    final nama = (user['nama_lengkap'] ?? '').toString().toLowerCase();

    return merk.contains(q) || nama.contains(q);
  }

  Color _chipColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('ditolak')) return Colors.red;
    if (s.contains('pengembalian_diajukan')) return Colors.orange;
    if (s.contains('dikembalikan') || s.contains('selesai')) return Colors.green;
    if (s.contains('disetujui')) return Colors.blue;
    return Colors.grey;
  }

  String _chipLabel(String status) {
    final s = status.toLowerCase();
    if (s == 'pengembalian_diajukan') return 'MENUNGGU CEK';
    if (s == 'dikembalikan' || s == 'selesai') return 'SELESAI';
    if (s == 'menunggu') return 'MENUNGGU';
    if (s == 'disetujui') return 'DIPINJAM';
    if (s == 'ditolak') return 'DITOLAK';
    return status.toUpperCase();
  }

  Future<void> _openKonfirmasiSheet({
    required Map<String, dynamic> detail,
  }) async {
    final permintaan = (detail['permintaan'] ?? {}) as Map<String, dynamic>;
    final pengembalian = detail['pengembalian'] as Map<String, dynamic>?;
    final alat = (permintaan['alat'] ?? {}) as Map<String, dynamic>;

    final int idPermintaan = (permintaan['id_permintaan'] as num).toInt();
    final int idAlat = (permintaan['id_alat'] as num).toInt();
    final String merk = (alat['merk'] ?? 'Keyboard').toString();

    final dendaCtrl = TextEditingController(
      text: _toNum(pengembalian?['denda_terlambat']).toInt().toString(),
    );
    final rusakCtrl = TextEditingController(
      text: _toNum(pengembalian?['biaya_kerusakan']).toInt().toString(),
    );
    final catatanCtrl = TextEditingController(
      text: (pengembalian?['catatan_petugas'] ?? '').toString(),
    );

    String kondisi = (pengembalian?['kondisi_akhir'] ?? 'Baik').toString();
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(builder: (context, setLocal) {
          final total = (int.tryParse(dendaCtrl.text) ?? 0) + (int.tryParse(rusakCtrl.text) ?? 0);

          return Padding(
            padding: EdgeInsets.only(
              left: 14,
              right: 14,
              bottom: MediaQuery.of(context).viewInsets.bottom + 14,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Konfirmasi Pengembalian",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF1F2A37),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Permintaan #$idPermintaan • $merk",
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Kondisi (hasil cek)",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _pillChoice(
                          label: "Baik",
                          selected: kondisi == "Baik",
                          onTap: () => setLocal(() => kondisi = "Baik"),
                        ),
                        _pillChoice(
                          label: "Rusak Ringan",
                          selected: kondisi == "Rusak Ringan",
                          onTap: () => setLocal(() => kondisi = "Rusak Ringan"),
                        ),
                        _pillChoice(
                          label: "Rusak Berat",
                          selected: kondisi == "Rusak Berat",
                          onTap: () => setLocal(() => kondisi = "Rusak Berat"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _numField(
                            label: "Denda terlambat",
                            controller: dendaCtrl,
                            onChanged: (_) => setLocal(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _numField(
                            label: "Denda kerusakan",
                            controller: rusakCtrl,
                            onChanged: (_) => setLocal(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Catatan petugas (opsional)",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: catatanCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Contoh: Tombol A macet, body lecet",
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total Denda",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            _rp(total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                setLocal(() => submitting = true);
                                try {
                                  final denda = int.tryParse(dendaCtrl.text) ?? 0;
                                  final rusak = int.tryParse(rusakCtrl.text) ?? 0;
                                  final permintaanExists = await supabase
                                      .from('permintaan')
                                      .select('id_permintaan')
                                      .eq('id_permintaan', idPermintaan)
                                      .maybeSingle();
                                  if (permintaanExists == null) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      const SnackBar(content: Text('Permintaan tidak ditemukan')),
                                    );
                                    return;
                                  }

                                  if (pengembalian == null) {
                                    await supabase.from('pengembalian').insert({
                                      'id_pinjam': idPermintaan,
                                      'tgl_kembali_asli': DateTime.now().toIso8601String(),
                                      'kondisi_akhir': kondisi,
                                      'denda_terlambat': denda,
                                      'biaya_kerusakan': rusak,
                                      'catatan_petugas':
                                          catatanCtrl.text.trim().isEmpty ? null : catatanCtrl.text.trim(),
                                    });
                                  } else {
                                    await supabase.from('pengembalian').update({
                                      'kondisi_akhir': kondisi,
                                      'denda_terlambat': denda,
                                      'biaya_kerusakan': rusak,
                                      'catatan_petugas':
                                          catatanCtrl.text.trim().isEmpty ? null : catatanCtrl.text.trim(),
                                    }).eq('id_pinjam', idPermintaan);
                                  }

                                  await supabase
                                      .from('permintaan')
                                      .update({'status': 'dikembalikan'}).eq('id_permintaan', idPermintaan);
                                  await supabase.from('alat').update({'status': 'tersedia'}).eq('id_alat', idAlat);

                                  if (!mounted) return;
                                  Navigator.pop(this.context);
                                  await _loadData();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text("Konfirmasi berhasil. Total denda: ${_rp(denda + rusak)}"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(content: Text("Gagal konfirmasi: $e")),
                                  );
                                } finally {
                                  setLocal(() => submitting = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Cek & Konfirmasi",
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );

    dendaCtrl.dispose();
    rusakCtrl.dispose();
    catatanCtrl.dispose();
  }

  static Widget _pillChoice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF2FF) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF9DB7E8) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF274C88) : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  static Widget _numField({
    required String label,
    required TextEditingController controller,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: "0",
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cartoonKeyboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final keyW = w * 0.12;
        final keyH = h * 0.12;
        final gapX = w * 0.03;
        final gapY = h * 0.05;

        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEAF2FF), Color(0xFFDDE9FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC9D7F0)),
          ),
          padding: EdgeInsets.all(w * 0.08),
          child: Column(
            children: [
              Container(
                height: h * 0.10,
                decoration: BoxDecoration(
                  color: const Color(0xFFB5C8EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              SizedBox(height: h * 0.08),
              Expanded(
                child: Wrap(
                  spacing: gapX,
                  runSpacing: gapY,
                  children: List.generate(
                    18,
                    (i) => Container(
                      width: keyW,
                      height: keyH,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _filteredByTab(bool menungguCek) {
    final rows = _details.where((detail) {
      final permintaan = (detail['permintaan'] ?? {}) as Map<String, dynamic>;
      final status = (permintaan['status'] ?? '').toString().toLowerCase();
      if (menungguCek) return status == 'pengembalian_diajukan';
      return status == 'dikembalikan' || status == 'selesai';
    }).toList();

    return rows.where(_matchSearch).toList();
  }

  Widget _buildTab({
    required bool menungguCek,
    required bool showAction,
    required String emptyMessage,
  }) {
    final rows = _filteredByTab(menungguCek);
    if (rows.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        itemCount: rows.length,
        itemBuilder: (context, i) => _buildCard(rows[i], showAction: showAction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Riwayat Pengembalian",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isDemoMode)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: const Text(
                "DEMO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (_isDemoMode) const SizedBox(width: 6),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Menunggu Cek"),
            Tab(text: "Riwayat"),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: "Cari peminjam / merk keyboard...",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text("Error: $_error"))
                    : TabBarView(
                        controller: _tab,
                        children: [
                          _buildTab(
                            menungguCek: true,
                            showAction: true,
                            emptyMessage: "Tidak ada pengembalian yang menunggu dicek.",
                          ),
                          _buildTab(
                            menungguCek: false,
                            showAction: false,
                            emptyMessage: "Belum ada riwayat pengembalian yang selesai.",
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> detail, {required bool showAction}) {
    final permintaan = (detail['permintaan'] ?? {}) as Map<String, dynamic>;
    final user = (detail['user'] ?? {}) as Map<String, dynamic>;
    final pengembalian = detail['pengembalian'] as Map<String, dynamic>?;

    final alat = (permintaan['alat'] ?? {}) as Map<String, dynamic>;
    final merk = (alat['merk'] ?? 'Keyboard').toString();
    final nama = (user['nama_lengkap'] ?? 'Peminjam').toString();

    final status = (permintaan['status'] ?? '').toString();
    final chip = _chipLabel(status);
    final chipColor = _chipColor(status);

    final tglPinjam = _fmtDate(permintaan['tgl_pinjam']);
    final tglRencana = _fmtDate(permintaan['tgl_kembali_rencana']);
    final tglKembaliAsli = _fmtDate(pengembalian?['tgl_kembali_asli']);

    final dendaTelat = _toNum(pengembalian?['denda_terlambat']);
    final dendaRusak = _toNum(pengembalian?['biaya_kerusakan']);
    final totalDenda = dendaTelat + dendaRusak;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 62,
                  height: 62,
                  color: const Color(0xFFF3F4F6),
                  child: _cartoonKeyboard(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merk,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: chipColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  chip,
                  style: TextStyle(
                    color: chipColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _rowInfo("Pinjam", tglPinjam),
                const SizedBox(height: 6),
                _rowInfo("Rencana", tglRencana),
                const SizedBox(height: 6),
                _rowInfo("Kembali", pengembalian == null ? "-" : tglKembaliAsli),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Denda", style: TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                      pengembalian == null ? "-" : _rp(totalDenda),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showAction) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _openKonfirmasiSheet(detail: detail),
                icon: const Icon(Icons.verified, size: 18),
                label: const Text(
                  "Cek & Konfirmasi",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rowInfo(String left, String right) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(left, style: const TextStyle(color: Colors.black54)),
        Text(right, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
