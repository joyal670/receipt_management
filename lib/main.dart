import 'dart:convert';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receipt_management/invoice.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize FirebaseApp
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // final model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
  //
  // // Provide a prompt that contains text
  // final prompt = [Content.text('Write a story about a magic backpack.')];
  //
  // // To generate text output, call generateContent with the text input
  // final response = await model.generateContent(prompt);
  // print(response.text);
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: ReceiptScanner()));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('App.title')),
    body: LlmChatView(
      provider: FirebaseProvider(
        // use FirebaseProvider and googleAI()
        model: FirebaseAI.googleAI().generativeModel(model: 'gemini-2.0-flash'),
      ),
    ),
  );
}

class ReceiptScanner extends StatefulWidget {
  const ReceiptScanner({super.key});

  @override
  State<ReceiptScanner> createState() => _ReceiptScannerState();
}

class _ReceiptScannerState extends State<ReceiptScanner> {
  final picker = ImagePicker();

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final inputImage = await File(pickedFile.path).readAsBytes();

      // Provide a text prompt to include with the image
      final prompt = TextPart("What's in the picture?");
      // Prepare images for input
      final imagePart = InlineDataPart('image/jpeg', inputImage);

      // To generate text output, call generateContent with the text and image
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: invoiceSchema,
        ),
      );
      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);
      print(response.text);
      final Map<String, dynamic> jsonMap = jsonDecode(response.text!);
      final result = Invoice.fromJson(jsonMap);
      print(result);
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
