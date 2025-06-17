import 'package:flutter/material.dart';
import 'package:app_pos_ac/data/models/transaction.dart'; // TransactionAC
import 'package:app_pos_ac/data/models/transaction_item.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:app_pos_ac/services/pdf_invoice_service.dart';
import 'package:app_pos_ac/presentation/common_widgets/app_dialogs.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Displays the detailed information of a single transaction.
class TransactionDetailView extends StatelessWidget {
  final TransactionAC transaction;

  const TransactionDetailView({super.key, required this.transaction});

  /// Generates the PDF invoice and then provides options to view or share it.
  Future<void> _generateAndSharePdf(BuildContext context) async {
    try {
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

      final pdfBytes = await PdfInvoiceService().generateInvoice(transaction);

      Navigator.pop(context);

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
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Back'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
                onPressed: () {
                  Navigator.pop(dialogContext);
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
                  Navigator.pop(dialogContext);
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
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      showAppMessageDialog(
        context,
        title: 'Error Generating PDF',
        message: 'Failed to generate PDF: ${e.toString()}',
      );
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
                // Untuk tampilan Flutter, gunakan widget Flutter
                ..._buildItemsTableFlutter(transaction.items, currencyFormatter),
                const Divider(height: 30, thickness: 2),
                const SizedBox(height: 10), // Gunakan SizedBox Flutter, bukan pw.SizedBox

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
                      backgroundColor: Colors.redAccent,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  /// Untuk tampilan Flutter
  List<Widget> _buildItemsTableFlutter(List<TransactionItem> items, NumberFormat formatter) {
    return [
      Table(
        border: TableBorder.all(),
        children: [
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Layanan', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Qty', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Harga', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Subtotal', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          ...items.map((item) => TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(item.serviceName),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(item.quantity.toString()),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(formatter.format(item.servicePrice)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(formatter.format(item.subtotal)),
              ),
            ],
          )),
        ],
      ),
      const SizedBox(height: 10),
    ];
  }

  /// Untuk PDF (gunakan di PdfInvoiceService, bukan di UI Flutter)
  pw.Widget buildItemsTablePdf(List<TransactionItem> items, NumberFormat formatter) {
    final headers = ['Layanan', 'Qty', 'Harga', 'Subtotal'];
    final data = items.map((item) {
      return [
        item.serviceName,
        item.quantity.toString(),
        formatter.format(item.servicePrice),
        formatter.format(item.subtotal),
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