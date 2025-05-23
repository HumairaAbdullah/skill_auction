import 'package:flutter/material.dart';
import 'package:skill_auction/custom_widgets/purpleblue_text.dart';

class BuyerScreen extends StatefulWidget {
  const BuyerScreen({super.key});

  @override
  State<BuyerScreen> createState() => _BuyerScreenState();
}

class _BuyerScreenState extends State<BuyerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PurpleblueText(data: 'Buyer Screen') ,
    );
  }
}
