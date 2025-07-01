import 'package:flutter/material.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:lottie/lottie.dart';

import '../../../constants/app_color.dart';
import '../../home/presentation/home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OnBoardingSlider(
        headerBackgroundColor: Colors.white,
        finishButtonText: 'Get Started',
        background: const [SizedBox.shrink(), SizedBox.shrink(), SizedBox.shrink()],
        totalPage: 3,
        speed: 1.8,
        controllerColor: AppColor.grey,
        onFinish: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        },
        pageBodies: [
          // Slide 1: AI Scanning & Extraction
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Lottie.asset('assets/Animation5.json', width: double.infinity, height: 200),
                const SizedBox(height: 20), // Added spacing
                const Text(
                  'AI-Powered Smart Scan',
                  style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center, // Center the title too
                ),
                const SizedBox(height: 10), // Added spacing
                const Text(
                  'Effortlessly scan receipts and invoices with advanced AI. Automatically extracts key details, saving you time and ensuring accuracy.',
                  style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.normal),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Slide 2: Organize & Export
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Lottie.asset('assets/Animation2.json', width: double.infinity, height: 200),
                const SizedBox(height: 20), // Added spacing
                const Text(
                  'Organize & Export with Ease',
                  style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10), // Added spacing
                const Text(
                  'Keep your financial documents neatly categorized and accessible. Export your data to Excel for simple record-keeping or sharing.',
                  style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.normal),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Slide 3: Smart Analysis & Graphical Insights
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Lottie.asset(
                  'assets/Animation3.json', // Ensure this Lottie file exists
                  width: double.infinity,
                  height: 200,
                ),
                const SizedBox(height: 20), // Added spacing
                const Text(
                  'Gain Smart Financial Insights',
                  style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10), // Added spacing
                const Text(
                  'Gain deep financial understanding from your digitized receipts. Explore interactive charts to pinpoint every expenditure and optimize your spending for the future.',
                  style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.normal),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
