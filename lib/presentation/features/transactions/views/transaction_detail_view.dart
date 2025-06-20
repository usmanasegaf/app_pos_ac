import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

import 'package:app_pos_ac/data/models/transaction.dart';
import 'package:app_pos_ac/data/models/transaction_item.dart';
import 'package:app_pos_ac/services/pdf_invoice_service.dart';
import 'package:app_pos_ac/presentation/common_widgets/app_dialogs.dart';

class TransactionDetailView extends StatelessWidget {
  final TransactionAC transaction;

  const TransactionDetailView({super.key, required this.transaction});

  Future<void> _generateAndSharePdf(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Membuat PDF...'),
            ],
          ),
        ),
      );

      final ByteData bytes = await rootBundle.load('assets/images/logo_ac_teknik.jpeg');
      final Uint8List logoBytes = bytes.buffer.asUint8List();

      final pdfBytes = await PdfInvoiceService().generateInvoice(transaction, logoBytes);

      if (context.mounted) Navigator.pop(context);

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Invoice Siap'),
          content: const Text('Anda ingin melihat atau membagikan PDF ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kembali'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Printing.sharePdf(bytes: pdfBytes, filename: 'invoice_${transaction.id}.pdf');
              },
              child: const Text('Bagikan PDF'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Printing.layoutPdf(
                  onLayout: (PdfPageFormat format) async => pdfBytes,
                  name: 'invoice_${transaction.id}.pdf',
                );
              },
              child: const Text('Lihat PDF'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (Navigator.of(context).canPop()) Navigator.pop(context);
      showAppMessageDialog(
        context,
        title: 'Gagal Membuat PDF',
        message: 'Terjadi kesalahan saat membuat PDF.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ID Transaksi:', transaction.id.toString()),
                _buildDetailRow('Waktu:', dateFormatter.format(transaction.date)),
                const Divider(height: 32),
                const Text('Data Pelanggan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDetailRow('Nama:', transaction.customerName),
                if ((transaction.customerAddress ?? '').isNotEmpty)
                  _buildDetailRow('Alamat:', transaction.customerAddress!),
                const Divider(height: 32),
                const Text('Layanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildItemsTable(transaction.items, formatter),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
                      formatter.format(transaction.total),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _generateAndSharePdf(context),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Buat & Bagikan Invoice PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildItemsTable(List<TransactionItem> items, NumberFormat formatter) {
    final headers = ['Layanan', 'Qty', 'Harga', 'Subtotal'];
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[100]),
          children: headers.map((h) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          }).toList(),
        ),
        ...items.map((item) {
          return TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(8), child: Text(item.serviceName)),
              Padding(padding: const EdgeInsets.all(8), child: Text('${item.quantity}', textAlign: TextAlign.center)),
              Padding(padding: const EdgeInsets.all(8), child: Text(formatter.format(item.servicePrice), textAlign: TextAlign.right)),
              Padding(padding: const EdgeInsets.all(8), child: Text(formatter.format(item.subtotal), textAlign: TextAlign.right)),
            ],
          );
        }),
      ],
    );
  }
}
