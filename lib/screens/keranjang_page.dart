import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KeranjangPage extends StatefulWidget {
  const KeranjangPage({super.key});

  @override
  State<KeranjangPage> createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    // ✅ CEGAH ERROR KALAU BELUM LOGIN
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User belum login")),
      );
    }

    final userId = user.id;

    return Scaffold(
      backgroundColor: const Color(0xFFAECBFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Keranjang", style: TextStyle(color: Colors.white)),
      ),

      // ================= LOAD DATA KERANJANG =================
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('keranjang')
            .stream(primaryKey: ['id_keranjang'])
            .eq('id_user', userId),
        builder: (context, snapshot) {

          // ERROR CHECK
          if (snapshot.hasError) {
            return Center(child: Text("ERROR: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final keranjangData = snapshot.data!;

          if (keranjangData.isEmpty) {
            return const Center(child: Text("Keranjang kosong"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: keranjangData.length,
            itemBuilder: (context, index) {
              final item = keranjangData[index];

              // ================= LOAD DATA ALAT =================
              return FutureBuilder<Map<String, dynamic>>(
                future: supabase
                    .from('alat')
                    .select()
                    .eq('id_alat', item['id_alat'])
                    .single(),
                builder: (context, alatSnapshot) {

                  if (!alatSnapshot.hasData) {
                    return const SizedBox(); // jangan loading lama
                  }

                  final alat = alatSnapshot.data!;

                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          alat['image_url'] ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.image_not_supported),
                        ),
                      ),
                      title: Text(
                        alat['merk'] ?? 'Tidak ada merk',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(alat['kode_aset'] ?? '-'),

                      // DELETE ICON
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await supabase
                              .from('keranjang')
                              .delete()
                              .eq('id_keranjang', item['id_keranjang']);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      // ================= BUTTON AJUKAN =================
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(15),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5371A5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.all(15),
          ),
          onPressed: _ajukanPermintaan,
          child: const Text(
            "AJUKAN PERMINTAAN",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  // ================= AJUKAN PERMINTAAN =================
  Future<void> _ajukanPermintaan() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final userId = user.id;

    final keranjangData = await supabase
        .from('keranjang')
        .select()
        .eq('id_user', userId);

    for (var item in keranjangData) {
      await supabase.from('permintaan').insert({
        'id_user': userId,
        'id_alat': item['id_alat'],
        'status': 'menunggu',
      });
    }

    // Hapus keranjang setelah kirim
    await supabase.from('keranjang').delete().eq('id_user', userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permintaan dikirim ke petugas")),
      );
    }
  }
}
