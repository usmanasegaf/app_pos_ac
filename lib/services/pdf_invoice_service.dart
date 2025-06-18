// lib/services/pdf_invoice_service.dart

import 'dart:typed_data'; // Untuk Uint8List
import 'package:pdf/pdf.dart'; // Untuk PDF format
import 'package:pdf/widgets.dart' as pw; // Alias untuk widget PDF
import 'package:intl/intl.dart'; // Untuk format mata uang dan tanggal
import 'package:app_pos_ac/data/models/transaction.dart'; // Mengimpor model TransactionAC
import 'package:app_pos_ac/data/models/transaction_item.dart'; // Mengimpor model TransactionItem

/// A service class responsible for generating PDF invoices from transaction data.
class PdfInvoiceService {
  /// Generates a PDF invoice for a given transaction.
  /// Requires logoBytes as a Uint8List for displaying the company logo.
  /// Returns the PDF document as a Uint8List.
  Future<Uint8List> generateInvoice(TransactionAC transaction, Uint8List logoBytes) async { // Pastikan parameter logoBytes ada
    final pdf = pw.Document(); // Membuat dokumen PDF baru

    // Formatter untuk mata uang Rupiah
    final currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Formatter untuk tanggal dan waktu
    final dateFormatter = DateFormat('dd MMMM HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header: Logo di kiri atas, Judul Invoice di kanannya
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center, // Menyusun vertikal logo dan teks
              children: [
                // Logo di kiri - UKURAN TELAH DITINGKATKAN DI SINI
                pw.Image(pw.MemoryImage(logoBytes), width: 140, height: 140), // <--- UBAH DI SINI
                pw.SizedBox(width: 20), // Jarak antara logo dan judul
// checkpoint
                // Judul Invoice
                pw.Expanded(
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight, // Judul bisa diatur di tengah atau kanan
                    child: pw.Text(
                      'INVOICE LAYANAN AC',
                      style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20), // Jarak antara header dan konten

            // Detail Perusahaan dan Tanggal/Invoice Number
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Nama Perusahaan: AC Teknik Semangat Pagi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Alamat: Paseban Barat B7 No.78 \nKopo Kencana, Kota Bandung'),
                    pw.Text('Telepon: 0813-2011-1868'),
                    pw.Text('Email: info@serviceacku.com'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Tanggal: ${dateFormatter.format(DateTime.now())}'),
                    pw.Text('Invoice # ${transaction.id ?? 'N/A'}'), // Gunakan ID transaksi sebagai nomor invoice
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Detail Pelanggan
            pw.Text(
              'Detail Pelanggan:',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Text('Nama: ${transaction.customerName}'),
            if (transaction.customerAddress != null && transaction.customerAddress!.isNotEmpty)
              pw.Text('Alamat: ${transaction.customerAddress}'),
            pw.SizedBox(height: 20),

            // Tabel Item Layanan
            pw.Text(
              'Daftar Layanan:',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildItemsTable(transaction.items, currencyFormatter),
            pw.SizedBox(height: 20),

            // Total
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL:',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  currencyFormatter.format(transaction.total),
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Catatan Kaki (tanpa placeholder tanda tangan)
            pw.Align(
              alignment: pw.Alignment.bottomCenter,
              child: pw.Column(
                children: [
                  pw.Text('Terima kasih atas kepercayaan Anda!', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save(); // Menyimpan dokumen PDF
  }

  /// Helper function to build the service items table for the PDF.
  pw.Widget _buildItemsTable(List<TransactionItem> items, NumberFormat currencyFormatter) {
    // Header tabel
    final headers = ['Layanan', 'Qty', 'Harga', 'Subtotal'];

    // Baris data
    final data = items.map((item) {
      return [
        item.serviceName,
        item.quantity.toString(),
        currencyFormatter.format(item.servicePrice),
        currencyFormatter.format(item.subtotal),
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey500),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellPadding: const pw.EdgeInsets.all(8),
    );
  }
}
