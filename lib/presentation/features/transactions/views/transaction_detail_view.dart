// lib/presentation/features/transactions/views/transaction_detail_view.dart

import 'package:flutter/material.dart';
import 'package:app_pos_ac/data/models/transaction.dart'; // TransactionAC
import 'package:app_pos_ac/data/models/transaction_item.dart';
import 'package:intl/intl.dart';

/// Displays the detailed information of a single transaction.
class TransactionDetailView extends StatelessWidget {
  final TransactionAC transaction;

  const TransactionDetailView({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMMM yyyy, HH:mm');

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
                // Button to generate PDF will be added in Fase 2
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

  /// Helper to build the table for service items.
  Widget _buildItemsTable(List<TransactionItem> items, NumberFormat formatter) {
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
