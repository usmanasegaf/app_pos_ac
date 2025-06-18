// lib/presentation/features/transactions/views/transaction_detail_view.dart

import 'package:flutter/material.dart';
import 'package:app_pos_ac/data/models/transaction.dart'; // TransactionAC
import 'package:app_pos_ac/data/models/transaction_item.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:app_pos_ac/services/pdf_invoice_service.dart'; // Import service PDF
import 'package:app_pos_ac/presentation/common_widgets/app_dialogs.dart'; // Import dialogs
import 'package:pdf/pdf.dart'; // Untuk PdfPageFormat di Printing.layoutPdf
import 'package:pdf/widgets.dart' as pw; // Untuk pw.Widget di _buildItemsTable
import 'package:flutter/services.dart' show rootBundle; // Import ini untuk memuat aset
import 'dart:typed_data'; // Untuk ByteData dan Uint8List

/// Displays the detailed information of a single transaction.
class TransactionDetailView extends StatelessWidget {
  final TransactionAC transaction;

  const TransactionDetailView({super.key, required this.transaction});

  /// Generates the PDF invoice and then provides options to view or share it.
  Future<void> _generateAndSharePdf(BuildContext context) async {
    try {
      // Tampilkan indikator loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Generating PDF...'),
            ],
          ),
        ),
      );

      // Muat logo dari aset
      // PASTIKAN FILE LOGO ANDA ADA DI 'assets/images/logo_ac_teknik.jpeg'
      // DAN SUDAH DIDAFTARKAN DI pubspec.yaml
      final ByteData bytes = await rootBundle.load('assets/images/logo_ac_teknik.jpeg'); // <--- Gunakan nama file .jpeg di sini
      final Uint8List logoBytes = bytes.buffer.asUint8List();

      // PENTING: Teruskan logoBytes sebagai argumen kedua
      final pdfBytes = await PdfInvoiceService().generateInvoice(transaction, logoBytes); // <--- Sekarang melewatkan dua argumen

      // Tutup dialog loading
      Navigator.pop(context);

      // Dialog untuk pilihan View atau Share
      await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
            title: const Text('Invoice Ready!'),
            content: const Text('Do you want to view the PDF or share it?'),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                onPressed: () => Navigator.pop(dialogContext, false), // Kembali ke view detail
                child: const Text('Back'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
                onPressed: () {
                  Navigator.pop(dialogContext); // Tutup dialog
                  Printing.sharePdf(bytes: pdfBytes, filename: 'invoice_${transaction.id}.pdf');
                },
                child: const Text('Share PDF'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                onPressed: () {
                  Navigator.pop(dialogContext); // Tutup dialog
                  Printing.layoutPdf(
                    onLayout: (PdfPageFormat format) async => pdfBytes,
                    name: 'invoice_${transaction.id}.pdf',
                  );
                },
                child: const Text('View PDF'),
              ),
            ],
          );
        },
      );

    } catch (e) {
      // Pastikan dialog loading ditutup jika terjadi error
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      showAppMessageDialog(
        context,
        title: 'Error Generating PDF',
        message: 'Failed to generate PDF',
      );
      debugPrint('Error generating PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMMM HH:mm'); 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Transaction ID:', transaction.id.toString()),
                _buildDetailRow('Date & Time:', dateFormatter.format(transaction.date)),
                const Divider(),
                const Text(
                  'Customer Information:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                _buildDetailRow('Name:', transaction.customerName),
                if (transaction.customerAddress != null && transaction.customerAddress!.isNotEmpty)
                  _buildDetailRow('Address:', transaction.customerAddress!),
                const Divider(),
                const Text(
                  'Service Items:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                const SizedBox(height: 10),
                _buildItemsTable(transaction.items, currencyFormatter),
                const Divider(height: 30, thickness: 2),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      currencyFormatter.format(transaction.total),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Tombol untuk generate & share PDF
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _generateAndSharePdf(context),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generate & Share Invoice PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      backgroundColor: Colors.redAccent, // Warna merah untuk aksi PDF
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper to build a consistent detail row.
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Fixed width for labels
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to build the table for service items for Flutter UI.
  Widget _buildItemsTable(List<TransactionItem> items, NumberFormat formatter) {
    // Header tabel
    final headers = ['Layanan', 'Qty', 'Harga', 'Subtotal'];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3), // Service Name
        1: FlexColumnWidth(1), // Qty
        2: FlexColumnWidth(2), // Price
        3: FlexColumnWidth(2), // Subtotal
      },
      border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8.0)),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(8.0)),
          children: const [
            Padding(padding: EdgeInsets.all(8.0), child: Text('Service', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8.0), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            Padding(padding: EdgeInsets.all(8.0), child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
            Padding(padding: EdgeInsets.all(8.0), child: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
          ],
        ),
        ...items.map((item) {
          return TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(8.0), child: Text(item.serviceName)),
              Padding(padding: const EdgeInsets.all(8.0), child: Text(item.quantity.toString(), textAlign: TextAlign.center)),
              Padding(padding: const EdgeInsets.all(8.0), child: Text(formatter.format(item.servicePrice), textAlign: TextAlign.right)),
              Padding(padding: const EdgeInsets.all(8.0), child: Text(formatter.format(item.subtotal), textAlign: TextAlign.right)),
            ],
          );
        }).toList(),
      ],
    );
  }
}
