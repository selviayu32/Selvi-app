import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Tambahkan intl di pubspec.yaml

class KeranjangPage extends StatefulWidget {
  const KeranjangPage({super.key});

  @override
  State<KeranjangPage> createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {
  final supabase = Supabase.instance.client;
  DateTime tglPinjam = DateTime.now();
  DateTime tglKembali = DateTime.now().add(const Duration(days: 2));
  bool isLoading = false;

  // Fungsi Pemilih Tanggal
  Future<void> _selectDate(BuildContext context, bool isPinjam) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPinjam ? tglPinjam : tglKembali,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isPinjam) {
          tglPinjam = picked;
          if (tglKembali.isBefore(tglPinjam)) {
            tglKembali = tglPinjam.add(const Duration(days: 1));
          }
        } else {
          tglKembali = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Belum login")));

    return Scaffold(
      backgroundColor: const Color(0xFFAECBFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text("Keranjang Peminjam", style: TextStyle(color: Colors.white)),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabase.from('keranjang').stream(primaryKey: ['id_keranjang']).eq('id_user', user.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final data = snapshot.data!;
                      if (data.isEmpty) return const Center(child: Text("Keranjang Kosong"));

                      return ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final item = data[index];
                          return FutureBuilder(
                            future: supabase.from('alat').select().eq('id_alat', item['id_alat']).single(),
                            builder: (context, alatSnap) {
                              if (!alatSnap.hasData) return const SizedBox();
                              final alat = alatSnap.data!;
                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                child: ListTile(
                                  leading: Image.network(alat['image_url'], width: 50, errorBuilder: (c, e, s) => const Icon(Icons.keyboard)),
                                  title: Text(alat['merk'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: const Text("Kondisi Awal: Baik"),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () => supabase.from('keranjang').delete().eq('id_keranjang', item['id_keranjang']),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                
                // BOX PEMILIH TANGGAL (SESUAI FIGMA)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      _buildDateTile("Tanggal Pinjam", tglPinjam, () => _selectDate(context, true)),
                      const SizedBox(height: 10),
                      _buildDateTile("Rencana Kembali", tglKembali, () => _selectDate(context, false)),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: _ajukanPermintaan,
                          child: const Text("Ajukan Permintaan", style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }

  Widget _buildDateTile(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: Color(0xFF5371A5)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(DateFormat('EEEE, d MMMM yyyy').format(date)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ajukanPermintaan() async {
    setState(() => isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      final keranjangData = await supabase.from('keranjang').select().eq('id_user', user!.id);

      for (var item in keranjangData) {
        await supabase.from('permintaan').insert({
          'id_user': user.id,
          'id_alat': item['id_alat'],
          'status': 'menunggu',
          'tgl_pinjam': tglPinjam.toIso8601String(),
          'tgl_kembali_rencana': tglKembali.toIso8601String(),
        });
      }
      await supabase.from('keranjang').delete().eq('id_user', user.id);
      
      // PINDAH KE HALAMAN SUKSES SESUAI FIGMA
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SuksesPage()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }
}

// HALAMAN SUKSES (PESANAN DIKIRIM)
class SuksesPage extends StatelessWidget {
  const SuksesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAECBFA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.check, size: 60, color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text("Pesanan Di Kirim!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "Permintaan Peminjamanmu telah di kirim ke petugas. Silahkan menunggu konfirmasi",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Lihat Status"),
            )
          ],
        ),
      ),
    );
  }
}