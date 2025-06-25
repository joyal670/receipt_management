import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'invoice.dart';
import 'invoice_view.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: ReceiptScanner()));

class ReceiptScanner extends StatefulWidget {
  const ReceiptScanner({super.key});

  @override
  State<ReceiptScanner> createState() => _ReceiptScannerState();
}

class _ReceiptScannerState extends State<ReceiptScanner> {
  File? _image;
  final picker = ImagePicker();

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
      extractAndParse(_image!);
    }
  }

  void extractAndParse(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final recognizedText = await textRecognizer.processImage(inputImage);

    final fullText = recognizedText.text;
    print("\n--- FULL OCR TEXT START ---");
    print(fullText);
    print("--- FULL OCR TEXT END ---\n");

    Invoice invoice = Invoice(
      invoiceNo: '',
      date: '',
      billTo: Contact(name: '', address: '', mobile: ''),
      billFrom: Contact(name: '', address: '', mobile: ''),
      items: [],
      grandTotal: '',
    );

    final lines = fullText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    // --- Extract non-table data using line-based parsing ---
    final invMatch = RegExp(r'INVOICE\s*NO[:\s]+(\d+)', caseSensitive: false).firstMatch(fullText);
    if (invMatch != null) invoice.invoiceNo = invMatch.group(1)!;

    final dateMatch = RegExp(r'DATE[:\s]+(\d{2}/\d{2}/\d{4})').firstMatch(fullText);
    if (dateMatch != null) invoice.date = dateMatch.group(1)!;

    final billToStart = lines.indexWhere((line) => line.toLowerCase().contains('bill to'));
    if (billToStart != -1) {
      final billToLines = lines.sublist(billToStart + 1);
      for (final line in billToLines) {
        if (line.toLowerCase().startsWith('from')) break;
        if (line.toLowerCase().startsWith('name:')) {
          invoice.billTo.name = line
              .replaceFirst(RegExp(r'name[:\s]*', caseSensitive: false), '')
              .trim();
        } else if (line.toLowerCase().startsWith('address:')) {
          invoice.billTo.address = line
              .replaceFirst(RegExp(r'address[:\s]*', caseSensitive: false), '')
              .trim();
        } else if (line.toLowerCase().contains('mobile')) {
          invoice.billTo.mobile = line
              .replaceFirst(RegExp(r'mobile\s*no\.?\s*:?\s*', caseSensitive: false), '')
              .trim();
        }
      }
    }

    final fromStart = lines.indexWhere((line) => line.toLowerCase().startsWith('from'));
    if (fromStart != -1) {
      final fromLines = lines.sublist(fromStart + 1);
      String company = '';
      String name = '';
      String address = '';
      String mobileValue = '';

      for (final line in fromLines) {
        final lineLower = line.toLowerCase();
        if (lineLower.startsWith("no") ||
            lineLower.startsWith("description") ||
            lineLower.startsWith("months") ||
            lineLower.startsWith("rate") ||
            lineLower.startsWith("total") ||
            lineLower.startsWith("grand total")) {
          break;
        }

        if (lineLower.startsWith('company name:')) {
          company = line
              .replaceFirst(RegExp(r'company name[:\s]*', caseSensitive: false), '')
              .trim();
        } else if (lineLower.startsWith('name:')) {
          name = line.replaceFirst(RegExp(r'name[:\s]*', caseSensitive: false), '').trim();
        } else if (lineLower.startsWith('address:')) {
          address = line.replaceFirst(RegExp(r'address[:\s]*', caseSensitive: false), '').trim();
        } else if (lineLower.contains('mobile')) {
          mobileValue = line
              .replaceFirst(RegExp(r'mobile\s*no\.?\s*:?\s*', caseSensitive: false), '')
              .trim();
        }
      }
      print("Debug: Bill From mobileValue before assignment: '$mobileValue'");
      invoice.billFrom = Contact(name: "$company - $name", address: address, mobile: mobileValue);
    }

    final grandTotalLabelMatch = RegExp(
      r'GRAND TOTAL\s*\(INR\)',
      caseSensitive: false,
    ).firstMatch(fullText);
    if (grandTotalLabelMatch != null) {
      final finalGrandTotalMatch = RegExp(
        r'GRAND TOTAL\s*\(INR\)\s*([\s\S]*?)(\d+)\s*(?:AUTHORIZED SIGNATURE|$)',
        caseSensitive: false,
      ).firstMatch(fullText);
      if (finalGrandTotalMatch != null && finalGrandTotalMatch.group(2) != null) {
        invoice.grandTotal = finalGrandTotalMatch.group(2)!;
        print("Grand Total extracted: ${invoice.grandTotal} (via combined regex)");
      } else {
        final grandTotalNumMatch = RegExp(
          r'(\d+)\s*AUTHORIZED SIGNATURE',
          caseSensitive: false,
        ).firstMatch(fullText);
        if (grandTotalNumMatch != null) {
          invoice.grandTotal = grandTotalNumMatch.group(1)!;
          print("Grand Total extracted: ${invoice.grandTotal} (via signature regex)");
        } else {
          print("Grand Total not found even with combined regex and signature fallback.");
        }
      }
    } else {
      print("Grand Total label 'GRAND TOTAL (INR)' not found in full text for main extraction.");
    }

    invoice.items = _parseTableFromBlocks(recognizedText.blocks);

    await textRecognizer.close();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceView(invoice: invoice, onExport: _exportToExcel),
      ),
    );
  }

  List<InvoiceItem> _parseTableFromBlocks(List<TextBlock> blocks) {
    final List<InvoiceItem> items = [];
    Map<String, double> headerXPositions = {};
    List<double> headerYCoords = [];

    double tableDataStartY = -1;
    double tableDataEndY = -1;

    print("\n--- HEADER DETECTION IN BLOCKS (Phase 1: Collect Candidates) ---");
    for (final block in blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final text = element.text.toLowerCase().trim();
          final xPos = element.boundingBox.left;
          final yPos = element.boundingBox.top;

          if (['no', 'description', 'months', 'rate', 'total'].contains(text)) {
            if (!headerXPositions.containsKey(text) ||
                (headerXPositions.containsKey(text) &&
                    (yPos - (headerYCoords.isNotEmpty ? headerYCoords.first : yPos)).abs() > 50)) {
              if (text == 'total' && headerXPositions.containsKey('total')) {
                if (headerYCoords.isNotEmpty &&
                    (yPos - headerYCoords[0]).abs() <
                        (headerXPositions['total']! - headerYCoords[0]).abs()) {
                  headerXPositions[text] = xPos;
                }
              } else {
                headerXPositions[text] = xPos;
              }
            }
            headerYCoords.add(yPos);
            print("Candidate header keyword '$text' at X:$xPos, Y:$yPos");
          }
        }
      }
    }

    if (headerYCoords.isEmpty) {
      print("No header keywords found at all.");
      return [];
    }

    headerYCoords.sort();
    double predominantHeaderY = headerYCoords.first;
    int maxCount = 1;
    int currentCount = 1;

    for (int i = 1; i < headerYCoords.length; i++) {
      if ((headerYCoords[i] - headerYCoords[i - 1]).abs() < 10) {
        currentCount++;
      } else {
        currentCount = 1;
      }
      if (currentCount > maxCount) {
        maxCount = currentCount;
        predominantHeaderY = headerYCoords[i];
      }
    }

    Map<String, double> finalHeaderXPositions = {};
    double minHeaderY = double.infinity;
    double maxHeaderY = -double.infinity;

    print("\n--- HEADER DETECTION IN BLOCKS (Phase 2: Filter by Predominant Y) ---");
    for (final block in blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final text = element.text.toLowerCase().trim();
          final xPos = element.boundingBox.left;
          final yPos = element.boundingBox.top;

          if (['no', 'description', 'months', 'rate', 'total'].contains(text) &&
              (yPos - predominantHeaderY).abs() < 10) {
            finalHeaderXPositions[text] = xPos;
            minHeaderY = min(minHeaderY, yPos);
            maxHeaderY = max(maxHeaderY, yPos + element.boundingBox.height);
            print("Confirmed header keyword '$text' at X:$xPos, Y:$yPos");
          }
        }
      }
    }

    headerXPositions = finalHeaderXPositions;

    if (headerXPositions.length < 5) {
      print(
        "Could not find all table headers after Y-clustering. Found: ${headerXPositions.keys}. Aborting table parsing.",
      );
      return [];
    }

    final sortedHeaders = headerXPositions.keys.toList()
      ..sort((a, b) => headerXPositions[a]!.compareTo(headerXPositions[b]!));

    print("Detected header column order and X positions (final): $sortedHeaders");
    print("Header Y-range (final): $minHeaderY to $maxHeaderY");

    tableDataStartY = maxHeaderY + 5;

    print("\n--- DETERMINING TABLE END Y ---");
    double grandTotalLabelY = -1;
    for (final block in blocks) {
      for (final line in block.lines) {
        print("Checking line for end marker: '${line.text}' at Y:${line.boundingBox.top}");
        if (line.text.toLowerCase().contains('grand total')) {
          grandTotalLabelY = line.boundingBox.top;
          print("Found 'GRAND TOTAL' label at Y:$grandTotalLabelY");
          break;
        }
      }
      if (grandTotalLabelY != -1) break;
    }

    if (grandTotalLabelY != -1) {
      tableDataEndY = grandTotalLabelY - 5;
      print("Expected table data Y-range: $tableDataStartY to $tableDataEndY");
    } else {
      double authSignatureY = -1;
      for (final block in blocks) {
        for (final line in block.lines) {
          if (line.text.toLowerCase().contains('authorized signature')) {
            authSignatureY = line.boundingBox.top;
            print("Found 'AUTHORIZED SIGNATURE' at Y:$authSignatureY (fallback for table end)");
            break;
          }
        }
        if (authSignatureY != -1) break;
      }

      if (authSignatureY != -1) {
        tableDataEndY = authSignatureY - 5;
        print("Expected table data Y-range (fallback): $tableDataStartY to $tableDataEndY");
      } else {
        print(
          "Warning: Neither 'GRAND TOTAL' nor 'AUTHORIZED SIGNATURE' found to define table end. Setting tableDataEndY to image bottom (effectively infinity).",
        );
        tableDataEndY = double.infinity;
      }
    }

    Map<String, List<String>> columnData = {
      'no': [],
      'description': [],
      'months': [],
      'rate': [],
      'total': [],
    };

    print("\n--- COLLECTING TABLE DATA ELEMENTS ---");
    for (final block in blocks) {
      for (final line in block.lines) {
        final lineYTop = line.boundingBox.top;
        final lineYBottom = line.boundingBox.top + line.boundingBox.height;

        if (lineYTop < tableDataStartY - 5 || lineYBottom > tableDataEndY + 5) {
          continue;
        }

        final lineTextLower = line.text.toLowerCase().trim();
        if ([
          'no',
          'description',
          'months',
          'rate',
          'total',
          'grand total',
          'authorized signature',
          'invoice',
          'date',
          'bill to',
          'from',
          'name',
          'address',
          'mobile',
          'company name',
          'inr',
        ].any((keyword) => lineTextLower.contains(keyword))) {
          continue;
        }

        for (final element in line.elements) {
          final elementX = element.boundingBox.left;
          final elementText = element.text.trim();

          if (elementText.isEmpty) continue;

          String? assignedColumn;
          for (final headerKey in sortedHeaders) {
            final headerX = headerXPositions[headerKey]!;
            double columnLeftBound = headerX - 30;
            double columnRightBound = headerX + 150;

            if (headerKey == 'no') {
              columnRightBound = headerX + 60;
            } else if (headerKey == 'description') {
              columnLeftBound = headerX - 50;
              columnRightBound = headerX + 250;
            } else if (headerKey == 'months') {
              columnRightBound = headerX + 70;
            } else if (headerKey == 'rate') {
              columnRightBound = headerX + 70;
            } else if (headerKey == 'total') {
              columnRightBound = headerX + 100;
            }

            final elementCenter = elementX + element.boundingBox.width / 2;

            if (elementCenter >= columnLeftBound && elementCenter < columnRightBound) {
              assignedColumn = headerKey;
              break;
            }
          }

          if (assignedColumn != null) {
            print(
              "Assigning element '$elementText' (X:$elementX, Y:${element.boundingBox.top}) to column '$assignedColumn'",
            );
            columnData[assignedColumn]!.add(elementText);
          } else {
            print(
              "Element '$elementText' (X:$elementX, Y:${element.boundingBox.top}) NOT assigned to a column. Outside X-bounds.",
            );
          }
        }
      }
    }

    print("Collected column data: $columnData");

    final List<String> noList = columnData['no']!;
    final List<String> descriptionList = columnData['description']!;
    final List<String> monthsList = columnData['months']!;
    final List<String> rateList = columnData['rate']!;
    final List<String> totalList = columnData['total']!;

    if (noList.isEmpty ||
        noList.length != monthsList.length ||
        noList.length != rateList.length ||
        noList.length != totalList.length ||
        descriptionList.length != (noList.length * 2)) {
      print(
        "WARNING: Inconsistent column data lengths for table reconstruction. Expected ${noList.length} items.",
      );
      print(
        "No: ${noList.length}, Desc: ${descriptionList.length}, Months: ${monthsList.length}, Rate: ${rateList.length}, Total: ${totalList.length}",
      );
      if (noList.isEmpty) return [];
    }

    for (int i = 0; i < noList.length; i++) {
      String description = '';
      if ((i * 2 + 1) < descriptionList.length) {
        description = "${descriptionList[i * 2]} ${descriptionList[i * 2 + 1]}";
      } else if (i * 2 < descriptionList.length) {
        description = descriptionList[i * 2];
      }

      items.add(
        InvoiceItem(
          no: int.tryParse(noList[i]) ?? 0,
          description: description.trim(),
          rate: rateList[i],
          total: totalList[i],
        ),
      );
    }

    print("Parsed Items: ${items.map((e) => e.description).join(', ')}");
    return items;
  }

  Future<void> _exportToExcel(Invoice invoice) async {
    final excel = Excel.createExcel();
    final sheet = excel['Invoice Data'];

    sheet.appendRow([TextCellValue('Invoice Details')]);
    sheet.appendRow([TextCellValue('Invoice No:'), TextCellValue(invoice.invoiceNo)]);
    sheet.appendRow([TextCellValue('Date:'), TextCellValue(invoice.date)]);
    sheet.appendRow([]);

    sheet.appendRow([TextCellValue('Bill To')]);
    sheet.appendRow([TextCellValue('Name:'), TextCellValue(invoice.billTo.name)]);
    sheet.appendRow([TextCellValue('Address:'), TextCellValue(invoice.billTo.address)]);
    sheet.appendRow([TextCellValue('Mobile:'), TextCellValue(invoice.billTo.mobile)]);
    sheet.appendRow([]);

    sheet.appendRow([TextCellValue('Bill From')]);
    sheet.appendRow([TextCellValue('Company/Name:'), TextCellValue(invoice.billFrom.name)]);
    sheet.appendRow([TextCellValue('Address:'), TextCellValue(invoice.billFrom.address)]);
    sheet.appendRow([TextCellValue('Mobile:'), TextCellValue(invoice.billFrom.mobile)]);
    sheet.appendRow([]);

    sheet.appendRow([
      TextCellValue('No'),
      TextCellValue('Description'),
      TextCellValue('Months'), // Placeholder for Months
      TextCellValue('Rate'),
      TextCellValue('Total'),
    ]);

    for (var item in invoice.items) {
      sheet.appendRow([
        IntCellValue(item.no),
        TextCellValue(item.description),
        TextCellValue(''), // Placeholder for Months
        TextCellValue(item.rate),
        TextCellValue(item.total),
      ]);
    }
    sheet.appendRow([]);

    sheet.appendRow([
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('GRAND TOTAL (INR)'),
      TextCellValue(invoice.grandTotal),
    ]);

    try {
      {
        // Mobile/Desktop platforms
        Directory? baseDirectory;

        // --- PLATFORM-SPECIFIC PERMISSION AND DIRECTORY HANDLING ---
        if (Platform.isAndroid) {
          final AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
          final int sdkInt = androidInfo.version.sdkInt;

          if (sdkInt >= 30) {
            // Android 11 (API 30) and above
            var status = await Permission.manageExternalStorage.status;
            print("Debug: Initial MANAGE_EXTERNAL_STORAGE Status: $status");

            if (!status.isGranted) {
              bool userAgreedToRequest = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Permission Needed: All Files Access"),
                    content: const Text(
                      "To save the Excel file directly to your device's Downloads folder, this app requires 'All Files Access' permission. Please grant it in the next screen.",
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text("Not Now"),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      TextButton(
                        child: const Text("Continue"),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  );
                },
              );

              if (userAgreedToRequest == true) {
                status = await Permission.manageExternalStorage
                    .request(); // This often opens a separate settings screen
                print("Debug: After Request MANAGE_EXTERNAL_STORAGE Status: $status");
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saving cancelled: Permission not granted.')),
                );
                return; // User declined explanation
              }
            }

            if (!status.isGranted) {
              // If permission is still not granted after request (user denied on settings screen)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All files access permission denied. Cannot save to Downloads.'),
                  action: SnackBarAction(
                    label: 'Go to Settings',
                    onPressed: () {
                      openAppSettings(); // Open app settings for user to manually enable
                    },
                  ),
                ),
              );
              return; // Exit if permission is not granted
            }
            baseDirectory =
                await getDownloadsDirectory(); // For Android, this should point to public Downloads
          } else {
            // Android 10 (API 29) and below
            var status = await Permission.storage.status;
            print("Debug: Initial Storage Permission Status (Android < 11): $status");

            if (!status.isGranted) {
              bool userAgreedToRequest = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Storage Permission Needed"),
                    content: const Text(
                      "To save the Excel file to your Downloads folder, this app needs storage access. Please grant the permission when prompted.",
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text("Not Now"),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      TextButton(
                        child: const Text("Continue"),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  );
                },
              );

              if (userAgreedToRequest == true) {
                status = await Permission.storage.request();
                print("Debug: After Request Storage Permission Status (Android < 11): $status");
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saving cancelled: Permission not granted.')),
                );
                return; // User declined explanation
              }
            }

            if (!status.isGranted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Storage permission denied. Cannot save to Downloads.'),
                  action: SnackBarAction(
                    label: 'Go to Settings',
                    onPressed: () {
                      openAppSettings();
                    },
                  ),
                ),
              );
              return; // Exit if permission not granted
            }
            baseDirectory =
                await getDownloadsDirectory(); // For Android, this should point to public Downloads
          }
        } else if (Platform.isIOS) {
          // On iOS, getDownloadsDirectory() maps to the app's sandboxed Documents directory.
          // We'll create a "Downloads" sub-folder within that.
          baseDirectory = await getDownloadsDirectory();
          if (baseDirectory != null) {
            // Define the specific sub-directory where you want to save the file
            // Let's create 'Invoices' or 'ExcelExports' within the app's Documents folder.
            final Directory targetDirectory = Directory('${baseDirectory.path}/ExcelExports');

            // Check if the directory exists, if not, create it
            if (!(await targetDirectory.exists())) {
              await targetDirectory.create(recursive: true);
              print("Debug: Created directory: ${targetDirectory.path}");
            }
            baseDirectory = targetDirectory; // Use this new directory as the base
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'On iOS, file saved to app documents. Look for "ExcelExports" folder.',
                ),
              ),
            );
          }
        } else {
          // For other platforms (e.g., Desktop), getDownloadsDirectory() should work directly.
          baseDirectory = await getDownloadsDirectory();
        }

        // --- Proceed with saving if baseDirectory is determined and exists ---
        if (baseDirectory != null) {
          final String filePath = '${baseDirectory.path}/Invoice_${invoice.invoiceNo}.xlsx';
          final File file = File(filePath);

          final List<int>? bytes = excel.save();
          if (bytes != null) {
            await file.writeAsBytes(bytes);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Invoice data exported to Excel at $filePath')));
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed to generate Excel bytes for saving.')));
          }
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not determine a valid save directory.')));
        }
      }
    } catch (e) {
      print('Error exporting to Excel: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting to Excel: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ElevatedButton(onPressed: pickImage, child: const Text("Pick Receipt Image")),
        ),
      ),
    );
  }
}
