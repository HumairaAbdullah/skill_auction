import 'package:flutter/material.dart';
import 'package:skill_auction/custom_widgets/custom_color.dart';

class SplashScreen extends StatelessWidget {
   SplashScreen({super.key});
final CustomColor customColor=CustomColor();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:customColor.peach ,
      body: Center(
        child: Container(
          height: 200,
            width: 200,
            child: Image.asset('assets/splash logo.png')),
      ),
    );
  }
}
