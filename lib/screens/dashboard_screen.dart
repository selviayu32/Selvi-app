import 'package:flutter/material.dart';
// IMPORT UI FLUTTER: SCAFFOLD, APPBAR, TEXT, COLUMN, DLL

import 'package:supabase_flutter/supabase_flutter.dart';
// IMPORT SUPABASE FLUTTER: AUTH + DATABASE REALTIME (STREAM)

import 'profile_screen.dart';
// IMPORT HALAMAN PROFILE (DIPAKAI SAAT KLIK ICON PROFILE)

// ✅ FIX: GANTI IMPORT INI BIAR KeyboardScreen KEBACA PASTI
import 'package:flutter_application_1/screens/keyboard_screen.dart';
// SEBELUMNYA: import 'keyboard_screen.dart';

import 'keranjang_page.dart';
// IMPORT HALAMAN KERANJANG (UNTUK ROLE PEMINJAM)

import 'data_petugas_screen.dart';
// IMPORT HALAMAN DATA PETUGAS (UNTUK ADMIN)

import 'status_page.dart';
// IMPORT HALAMAN STATUS PEMINJAMAN (UNTUK PEMINJAM)

import 'konfirmasi_petugas_page.dart';
// IMPORT HALAMAN KONFIRMASI PETUGAS (NOTIF PERMINTAAN MENUNGGU)

// ✅ TAMBAHAN: HALAMAN PENGEMBALIAN PEMINJAM
import 'pengembalian_page.dart';

// =====================================================
// KONFIGURASI WARNA UTAMA APLIKASI (BIAR KONSISTEN)
// =====================================================
const Color primaryBlue = Color(0xFF5371A5);
// WARNA UTAMA (BIRU TUA)

const Color backgroundBlue = Color(0xFFAECBFA);
// WARNA BACKGROUND (BIRU MUDA)

// =====================================================
// INISIALISASI CLIENT SUPABASE (UNTUK QUERY/STREAM)
// =====================================================
final supabase = Supabase.instance.client;
// CLIENT INI DIPAKAI DI SEMUA QUERY: from('tabel')..., auth..., DLL

// =====================================================
// 1) DASHBOARD ADMIN
// =====================================================
// STATELESS KARENA DATA REALTIME DIHANDLE STREAMBUILDER (AUTO UPDATE)
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // KERANGKA HALAMAN (APPBAR + BODY)
      backgroundColor: backgroundBlue,

      // APPBAR: PAKAI HELPER AGAR KONSISTEN DI SEMUA ROLE
      appBar: _buildAppBar(context, "Hallo Admin", "admin", "Celvinno"),

      body: Padding(
        // PADDING LUAR BIAR KONTEN GA NEMPEL TEPI
        padding: const EdgeInsets.all(20),
        child: Column(
          // SUSUN KONTEN DARI ATAS KE BAWAH
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // KARTU STATISTIK: TOTAL KEYBOARD
            // =========================
            StreamBuilder(
              // STREAM REALTIME: AMBIL DATA DARI TABEL 'alat'
              stream: supabase.from('alat').stream(primaryKey: ['id_alat']), //ARRAY ID ALAT DAN STRAMBUILDER//
              builder: (context, snapshot) {
                // HITUNG JUMLAH DATA SAAT ADA, KALAU BELUM ADA -> 0
                final total =
                    snapshot.hasData ? snapshot.data!.length.toString() : "0";

                // TAMPILKAN DALAM CARD
                return _buildStatCard("Total Keyboard", total);
              },
            ),

            const SizedBox(height: 25),

            // JUDUL SECTION
            const Text(
              "Manajemen Data",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 15),

            // =========================
            // GRID MENU ADMIN
            // =========================
            Expanded(
              // EXPANDED BIAR GRID NGISI SISA RUANG LAYAR
              child: GridView.count(
                crossAxisCount: 2, // 2 KOLOM
                crossAxisSpacing: 15, // JARAK ANTAR KOLOM
                mainAxisSpacing: 15, // JARAK ANTAR BARIS
                children: [
                  _buildMenuCard(
                    context,
                    "Data Keyboard",
                    Icons.keyboard,
                    const KeyboardScreen(role: "admin"),
                    // NAVIGASI KE KEYBOARDSCREEN DENGAN ROLE ADMIN
                  ),
                  _buildMenuCard(
                    context,
                    "Data Petugas",
                    Icons.badge,
                    const DataPetugasScreen(),
                    // NAVIGASI KE DATAPETUGASSCREEN
                  ),
                  _buildMenuCard(
                    context,
                    "Data Peminjam",
                    Icons.people,
                    null,
                    // NULL = BELUM ADA HALAMAN, JADI TIDAK BISA DIKLIK
                  ),
                  _buildMenuCard(
                    context,
                    "Riwayat",
                    Icons.history,
                    null,
                    // NULL = BELUM ADA HALAMAN
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

// =====================================================
// 2) DASHBOARD PETUGAS
// =====================================================
class PetugasDashboard extends StatelessWidget {
  const PetugasDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: _buildAppBar(context, "Hallo Petugas", "petugas", "Selvi"),

      // SCROLLVIEW: BIAR HALAMAN BISA DISCROLL KALO KONTEN PANJANG
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // JUDUL SECTION
            const Text(
              "Ringkasan Data",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 15),

            // =========================
            // ROW 2 KARTU STATISTIK (TOTAL ALAT & PENDING)
            // =========================
            Row(
              children: [
                // KARTU KIRI: TOTAL ALAT
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

                // KARTU KANAN: PERMINTAAN MENUNGGU
                Expanded(
                  child: StreamBuilder(
                    stream: supabase
                        .from('permintaan')
                        .stream(primaryKey: ['id_permintaan'])
                        .eq('status', 'menunggu'),
                    // FILTER: HANYA STATUS = 'menunggu'
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

            // JUDUL SECTION
            const Text(
              "Menu Utama",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 15),

            // =========================
            // GRID MENU PETUGAS
            // shrinkWrap + NeverScrollableScrollPhysics:
            // GRID NGIKUTIN TINGGI KONTEN, SCROLL NGIKUT PARENT
            // =========================
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
                  // NULL = BELUM ADA HALAMAN
                ),
                _buildModernMenuCard(
                  context,
                  "Stok Alat",
                  Icons.inventory_2,
                  "Kelola Keyboard",
                  const KeyboardScreen(role: "petugas"),
                ),
                _buildModernMenuCard(
                  context,
                  "Laporan",
                  Icons.bar_chart,
                  "Data Bulanan",
                  null,
                  // NULL = BELUM ADA HALAMAN
                ),
              ],
            ),

            const SizedBox(height: 25),

            // =====================================================
            // TAMBAHAN: LIST PENGEMBALIAN TERBARU (REALTIME)
            // =====================================================
            const Text(
              "Aktivitas Terkini",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder(
              stream: supabase
                  .from('permintaan')
                  .stream(primaryKey: ['id_permintaan'])
                  .order('created_at')
                  .limit(3),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("Tidak ada aktivitas");
                }
                return Column(
                  children: snapshot.data!.map((data) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: backgroundBlue, child: Icon(Icons.history, color: primaryBlue)),
                        title: Text("Alat ID: ${data['id_alat']}"),
                        subtitle: Text("Status: ${data['status']}"),
                        trailing: const Icon(Icons.arrow_right),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // CARD STATISTIK KECIL (KHUSUS PETUGAS)
  // =====================================================
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
            color: Colors.black.withOpacity(0.05),
            // OPACITY 5% = BAYANGAN TIPIS
            blurRadius: 10,
          ),
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

  // =====================================================
  // CARD MENU MODERN (PETUGAS)
  // =====================================================
  Widget _buildModernMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
    Widget? target,
  ) {
    return InkWell(
      // INKWELL = BISA DIKLIK + EFEK RIPPLE
      onTap: () {
        // NAVIGASI HANYA JIKA TARGET TIDAK NULL
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              // LINGKARAN ICON
              backgroundColor: Colors.black.withOpacity(0.05),
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

// =====================================================
// 3) DASHBOARD PEMINJAM
// =====================================================
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
            // =========================
            // BANNER/LOGO
            // =========================
            Container(
              width: double.infinity, // FULL LEBAR
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: ClipRRect(
                // POTONG CHILD SESUAI BORDER RADIUS
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  // JIKA ASSET TIDAK ADA -> TAMPILKAN ICON
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.image, size: 50)),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // JUDUL SECTION
            const Text(
              "Aksi Cepat",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 15),

            // MENU PANJANG: LIHAT DAFTAR KEYBOARD
            _buildLongMenu(
              context,
              "Lihat Daftar Keyboard",
              Icons.search,
              const KeyboardScreen(role: "peminjam"),
            ),

            const SizedBox(height: 12),

            // MENU PANJANG: STATUS PEMINJAMAN
            _buildLongMenu(
              context,
              "Lihat Status Peminjaman",
              Icons.assignment,
              const StatusPage(),
            ),

            // ✅ TAMBAHAN MENU: PENGEMBALIAN (PEMINJAM)
            const SizedBox(height: 12),
            _buildLongMenu(
              context,
              "Pengembalian",
              Icons.keyboard_return,
              const PengembalianPage(),
            ),

            const SizedBox(height: 25),

            // JUDUL SECTION
            const Text(
              "Status Peminjaman Terkini",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 15),

            // STATUS REALTIME USER
            _buildStatusRealtime(),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // STATUS REALTIME: AMBIL PERMINTAAN TERAKHIR USER LOGIN
  // =====================================================
  Widget _buildStatusRealtime() {
    final user = supabase.auth.currentUser;
    // USER LOGIN SAAT INI (BISA NULL KALO BELUM LOGIN)

    return StreamBuilder(
      stream: supabase
          .from('permintaan')
          .stream(primaryKey: ['id_permintaan'])
          .eq('id_user', user?.id ?? '')
          // FILTER: HANYA PERMINTAAN MILIK USER LOGIN
          .order('created_at'),
      // URUT BERDASARKAN created_at (DEFAULT ASC)

      builder: (context, snapshot) {
        // KALO DATA KOSONG/BLM ADA: TAMPILKAN TEKS
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Belum ada riwayat peminjaman"));
        }

        // AMBIL DATA PALING AKHIR (PALING BARU SETELAH DI-ORDER)
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

// =====================================================
// HELPER WIDGETS (DIPAKAI BERBAGAI DASHBOARD)
// =====================================================

AppBar _buildAppBar(
  BuildContext context,
  String title,
  String role,
  String nama,
) {
  final user = supabase.auth.currentUser;
  // DIPAKAI BUAT FILTER KERANJANG/USER DATA

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
      // =================================================
      // ROLE PEMINJAM: ICON KERANJANG + BADGE JUMLAH ITEM
      // =================================================
      if (role == "peminjam")
        StreamBuilder(
          stream: supabase
              .from('keranjang')
              .stream(primaryKey: ['id_keranjang'])
              .eq('id_user', user?.id ?? ''),
          builder: (context, snapshot) {
            final count = snapshot.hasData ? snapshot.data!.length : 0;
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

      // =================================================
      // ROLE PETUGAS: ICON NOTIF + BADGE PERMINTAAN MENUNGGU
      // =================================================
      if (role == "petugas")
        StreamBuilder(
          stream: supabase
              .from('permintaan')
              .stream(primaryKey: ['id_permintaan'])
              .eq('status', 'menunggu'),
          builder: (context, snapshot) {
            final count = snapshot.hasData ? snapshot.data!.length : 0;
            return _buildBadgeIcon(
              context,
              Icons.notifications,
              count,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const KonfirmasiPetugasPage(),
                  ),
                );
              },
            );
          },
        ),

      // =================================================
      // PROFILE ICON: AMBIL FULL USER DATA DARI TABEL 'users'
      // FIX UTAMA: ProfileScreen BUTUH fullUserData
      // =================================================
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('users') // KALO NAMA TABEL BEDA, GANTI DI SINI
            .stream(primaryKey: ['id'])
            .eq('id', user?.id ?? ''),
        builder: (context, snap) {
          // AMBIL DATA USER (MAP) ATAU MAP KOSONG BIAR GA CRASH
          final fullUserData = (snap.hasData && snap.data!.isNotEmpty)
              ? snap.data!.first
              : <String, dynamic>{};

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: const Icon(
                Icons.account_circle,
                color: Colors.white,
                size: 35,
              ),
              onPressed: () {
                // NAVIGASI KE PROFILE SCREEN
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      role: role,
                      nama: nama,
                      fullUserData: fullUserData,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    ],
  );
}

// =====================================================
// BADGE ICON: ICON + ANGKA DI POJOK (KERANJANG/NOTIF)
// =====================================================
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

// =====================================================
// CARD STATISTIK BESAR (ADMIN)
// =====================================================
Widget _buildStatCard(String title, String value) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
        ),
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

// =====================================================
// MENU GRID (KOTAK) UNTUK ADMIN
// =====================================================
Widget _buildMenuCard(
  BuildContext context,
  String title,
  IconData icon,
  Widget? targetScreen,
) {
  return InkWell(
    onTap: () {
      // NAVIGASI HANYA JIKA targetScreen ADA
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: backgroundBlue.withOpacity(0.03),
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

// =====================================================
// MENU PANJANG (LISTTILE) UNTUK PEMINJAM
// =====================================================
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
          color: Colors.black.withOpacity(0.05),
          blurRadius: 5,
        ),
      ],
    ),
    child: ListTile(
      onTap: () {
        // NAVIGASI HANYA JIKA HALAMAN ADA
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

// =====================================================
// CARD STATUS PEMINJAMAN (ITEM + BADGE STATUS + TANGGAL)
// =====================================================
Widget _buildStatusCard(String item, String status, String date) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
        ),
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
            // BADGE STATUS: WARNA BERUBAH SESUAI STATUS
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

            // TANGGAL
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
