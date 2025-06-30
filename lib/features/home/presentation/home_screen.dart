import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_color.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ValueNotifier<int> currentIndex = ValueNotifier(1);

  @override
  void dispose() {
    currentIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: currentIndex,
        builder: (context, value, child) {
          return CircleNavBar(
            activeIcons: [
              Icon(Icons.person, color: AppColor.white),
              Icon(Icons.home, color: AppColor.white),
              Icon(Icons.favorite, color: AppColor.white),
            ],
            inactiveIcons: const [Text("Create"), Text("Home"), Text("Settings")],
            color: Colors.white,
            circleColor: Colors.blue,
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
    );
  }
}
