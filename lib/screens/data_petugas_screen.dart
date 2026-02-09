import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ================= WARNA TEMA =================
const Color primaryBlue = Color(0xFF5371A5);
const Color backgroundBlue = Color(0xFFAECBFA);

// Supabase client
final supabase = Supabase.instance.client;

class DataPetugasScreen extends StatelessWidget {
  const DataPetugasScreen({super.key});

  // ================= 1. EDIT PROFIL =================
  void _showEditSheet(BuildContext context) {
    final nameController = TextEditingController(text: "Selvi");
    final nipController = TextEditingController(text: "1012007");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 25,
          right: 25,
          top: 25,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Perbarui Profil Petugas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue),
            ),
            const SizedBox(height: 20),

            // Input Nama
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Nama Petugas",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 15),

            // Input NIP
            TextField(
              controller: nipController,
              decoration: InputDecoration(
                labelText: "NIP",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 25),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profil berhasil diperbarui!")),
                  );
                },
                child: const Text("Simpan Perubahan", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ================= 2. HUBUNGI PETUGAS =================
  void _showHubungiDialog(BuildContext context) {
    final pesanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text(
          "Kirim Pesan ke Petugas",
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue),
        ),
        content: TextField(
          controller: pesanController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Tulis pesan instruksi...",
            filled: true,
            fillColor: backgroundBlue.withOpacity(0.1), // FIX ERROR
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              if (pesanController.text.isNotEmpty) {
                try {
                  await supabase.from('pesan').insert({
                    'isi_pesan': pesanController.text,
                    'penerima_id': 'ID_USER_PETUGAS', // nanti ganti auth id
                    'is_read': false,
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Pesan terkirim ke Petugas!")),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error kirim pesan: $e")),
                  );
                }
              }
            },
            child: const Text("Kirim Pesan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ================= UI UTAMA =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Detail Petugas",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainProfileCard(
              nama: "Selvi",
              role: "Petugas Sarpras IT",
              status: "Aktif",
            ),
            const SizedBox(height: 25),

            const Text(
              "Informasi Kontak & Lokasi",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBlue),
            ),
            const SizedBox(height: 12),

            _buildDetailInformationCard(
              nip: "1012007",
              email: "selvi2@gmail.com",
              phone: "+62 856 47588200",
              lokasi: "Lantai 4 Kampus Brantas",
            ),

            const SizedBox(height: 30),
            const Text(
              "Aksi Admin",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBlue),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showEditSheet(context),
                    child: _buildActionButton(Icons.edit_note_rounded, "Edit Profil", Colors.white, primaryBlue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _showHubungiDialog(context),
                    child: _buildActionButton(Icons.chat_rounded, "Hubungi", Colors.green, Colors.white),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ================= CARD PROFIL =================
  Widget _buildMainProfileCard({required String nama, required String role, required String status}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: backgroundBlue,
                child: Icon(Icons.person, size: 60, color: primaryBlue),
              ),
              Container(
                height: 25,
                width: 25,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              )
            ],
          ),
          const SizedBox(height: 15),
          Text(
            nama,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryBlue),
          ),
          const SizedBox(height: 5),
          Text(
            role,
            style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              status,
              style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          )
        ],
      ),
    );
  }

  // ================= DETAIL INFO =================
  Widget _buildDetailInformationCard({
    required String nip,
    required String email,
    required String phone,
    required String lokasi,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(Icons.badge_rounded, "NIP", nip),
          const Divider(height: 25, thickness: 0.5),
          _buildInfoTile(Icons.alternate_email_rounded, "Email", email),
          const Divider(height: 25, thickness: 0.5),
          _buildInfoTile(Icons.phone_iphone_rounded, "Nomor Telepon", phone),
          const Divider(height: 25, thickness: 0.5),
          _buildInfoTile(Icons.location_on_rounded, "Lokasi Kerja", lokasi),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: backgroundBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: primaryBlue),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // ================= TOMBOL AKSI =================
  Widget _buildActionButton(IconData icon, String label, Color bgColor, Color textColor) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: bgColor == Colors.white ? Border.all(color: primaryBlue.withOpacity(0.3)) : null,
        boxShadow: bgColor != Colors.white
            ? [
                BoxShadow(
                  color: bgColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
