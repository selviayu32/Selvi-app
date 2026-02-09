import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart';
import 'keyboard_screen.dart';
import 'keranjang_page.dart';
import 'data_petugas_screen.dart';
import 'status_page.dart';
import 'konfirmasi_petugas_page.dart';

// Warna Tema Figma
const Color primaryBlue = Color(0xFF5371A5);
const Color backgroundBlue = Color(0xFFAECBFA);

final supabase = Supabase.instance.client;

// ================= DASHBOARD ADMIN =================
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: _buildAppBar(context, "Hallo Admin", "admin", "Celvinno"),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistik Card Utama
            StreamBuilder(
              stream: supabase.from('alat').stream(primaryKey: ['id_alat']),
              builder: (context, snapshot) {
                final total =
                    snapshot.hasData ? snapshot.data!.length.toString() : "0";
                return _buildStatCard("Total Keyboard", total);
              },
            ),
            const SizedBox(height: 25),
            const Text(
              "Manajemen Data",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildMenuCard(
                    context,
                    "Data Keyboard",
                    Icons.keyboard,
                    KeyboardScreen(role: "admin"),
                  ),
                  _buildMenuCard(
                    context,
                    "Data Petugas",
                    Icons.badge,
                    const DataPetugasScreen(),
                  ),
                  _buildMenuCard(
                    context,
                    "Data Peminjam",
                    Icons.people,
                    null,
                  ),
                  _buildMenuCard(
                    context,
                    "Riwayat",
                    Icons.history,
                    null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= DASHBOARD PETUGAS =================
class PetugasDashboard extends StatelessWidget {
  const PetugasDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: _buildAppBar(context, "Hallo Petugas", "petugas", "Selvi"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ringkasan Data",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: supabase.from('alat').stream(primaryKey: ['id_alat']),
                    builder: (context, snapshot) {
                      final total = snapshot.hasData
                          ? snapshot.data!.length.toString()
                          : "0";
                      return _buildCompactStatCard(
                        "Total Alat",
                        total,
                        Icons.keyboard,
                        Colors.orange,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: StreamBuilder(
                    stream: supabase
                        .from('permintaan')
                        .stream(primaryKey: ['id_permintaan'])
                        .eq('status', 'menunggu'),
                    builder: (context, snapshot) {
                      final pending = snapshot.hasData
                          ? snapshot.data!.length.toString()
                          : "0";
                      return _buildCompactStatCard(
                        "Pending",
                        pending,
                        Icons.pending_actions,
                        Colors.redAccent,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              "Menu Utama",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.1,
              children: [
                _buildModernMenuCard(
                  context,
                  "Permintaan",
                  Icons.assignment_turned_in,
                  "Cek Peminjaman",
                  const KonfirmasiPetugasPage(),
                ),
                _buildModernMenuCard(
                  context,
                  "Pengembalian",
                  Icons.keyboard_return,
                  "Update Status",
                  null,
                ),
                _buildModernMenuCard(
                  context,
                  "Stok Alat",
                  Icons.inventory_2,
                  "Kelola Keyboard",
                  KeyboardScreen(role: "petugas"),
                ),
                _buildModernMenuCard(
                  context,
                  "Laporan",
                  Icons.bar_chart,
                  "Data Bulanan",
                  null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widgets for Petugas
  Widget _buildCompactStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
    Widget? target,
  ) {
    return InkWell(
      onTap: () {
        if (target != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => target),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: backgroundBlue.withValues(alpha: 0.2),
              child: Icon(icon, color: primaryBlue),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "",
              style: TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ================= DASHBOARD PEMINJAM =================
class PeminjamDashboard extends StatelessWidget {
  const PeminjamDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: _buildAppBar(context, "Hallo Rizky", "peminjam", "Rizky"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10)
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.image, size: 50)),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Aksi Cepat",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 15),

            // MENU 1
            _buildLongMenu(
              context,
              "Lihat Daftar Keyboard",
              Icons.search,
              KeyboardScreen(role: "peminjam"),
            ),

            // MENU STATUS
            const SizedBox(height: 12),
            _buildLongMenu(
              context,
              "Lihat Status Peminjaman",
              Icons.assignment,
              const StatusPage(),
            ),

            const SizedBox(height: 25),
            const Text(
              "Status Peminjaman Terkini",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 15),
            _buildStatusRealtime(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRealtime() {
    final user = supabase.auth.currentUser;
    return StreamBuilder(
      stream: supabase
          .from('permintaan')
          .stream(primaryKey: ['id_permintaan'])
          .eq('id_user', user?.id ?? '')
          .order('created_at'),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Belum ada riwayat peminjaman"));
        }

        final data = snapshot.data!.last;

        return _buildStatusCard(
          "Keyboard ID: ${data['id_alat']}",
          data['status'].toString().toUpperCase(),
          "Diajukan: ${data['created_at'].toString().substring(0, 10)}",
        );
      },
    );
  }
}

// ================= HELPER WIDGETS =================

AppBar _buildAppBar(
  BuildContext context,
  String title,
  String role,
  String nama,
) {
  final user = supabase.auth.currentUser;

  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    title: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: 22,
      ),
    ),
    actions: [
      if (role == "peminjam")
        StreamBuilder(
          stream: supabase
              .from('keranjang')
              .stream(primaryKey: ['id_keranjang'])
              .eq('id_user', user?.id ?? ''),
          builder: (context, snapshot) {
            int count = snapshot.hasData ? snapshot.data!.length : 0;
            return _buildBadgeIcon(
              context,
              Icons.shopping_cart,
              count,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KeranjangPage()),
                );
              },
            );
          },
        ),
      if (role == "petugas")
        StreamBuilder(
          stream: supabase
              .from('permintaan')
              .stream(primaryKey: ['id_permintaan'])
              .eq('status', 'menunggu'),
          builder: (context, snapshot) {
            int count = snapshot.hasData ? snapshot.data!.length : 0;
            return _buildBadgeIcon(
              context,
              Icons.notifications,
              count,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const KonfirmasiPetugasPage()),
                );
              },
            );
          },
        ),
      Padding(
        padding: const EdgeInsets.only(right: 10),
        child: IconButton(
          icon: const Icon(Icons.account_circle, color: Colors.white, size: 35),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(role: role, nama: nama),
              ),
            );
          },
        ),
      ),
    ],
  );
}

Widget _buildBadgeIcon(
  BuildContext context,
  IconData icon,
  int count,
  VoidCallback onTap,
) {
  return Stack(
    children: [
      IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
      if (count > 0)
        Positioned(
          right: 8,
          top: 8,
          child: CircleAvatar(
            radius: 8,
            backgroundColor: Colors.red,
            child: Text(
              count.toString(),
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
        ),
    ],
  );
}

Widget _buildStatCard(String title, String value) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
        )
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryBlue,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
      ],
    ),
  );
}

Widget _buildMenuCard(
  BuildContext context,
  String title,
  IconData icon,
  Widget? targetScreen,
) {
  return InkWell(
    onTap: () {
      if (targetScreen != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        );
      }
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: backgroundBlue.withValues(alpha: 0.3),
            radius: 30,
            child: Icon(icon, size: 35, color: primaryBlue),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildLongMenu(
  BuildContext context,
  String title,
  IconData icon,
  Widget? targetScreen,
) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 5,
        )
      ],
    ),
    child: ListTile(
      onTap: () {
        if (targetScreen != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
          );
        }
      },
      leading: Icon(icon, color: primaryBlue),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: primaryBlue,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: primaryBlue),
    ),
  );
}

Widget _buildStatusCard(String item, String status, String date) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: primaryBlue,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              decoration: BoxDecoration(
                color: status == "DISETUJUI"
                    ? Colors.green
                    : Colors.orangeAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            )
          ],
        ),
      ],
    ),
  );
}
