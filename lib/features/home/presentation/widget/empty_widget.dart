import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmptyWidget extends StatelessWidget {
  const EmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/Animation6.json',
            width: 180,
            height: 180,
            animate: true,
            repeat: false,
          ),
          Text(
            "You don't have any invoices",
            style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            "Start a new scan from your camera or import photos",
            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.normal),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
