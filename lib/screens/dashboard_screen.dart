import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'keyboard_screen.dart';
import 'keranjang_page.dart';
import 'permintaan_page.dart';

// Warna Tema Figma
const Color primaryBlue = Color(0xFF5371A5);
const Color backgroundBlue = Color(0xFFAECBFA);

// Dummy Data Global
List<Map<String, dynamic>> keranjang = [];
int jumlahPermintaan = 1;

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
          children: [
            _buildStatCard("Total Keyboard", "12"),
            const SizedBox(height: 25),
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
                    KeyboardScreen(role: "admin"), // ✅ ADMIN ROLE
                  ),
                  _buildMenuCard(context, "Data Petugas", Icons.badge, null),
                  _buildMenuCard(context, "Data Peminjam", Icons.people, null),
                  _buildMenuCard(context, "Riwayat", Icons.history, null),
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildStatCard("Total Keyboard", "12"),
          const SizedBox(height: 20),

          _buildLongMenu(
            context,
            "Permintaan Peminjaman",
            Icons.assignment,
            const PermintaanPage(),
          ),

          _buildLongMenu(context, "Pengembalian Keyboard", Icons.keyboard_return, null),

          _buildLongMenu(
            context,
            "Data Keyboard",
            Icons.keyboard,
            KeyboardScreen(role: "petugas"), // ✅ PETUGAS ROLE
          ),
        ],
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

      // APPBAR PEMINJAM + KERANJANG
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Hallo Rizky",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const KeranjangPage()));
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Logo
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
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
              "Status Peminjaman",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: primaryBlue),
            ),
            const SizedBox(height: 15),

            _buildLongMenu(
              context,
              "Lihat Daftar Keyboard",
              Icons.search,
              KeyboardScreen(role: "peminjam"), // ✅ PEMINJAM ROLE
            ),

            const SizedBox(height: 10),
            _buildStatusCard(
                "Keyboard Lenovo Preferred Pro", "Di Pinjam", "24 April 2025"),
          ],
        ),
      ),
    );
  }
}

// ================= HELPER WIDGETS =================

// APPBAR GLOBAL
AppBar _buildAppBar(BuildContext context, String title, String role, String nama) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    title: Text(title,
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22)),
    actions: [
      // NOTIF PETUGAS
      if (role == "petugas")
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PermintaanPage()));
              },
            ),
            if (jumlahPermintaan > 0)
              Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.red,
                  child: Text(
                    jumlahPermintaan.toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),

      // PROFILE ICON
      Padding(
        padding: const EdgeInsets.only(right: 10),
        child: IconButton(
          icon: const Icon(Icons.account_circle, color: Colors.white, size: 35),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ProfileScreen(role: role, nama: nama)),
            );
          },
        ),
      ),
    ],
  );
}

// CARD TOTAL
Widget _buildStatCard(String title, String value) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: primaryBlue)),
        Text(value,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: primaryBlue)),
      ],
    ),
  );
}

// MENU GRID ADMIN
Widget _buildMenuCard(
    BuildContext context, String title, IconData icon, Widget? targetScreen) {
  return InkWell(
    onTap: () {
      if (targetScreen != null) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => targetScreen));
      }
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: backgroundBlue.withOpacity(0.3),
            radius: 30,
            child: Icon(icon, size: 35, color: primaryBlue),
          ),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: primaryBlue)),
        ],
      ),
    ),
  );
}

// MENU LIST
Widget _buildLongMenu(
    BuildContext context, String title, IconData icon, Widget? targetScreen) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
    ),
    child: ListTile(
      onTap: () {
        if (targetScreen != null) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => targetScreen));
        }
      },
      leading: Icon(icon, color: primaryBlue),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: primaryBlue)),
      trailing: const Icon(Icons.chevron_right, color: primaryBlue),
    ),
  );
}

// STATUS CARD
Widget _buildStatusCard(String item, String status, String date) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: primaryBlue)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(status,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(date,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            )
          ],
        ),
      ],
    ),
  );
}
