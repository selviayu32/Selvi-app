import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        title: const Text(
          "Permintaan Peminjaman",
          style: TextStyle(color: Colors.white),
        ),
      ),

      // LOAD DATA PERMINTAAN + JOIN ALAT + USER
      body: StreamBuilder(
        stream: supabase
            .from('permintaan')
            .stream(primaryKey: ['id_permintaan'])
            .order('id_permintaan'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Tidak ada permintaan"));
          }

          return FutureBuilder(
            future: supabase
                .from('permintaan')
                .select('*, alat(*), users(nama_lengkap)')
                .order('id_permintaan'),
            builder: (context, joinSnap) {
              if (!joinSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = joinSnap.data as List;

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final item = data[index];
                  final alat = item['alat'];
                  final user = item['users'];

                  // WARNA STATUS
                  Color statusColor = Colors.orange;
                  if (item['status'] == 'disetujui') statusColor = Colors.green;
                  if (item['status'] == 'ditolak') statusColor = Colors.red;

                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          alat['image_url'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.image_not_supported),
                        ),
                      ),

                      // NAMA ALAT
                      title: Text(
                        alat['merk'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      // USER + STATUS
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Peminjam: ${user?['nama_lengkap'] ?? '-'}"),
                          Text(
                            "Status: ${item['status']}",
                            style: TextStyle(color: statusColor),
                          ),
                        ],
                      ),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // SETUJUI
                          IconButton(
                            icon: const Icon(Icons.check_circle,
                                color: Colors.green),
                            onPressed: () => _updateStatus(
                                item['id_permintaan'], 'disetujui'),
                          ),

                          // TOLAK
                          IconButton(
                            icon:
                                const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _updateStatus(
                                item['id_permintaan'], 'ditolak'),
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

  // UPDATE STATUS PERMINTAAN
  Future<void> _updateStatus(int id, String status) async {
    await supabase
        .from('permintaan')
        .update({'status': status})
        .eq('id_permintaan', id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Permintaan $status")),
    );
  }
}
