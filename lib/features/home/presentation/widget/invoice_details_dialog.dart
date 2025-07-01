// lib/features/home/presentation/widgets/invoice_details_dialog.dart
import 'package:flutter/material.dart';
import 'package:receipt_management/features/home/data/model/invoice.dart';

import '../../../../constants/app_color.dart'; // Ensure correct path for AppColor

class InvoiceDetailsDialog extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const InvoiceDetailsDialog({
    super.key,
    required this.invoice,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invoice Details Extracted'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Invoice No:', invoice.invoiceNo),
            _buildDetailRow('Date:', invoice.date),
            if (invoice.billFrom != null) ...[
              const SizedBox(height: 10),
              Text(
                'Bill From:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              _buildDetailRow('  Name:', invoice.billFrom!.name),
              _buildDetailRow('  Address:', invoice.billFrom!.address),
              _buildDetailRow('  Mobile:', invoice.billFrom!.mobile),
            ],
            if (invoice.billTo != null) ...[
              const SizedBox(height: 10),
              Text(
                'Bill To:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              _buildDetailRow('  Name:', invoice.billTo!.name),
              _buildDetailRow('  Address:', invoice.billTo!.address),
              _buildDetailRow('  Mobile:', invoice.billTo!.mobile),
            ],
            const SizedBox(height: 10),
            Text(
              'Items:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (invoice.items != null && invoice.items!.isNotEmpty)
              ...invoice.items!.asMap().entries.map((entry) {
                int idx = entry.key + 1;
                Items item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item $idx:',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                      ),
                      _buildDetailRow('    Description:', item.description),
                      _buildDetailRow('    Quantity:', item.quantity),
                      _buildDetailRow('    Rate:', item.rate),
                      _buildDetailRow('    Total:', item.total),
                    ],
                  ),
                );
              }).toList()
            else
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text('    No items extracted.'),
              ),
            const SizedBox(height: 10),
            _buildDetailRow('Grand Total:', invoice.grandTotal),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('Cancel', style: TextStyle(color: AppColor.primary)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary, // Button background color
            foregroundColor: AppColor.white, // Text color
          ),
          child: const Text('Confirm & Save'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }
}
