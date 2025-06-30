// import 'package:flutter/material.dart';
//
// import 'invoice.dart';
//
// class InvoiceView extends StatelessWidget {
//   final Invoice invoice;
//   // 1. Add a callback function for export
//   final Function(Invoice) onExport;
//
//   // 2. Update the constructor to require the callback
//   const InvoiceView({
//     super.key,
//     required this.invoice,
//     required this.onExport, // New required parameter
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Invoice Details'),
//         // 3. Add an IconButton to the AppBar's actions
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.download), // Or Icons.file_download, Icons.excel_file
//             onPressed: () => onExport(invoice), // Call the passed function with the invoice data
//             tooltip: 'Export to Excel',
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Invoice #: ${invoice.invoiceNo}", style: Theme.of(context).textTheme.titleMedium),
//             Text("Date: ${invoice.date}"),
//             const SizedBox(height: 16),
//
//             Text("🔻 Bill From", style: Theme.of(context).textTheme.titleSmall),
//             Text(invoice.billFrom.name),
//             Text(invoice.billFrom.address),
//             Text("📞 ${invoice.billFrom.mobile}"),
//             const SizedBox(height: 16),
//
//             Text("🔺 Bill To", style: Theme.of(context).textTheme.titleSmall),
//             Text(invoice.billTo.name),
//             Text(invoice.billTo.address),
//             Text("📞 ${invoice.billTo.mobile}"),
//             const SizedBox(height: 16),
//
//             Text("🧾 Items", style: Theme.of(context).textTheme.titleSmall),
//             Table(
//               border: TableBorder.all(),
//               columnWidths: const {
//                 0: FixedColumnWidth(40),
//                 1: FlexColumnWidth(),
//                 2: FixedColumnWidth(70),
//                 3: FixedColumnWidth(80),
//               },
//               children: [
//                 TableRow(
//                   decoration: const BoxDecoration(color: Colors.grey),
//                   children: const [
//                     Padding(
//                       padding: EdgeInsets.all(8),
//                       child: Text('No', style: TextStyle(fontWeight: FontWeight.bold)),
//                     ),
//                     Padding(
//                       padding: EdgeInsets.all(8),
//                       child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
//                     ),
//                     Padding(
//                       padding: EdgeInsets.all(8),
//                       child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold)),
//                     ),
//                     Padding(
//                       padding: EdgeInsets.all(8),
//                       child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
//                     ),
//                   ],
//                 ),
//                 ...invoice.items.map(
//                   (item) => TableRow(
//                     children: [
//                       Padding(padding: const EdgeInsets.all(8), child: Text(item.no.toString())),
//                       Padding(padding: const EdgeInsets.all(8), child: Text(item.description)),
//                       Padding(padding: const EdgeInsets.all(8), child: Text(item.rate)),
//                       Padding(padding: const EdgeInsets.all(8), child: Text(item.total)),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//
//             Align(
//               alignment: Alignment.centerRight,
//               child: Text(
//                 "Grand Total: ₹${invoice.grandTotal}",
//                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
