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
        background: [SizedBox.shrink(), SizedBox.shrink(), SizedBox.shrink()],
        totalPage: 3,
        speed: 1.8,
        controllerColor: AppColor.grey,
        onFinish: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        },
        pageBodies: [
          // Slide 1 (Existing)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Lottie.asset('assets/Animation5.json', width: double.infinity, height: 200),
                Text(
                  'Smart Scan',
                  style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Effortlessly scan and crop documents with AI-powered precision.',
                  style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.normal),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Slide 2 (New Text)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Added for vertical centering
              children: <Widget>[
                Lottie.asset('assets/Animation2.json', width: double.infinity, height: 200),
                Text(
                  'Organize with Ease', // New Title
                  style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Categorize and manage your receipts instantly for quick access, anytime, anywhere.', // New Description
                  style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.normal),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Slide 3 (New Text - see below)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Added for vertical centering
              children: <Widget>[
                // Assuming you'll have a Lottie animation for this slide too, e.g., 'assets/Animation3.json'
                // If not, you can remove this or use a SizedBox.shrink()
                Lottie.asset(
                  'assets/Animation3.json',
                  width: double.infinity,
                  height: 200,
                ), // Placeholder for third animation
                Text(
                  'Gain Valuable Insights', // New Title
                  style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Track your spending and get smart insights from your organized receipts.', // New Description
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
