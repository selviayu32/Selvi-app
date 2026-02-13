import 'package:flutter/material.dart';

import '../services/laporan_pdf_service.dart';

class AdminRiwayatPage extends StatelessWidget {
  const AdminRiwayatPage({super.key});

  static const Color primaryBlue = Color(0xFF5371A5);
  static const Color backgroundBlue = Color(0xFFAECBFA);

  List<Map<String, dynamic>> get _dummyLaporan => const [
        {
          'judul': 'Laporan Bulanan Januari 2026',
          'periode': '01 Jan 2026 - 31 Jan 2026',
          'totalPeminjaman': 42,
          'totalPengembalian': 38,
          'totalDenda': 85000,
        },
        {
          'judul': 'Laporan Bulanan Februari 2026',
          'periode': '01 Feb 2026 - 28 Feb 2026',
          'totalPeminjaman': 35,
          'totalPengembalian': 33,
          'totalDenda': 45000,
        },
        {
          'judul': 'Laporan Bulanan Maret 2026',
          'periode': '01 Mar 2026 - 31 Mar 2026',
          'totalPeminjaman': 51,
          'totalPengembalian': 49,
          'totalDenda': 120000,
        },
      ];

  String _rp(int value) {
    final s = value.toString();
    final chars = s.split('');
    final buf = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      final left = chars.length - i;
      buf.write(chars[i]);
      if (left > 1 && left % 3 == 1) buf.write('.');
    }
    return 'Rp $buf';
  }

  Future<void> _printLaporan(Map<String, dynamic> laporan) async {
    await LaporanPdfService.printLaporan(
      judul: laporan['judul'] as String,
      periode: laporan['periode'] as String,
      totalPeminjaman: laporan['totalPeminjaman'] as int,
      totalPengembalian: laporan['totalPengembalian'] as int,
      totalDenda: laporan['totalDenda'] as int,
      rows: const [
        {'nama': 'Rizky', 'status': 'Dikembalikan', 'denda': 'Rp 10.000'},
        {'nama': 'Nanda', 'status': 'Selesai', 'denda': 'Rp 0'},
        {'nama': 'Rama', 'status': 'Dikembalikan', 'denda': 'Rp 25.000'},
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Arsip Laporan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => _printLaporan(_dummyLaporan.first),
            icon: const Icon(Icons.print, color: Colors.white),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _dummyLaporan.length,
        itemBuilder: (context, i) {
          final item = _dummyLaporan[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['judul'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF1F2A44),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFF7AC89A)),
                      ),
                      child: const Text(
                        'TERSIMPAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E7B4B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item['periode'] as String,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Peminjaman: ${item['totalPeminjaman']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Pengembalian: ${item['totalPengembalian']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Denda: ${_rp(item['totalDenda'] as int)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () => _printLaporan(item),
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text(
                      'Print Laporan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
