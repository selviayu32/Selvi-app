import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PengembalianPage extends StatefulWidget {
  const PengembalianPage({super.key});

  @override
  State<PengembalianPage> createState() => _PengembalianPageState();
}

class _PengembalianPageState extends State<PengembalianPage> {
  String? kondisiTerpilih;
  final TextEditingController _catatanController = TextEditingController();
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? pinjamAktif;
  bool loading = true;
  bool submitting = false;

  static const Color primaryBlue = Color(0xFF5371A5);
  static const Color backgroundBlue = Color(0xFFAECBFA);

  @override
  void initState() {
    super.initState();
    _loadPinjamAktifDariPermintaan();
  }

  Future<void> _loadPinjamAktifDariPermintaan() async {
    setState(() => loading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          pinjamAktif = null;
          loading = false;
        });
        return;
      }

      // ==============================
      // 1) MAP auth_id (uuid) -> users.id_user (int)
      // ==============================
      final userRow = await supabase
          .from('users')
          .select('id_user')
          .eq('auth_id', user.id)
          .single();

      final int userIntId = userRow['id_user'];

      // ==============================
      // 2) Ambil 1 permintaan terbaru yang statusnya disetujui
      // JOIN alat lewat FK permintaan_id_alat_fkey
      // ==============================
      final res = await supabase
          .from('permintaan')
          .select(
            'id_permintaan, id_alat, tgl_pinjam, tgl_kembali_rencana, status, alat:alat!permintaan_id_alat_fkey(merk, image_url)',
          )
          .eq('id_user', userIntId)
          .eq('status', 'disetujui')
          .order('tgl_pinjam', ascending: false)
          .limit(1);

      setState(() {
        pinjamAktif =
            (res is List && res.isNotEmpty) ? (res.first as Map<String, dynamic>) : null;
        loading = false;
      });
    } catch (e) {
      setState(() {
        pinjamAktif = null;
        loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal ambil data pinjam: $e")),
        );
      }
    }
  }

  String _fmtDate(dynamic iso) {
    if (iso == null) return "-";
    final s = iso.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  int _telatHari(dynamic tglKembaliRencana) {
    if (tglKembaliRencana == null) return 0;
    final due = DateTime.tryParse(tglKembaliRencana.toString());
    if (due == null) return 0;

    final now = DateTime.now();
    final dueDate = DateTime(due.year, due.month, due.day);
    final today = DateTime(now.year, now.month, now.day);

    final diff = today.difference(dueDate).inDays;
    return diff > 0 ? diff : 0;
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

  Future<void> _ajukanPengembalian() async {
    if (pinjamAktif == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada peminjaman aktif untuk dikembalikan.")),
      );
      return;
    }
    if (kondisiTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih kondisi dulu.")),
      );
      return;
    }

    setState(() => submitting = true);

    try {
      // id_permintaan dipakai sebagai id_pinjam (sesuai struktur kamu sekarang)
      final idPermintaan = pinjamAktif!['id_permintaan'];
      final telat = _telatHari(pinjamAktif!['tgl_kembali_rencana']);
      final previewDenda = telat * 10000;

      final inserted = await supabase
          .from('pengembalian')
          .insert({
            'id_pinjam': idPermintaan,
            'tgl_kembali_asli': DateTime.now().toIso8601String(),
            'kondisi_akhir': kondisiTerpilih,
            'denda_terlambat': 0,
            'biaya_kerusakan': 0,
            'catatan_petugas': _catatanController.text.trim().isEmpty
                ? null
                : _catatanController.text.trim(),
          })
          .select()
          .single();

      await supabase
          .from('permintaan')
          .update({'status': 'pengembalian_diajukan'})
          .eq('id_permintaan', idPermintaan);

      final dendaFinal = (inserted['denda_terlambat'] ?? previewDenda) as num;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pengembalian diajukan. Denda: ${_rp(dendaFinal)}")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal ajukan pengembalian: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: AppBar(
        title: const Text("Pengembalian Alat", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoCardReal(),
                  const SizedBox(height: 20),
                  _buildSectionContainer(
                    title: "Kondisi Saat Dikembalikan",
                    child: Column(
                      children: [
                        _buildRadioOption("Baik", Icons.check_circle, Colors.green),
                        _buildRadioOption("Rusak Ringan", Icons.warning, Colors.orange),
                        _buildRadioOption("Rusak Berat", Icons.cancel, Colors.red),
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Catatan Tambahan (opsional)",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _catatanController,
                          decoration: InputDecoration(
                            hintText: "Contoh: Tombol A agak keras",
                            fillColor: Colors.grey[200],
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionContainer(
                    title: "Denda Keterlambatan",
                    child: _buildDendaTelatPreview(),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: submitting ? null : _ajukanPengembalian,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Ajukan Pengembalian",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCardReal() {
    if (pinjamAktif == null) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: const Text("Tidak ada peminjaman aktif untuk dikembalikan."),
      );
    }

    final idAlat = pinjamAktif!['id_alat']?.toString() ?? "-";
    final tglPinjam = _fmtDate(pinjamAktif!['tgl_pinjam']);
    final tglRencana = _fmtDate(pinjamAktif!['tgl_kembali_rencana']);

    final alat = pinjamAktif!['alat'] as Map<String, dynamic>?;
    final merk = alat?['merk']?.toString() ?? "Keyboard";
    final imageUrl = alat?['image_url']?.toString();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey[200],
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : const Icon(Icons.keyboard, size: 40, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merk,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text("ID Alat: $idAlat", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 6),
                Text(
                  "Tgl Pinjam: $tglPinjam",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  "Rencana Kembali: $tglRencana",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDendaTelatPreview() {
    if (pinjamAktif == null) {
      return const Text("Tidak ada peminjaman aktif.");
    }
    final telat = _telatHari(pinjamAktif!['tgl_kembali_rencana']);
    final total = telat * 10000;

    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.access_time, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                telat == 0 ? "Tidak terlambat" : "Telat $telat hari (Rp 10.000 x $telat)",
              ),
            ),
            Text(_rp(total), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Total Denda",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              _rp(total),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionContainer({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF1D3557),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(padding: const EdgeInsets.all(15), child: child),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String label, IconData icon, Color color) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
      value: label,
      groupValue: kondisiTerpilih,
      onChanged: (val) => setState(() => kondisiTerpilih = val),
    );
  }
}
