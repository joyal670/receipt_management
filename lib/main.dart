import 'dart:convert';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receipt_management/features/home/data/model/invoice.dart';
import 'package:receipt_management/features/welcome/presentation/welcome_screen.dart';

import '../../../constants/app_color.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize FirebaseApp
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColor.primary,
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 30, fontStyle: FontStyle.italic),
          bodyMedium: TextStyle(fontSize: 16),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 4.0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        // >>> ADD THIS FLOATING ACTION BUTTON THEME <<<
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColor.primary, // Set the background color
          foregroundColor: Colors.white, // Set the icon/text color
          // You can also customize other properties like:
          // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          // elevation: 8.0,
        ),
      ),
    ),
  );
}

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   @override
//   Widget build(BuildContext context) => Scaffold(
//     appBar: AppBar(title: const Text('App.title')),
//     body: LlmChatView(
//       provider: FirebaseProvider(
//         // use FirebaseProvider and googleAI()
//         model: FirebaseAI.googleAI().generativeModel(model: 'gemini-2.0-flash'),
//       ),
//     ),
//   );
// }

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
