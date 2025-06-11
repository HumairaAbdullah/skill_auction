import 'package:flutter/material.dart';
import 'package:skill_auction/custom_widgets/custom_color.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final CustomColor customColor=CustomColor();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: customColor.white,
      // appBar: AppBar(
      //   backgroundColor: customColor.peach,
      //   centerTitle: true,
      //   title: Text('All Reviews',style: TextStyle(
      //     color: customColor.purpleBlue,
      //   ),),
      // ),
      body: Center(child: Text('No Reviews yet!',style: TextStyle(
        color: customColor.purpleText
      ),)),
    );
  }
}
