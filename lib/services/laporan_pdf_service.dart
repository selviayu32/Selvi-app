import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LaporanPdfService {
  static Future<Uint8List> generateLaporanPdf({
    required String judul,
    required String periode,
    required int totalPeminjaman,
    required int totalPengembalian,
    required int totalDenda,
    required List<Map<String, String>> rows,
  }) async {
    final doc = pw.Document();

    pw.Widget summaryBox(String label, String value, PdfColor color) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(
                color: PdfColors.white,
                fontSize: 10,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1F2A44),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  judul,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Periode: $periode',
                  style: const pw.TextStyle(
                    color: PdfColor.fromInt(0xFFD6E3FF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              pw.Expanded(
                child: summaryBox(
                  'Total Peminjaman',
                  '$totalPeminjaman',
                  const PdfColor.fromInt(0xFF4C6DAF),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: summaryBox(
                  'Total Pengembalian',
                  '$totalPengembalian',
                  const PdfColor.fromInt(0xFF2C9B79),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: summaryBox(
                  'Total Denda',
                  'Rp $totalDenda',
                  const PdfColor.fromInt(0xFFB85454),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Ringkasan Detail',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF1F2A44),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF344B7F),
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headers: const [
              'No',
              'Nama',
              'Status',
              'Denda',
            ],
            data: List.generate(rows.length, (i) {
              final row = rows[i];
              return [
                '${i + 1}',
                row['nama'] ?? '-',
                row['status'] ?? '-',
                row['denda'] ?? '-',
              ];
            }),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<void> printLaporan({
    required String judul,
    required String periode,
    required int totalPeminjaman,
    required int totalPengembalian,
    required int totalDenda,
    required List<Map<String, String>> rows,
  }) async {
    await Printing.layoutPdf(
      onLayout: (format) => generateLaporanPdf(
        judul: judul,
        periode: periode,
        totalPeminjaman: totalPeminjaman,
        totalPengembalian: totalPengembalian,
        totalDenda: totalDenda,
        rows: rows,
      ),
    );
  }
}
