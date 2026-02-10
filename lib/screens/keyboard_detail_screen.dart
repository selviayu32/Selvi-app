import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'keranjang_page.dart';
import 'permintaan_page.dart';
import 'edit_keyboard_screen.dart';

class KeyboardDetailScreen extends StatefulWidget {
  final dynamic idAlat;
  final String merk;
  final String status;
  final String spesifikasi;
  final String imageUrl;
  final String role;

  const KeyboardDetailScreen({
    super.key,
    required this.idAlat,
    required this.merk,
    required this.status,
    required this.spesifikasi,
    required this.imageUrl,
    required this.role,
  });

  @override
  State<KeyboardDetailScreen> createState() => _KeyboardDetailScreenState();
}

class _KeyboardDetailScreenState extends State<KeyboardDetailScreen> {
  final supabase = Supabase.instance.client;

  late Future<Map<String, dynamic>> _futureDetail;

  bool _addingToCart = false;

  // flag untuk kirim sinyal refresh ke halaman sebelumnya saat back
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _futureDetail = _fetchKeyboardDetail();
  }

  void _refreshDetail() {
    setState(() {
      _futureDetail = _fetchKeyboardDetail();
    });
  }

  Future<Map<String, dynamic>> _fetchKeyboardDetail() async {
    final response = await supabase
        .from('alat')
        .select()
        .eq('id_alat', widget.idAlat)
        .single();

    return response as Map<String, dynamic>;
  }

  // ✅ Insert keranjang yang aman
  Future<void> _addToCartFromDetail() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kamu belum login.")),
      );
      return;
    }

    if (_addingToCart) return;

    setState(() => _addingToCart = true);

    try {
      final existing = await supabase
          .from('keranjang')
          .select('id_keranjang')
          .eq('id_user', user.id)
          .eq('id_alat', widget.idAlat);

      if (existing is List && existing.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Produk sudah ada di keranjang.")),
        );
        return;
      }

      await supabase.from('keranjang').insert({
        'id_alat': widget.idAlat,
        'id_user': user.id,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Berhasil masuk keranjang"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const KeranjangPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal masuk keranjang: $e")),
      );
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  // ✅ BACK HANDLER: tidak putih + tidak butuh import beranda
  void _safeBack() {
    final nav = Navigator.of(context);

    if (nav.canPop()) {
      nav.pop(_changed);
      return;
    }

    // kalau stack kosong (sering di Flutter Web / direct open)
    // balik ke route pertama yang ada
    nav.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _safeBack();
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.only(left: 12, top: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
              onPressed: _safeBack,
            ),
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _futureDetail,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Data tidak ditemukan"));
            }

            final data = snapshot.data!;
            final String merk = (data['merk'] ?? 'Tidak Diketahui').toString();
            final String status = (data['status'] ?? 'tidak diketahui').toString();
            final String spesifikasi =
                (data['spesifikasi'] ?? 'Belum ada spesifikasi').toString();
            final String imageUrl = (data['image_url'] ?? '').toString();

            final String role = widget.role;

            final bool isAvailable = status.toLowerCase() == 'tersedia';
            final statusColor = isAvailable ? Colors.green : Colors.orange;
            final statusText = isAvailable ? 'TERSEDIA' : status.toUpperCase();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    height: 260,
                    margin: const EdgeInsets.only(top: 60, left: 20, right: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Icon(Icons.image_not_supported,
                                    size: 80, color: Colors.grey),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.keyboard_alt_rounded,
                                  size: 100, color: Colors.grey),
                            ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        merk,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: statusColor, width: 1.5),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "ID Alat: ${widget.idAlat}",
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.description_outlined,
                                    color: Color(0xFF5371A5), size: 22),
                                SizedBox(width: 10),
                                Text(
                                  "Spesifikasi",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              spesifikasi,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildActionButton(
                        context,
                        role,
                        merk,
                        status,
                        spesifikasi,
                        imageUrl,
                        isAvailable,
                      ),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String role,
    String merk,
    String status,
    String spesifikasi,
    String imageUrl,
    bool isAvailable,
  ) {
    if (role == 'peminjam') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: (_addingToCart || !isAvailable) ? null : _addToCartFromDetail,
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: Text(
            _addingToCart ? "Memproses..." : "Tambah ke Keranjang",
            style: const TextStyle(fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFF5371A5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    } else if (role == 'petugas') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PermintaanPage()),
            );
          },
          icon: const Icon(Icons.request_page_rounded),
          label: const Text("Permintaan Peminjaman", style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    } else if (role == 'admin') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditKeyboardScreen(
                  idAlat: widget.idAlat,
                  merk: merk,
                  status: status,
                  spesifikasi: spesifikasi,
                  imageUrl: imageUrl,
                ),
              ),
            );

            if (result == true && mounted) {
              _changed = true;
              _refreshDetail();
            }
          },
          icon: const Icon(Icons.edit_rounded),
          label: const Text("Edit Produk", style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
