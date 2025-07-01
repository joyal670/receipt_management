// lib/features/home/home_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:excel/excel.dart' as excel_package;
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:receipt_management/features/home/data/model/invoice.dart';

import '../../../constants/app_color.dart';
import 'widget/bar_chart_section.dart'; // Import the updated chart widget
import 'widget/empty_widget.dart';
import 'widget/invoice_details_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ValueNotifier<int> currentIndex = ValueNotifier(1);
  final _fabKey = GlobalKey<ExpandableFabState>();

  ValueNotifier<List<Invoice>> invoicesNotifier = ValueNotifier([]);
  ValueNotifier<String?> currentStatus = ValueNotifier(null);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildGraphSection(), // Now passes dynamic data
      _buildInvoiceGridView(),
      const Center(child: Text("Settings / Favorites (Future Feature)")),
    ];
  }

  @override
  void dispose() {
    currentIndex.dispose();
    invoicesNotifier.dispose();
    currentStatus.dispose();
    super.dispose();
  }

  Future<void> pickImage(ImageSource source) async {
    if (_fabKey.currentState != null && _fabKey.currentState!.isOpen) {
      _fabKey.currentState!.toggle();
    }

    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) {
      return;
    }

    currentStatus.value = 'Scanning invoice...';
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final inputImage = await File(pickedFile.path).readAsBytes();

      final prompt = TextPart(
        "Extract invoice details from this image in JSON format according to the provided schema.",
      );
      final imagePart = InlineDataPart('image/jpeg', inputImage);

      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: invoiceSchema,
        ),
      );

      currentStatus.value = 'Analyzing with AI...';
      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      if (response.text != null && response.text!.isNotEmpty) {
        currentStatus.value = 'Extracting document data...';
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          final Map<String, dynamic> jsonMap = jsonDecode(response.text!);
          final result = Invoice.fromJson(jsonMap);
          result.image = pickedFile.path;

          currentStatus.value = null;
          bool? confirmSave = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return InvoiceDetailsDialog(
                invoice: result,
                onConfirm: () {
                  Navigator.of(dialogContext).pop(true);
                },
                onCancel: () {
                  Navigator.of(dialogContext).pop(false);
                },
              );
            },
          );

          if (confirmSave == true) {
            final List<Invoice> updatedInvoices = List.from(invoicesNotifier.value)..add(result);
            invoicesNotifier.value = updatedInvoices;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invoice scanned and added successfully!')),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Invoice data discarded.')));
          }
        } on FormatException catch (e) {
          debugPrint('JSON decoding error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to process invoice: Invalid data format. ${e.message}')),
          );
        } on TypeError catch (e) {
          debugPrint('Type error during JSON parsing: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Mismatched invoice data structure.')),
          );
        } catch (e) {
          debugPrint('Unexpected error during JSON processing: $e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI could not extract invoice data from the image.')),
        );
      }
    } catch (e) {
      debugPrint('Error during image processing or AI request: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to scan image: ${e.toString()}')));
    } finally {
      // currentStatus.value = null;
    }
  }

  Future<void> _exportInvoiceToExcel(Invoice invoice) async {
    currentStatus.value = 'Preparing Excel export...';
    try {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Storage permission denied. Cannot export.')));
        return;
      }

      final excel_package.Excel excel = excel_package.Excel.createExcel();
      final excel_package.Sheet sheetObject = excel['InvoiceData'];

      sheetObject.appendRow([
        excel_package.TextCellValue('Invoice Number'),
        excel_package.TextCellValue('Date'),
        excel_package.TextCellValue('Vendor Name'),
        excel_package.TextCellValue('Total Amount'),
        excel_package.TextCellValue('Currency'),
        excel_package.TextCellValue('Items'),
      ]);

      String itemsString = (invoice.items ?? [])
          .map(
            (item) =>
                '${item.description ?? ''} (Qty: ${item.quantity ?? ''}, Rate: ${item.rate ?? ''}, Total: ${item.total ?? ''})',
          )
          .join('\n');

      sheetObject.appendRow([
        excel_package.TextCellValue(invoice.invoiceNo ?? ''),
        excel_package.TextCellValue(invoice.date ?? ''),
        excel_package.TextCellValue(invoice.billFrom?.name ?? ''),
        excel_package.TextCellValue(invoice.grandTotal ?? ''),
        excel_package.TextCellValue(itemsString),
      ]);

      for (int i = 0; i < 6; i++) {
        sheetObject.setColumnAutoFit(i);
      }

      final List<int>? excelBytes = excel.save();
      if (excelBytes == null) {
        throw 'Failed to generate Excel file bytes.';
      }

      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw 'Could not get a suitable directory for saving.';
      }

      final String fileName =
          'invoice_${invoice.invoiceNo ?? 'unknown'}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final String filePath = '${directory.path}/$fileName';
      final File file = File(filePath);

      await file.writeAsBytes(excelBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice exported to: ${file.path}'),
          duration: const Duration(seconds: 5),
        ),
      );
      debugPrint('Invoice exported to: ${file.path}');
    } catch (e) {
      debugPrint('Error exporting invoice to Excel: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export invoice to Excel: ${e.toString()}')));
    } finally {
      currentStatus.value = null;
    }
  }

  void _showInvoiceOptionsBottomSheet(BuildContext context, Invoice invoice) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(bc);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sharing invoice ${invoice.invoiceNo ?? ''}')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(bc);
                  final List<Invoice> currentInvoices = List.from(invoicesNotifier.value);
                  currentInvoices.remove(invoice);
                  invoicesNotifier.value = currentInvoices;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invoice ${invoice.invoiceNo ?? ''} deleted.')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export to Excel (.xlsx)'),
                onTap: () {
                  Navigator.pop(bc);
                  _exportInvoiceToExcel(invoice);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvoiceGridView() {
    return ValueListenableBuilder<List<Invoice>>(
      valueListenable: invoicesNotifier,
      builder: (context, invoices, child) {
        if (invoices.isEmpty) {
          return const Center(child: EmptyWidget());
        } else {
          return GridView.builder(
            itemCount: invoices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return GestureDetector(
                onTap: () async {
                  await showDialog<bool>(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext dialogContext) {
                      return InvoiceDetailsDialog(
                        invoice: invoice,
                        onConfirm: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                        onCancel: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                      );
                    },
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColor.primary, width: 1),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: (invoice.image != null && invoice.image!.isNotEmpty)
                              ? Image.file(
                                  File(invoice.image!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColor.primary.withOpacity(0.8),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          padding: const EdgeInsets.only(left: 6, top: 3, bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      invoice.invoiceNo ?? 'No. N/A',
                                      style: TextStyle(
                                        color: AppColor.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      invoice.date ?? 'Date N/A',
                                      style: TextStyle(
                                        color: AppColor.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                style: IconButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () => _showInvoiceOptionsBottomSheet(context, invoice),
                                icon: Icon(Icons.more_vert, color: AppColor.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildGraphSection() {
    return ValueListenableBuilder<List<Invoice>>(
      valueListenable: invoicesNotifier,
      builder: (context, invoices, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Spending Analysis',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(height: 20),
              // Pass the invoices data to the BarChartSection
              SizedBox(
                width: double.infinity,
                height: 400,
                child: BarChartSection(invoices: invoices),
              ),
              const SizedBox(height: 20),
              Text(
                'This graph provides a visual overview over the past week. '
                'Future updates will allow for dynamic data input and more detailed financial insights.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'InvoyAI',
          style: TextStyle(fontStyle: FontStyle.normal, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        key: _fabKey,
        type: ExpandableFabType.up,
        distance: 80,
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.add),
          fabSize: ExpandableFabSize.regular,
        ),
        children: [
          FloatingActionButton.small(
            heroTag: null,
            child: const Icon(Icons.image),
            onPressed: () => pickImage(ImageSource.gallery),
          ),
          FloatingActionButton.small(
            heroTag: null,
            child: const Icon(Icons.camera_alt),
            onPressed: () => pickImage(ImageSource.camera),
          ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: currentIndex,
        builder: (context, value, child) {
          return CircleNavBar(
            activeIcons: [
              Icon(Icons.person, color: AppColor.white),
              Icon(Icons.home, color: AppColor.white),
              Icon(Icons.settings, color: AppColor.white),
            ],
            inactiveIcons: const [Text("Profile"), Text("Home"), Text("Settings")],
            color: Colors.white,
            circleColor: AppColor.primary,
            height: 60,
            circleWidth: 60,
            onTap: (index) {
              currentIndex.value = index;
            },
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
            cornerRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
            elevation: 10,
            circleGradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [AppColor.primary, AppColor.primary],
            ),
            activeIndex: value,
          );
        },
      ),
      body: Stack(
        children: [
          SafeArea(
            child: ValueListenableBuilder<int>(
              valueListenable: currentIndex,
              builder: (context, index, child) {
                return _pages[index];
              },
            ),
          ),
          ValueListenableBuilder<String?>(
            valueListenable: currentStatus,
            builder: (context, status, child) {
              if (status != null) {
                return Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          color: AppColor.primary,
                          backgroundColor: AppColor.primary.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(status, style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
