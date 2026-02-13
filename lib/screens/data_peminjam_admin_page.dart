import 'package:flutter/material.dart';

class DataPeminjamAdminPage extends StatelessWidget {
  const DataPeminjamAdminPage({super.key});

  static const Color primaryBlue = Color(0xFF5371A5);
  static const Color backgroundBlue = Color(0xFFAECBFA);

  List<Map<String, String>> get _dummyPeminjam => const [
        {'nama': 'Rizky Pratama', 'info': 'Peminjam • XI RPL 1', 'status': 'Disetujui'},
        {'nama': 'Nanda Salsabila', 'info': 'Peminjam • XII TKJ 2', 'status': 'Menunggu'},
        {'nama': 'Rama Aditya', 'info': 'Peminjam • X DKV 1', 'status': 'Ditolak'},
        {'nama': 'Tiara Kurnia', 'info': 'Peminjam • XI RPL 2', 'status': 'Disetujui'},
      ];

  Color _badgeBg(String status) {
    final s = status.toLowerCase();
    if (s == 'disetujui') return const Color(0xFFE8F5EE);
    if (s == 'ditolak') return const Color(0xFFFCEBEC);
    return const Color(0xFFFFF3E0);
  }

  Color _badgeFg(String status) {
    final s = status.toLowerCase();
    if (s == 'disetujui') return const Color(0xFF1E7B4B);
    if (s == 'ditolak') return const Color(0xFFB42318);
    return const Color(0xFFB45309);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Data Peminjam',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _dummyPeminjam.length,
        itemBuilder: (context, i) {
          final item = _dummyPeminjam[i];
          final status = item['status']!;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEF9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.sentiment_satisfied_alt_rounded,
                    color: primaryBlue,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['nama']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF1F2A44),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['info']!,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _badgeBg(status),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _badgeFg(status).withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _badgeFg(status),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
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
