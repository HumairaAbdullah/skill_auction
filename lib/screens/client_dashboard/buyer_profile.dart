import 'package:flutter/material.dart';
import 'package:skill_auction/custom_widgets/purpleblue_text.dart';

class BuyerProfile extends StatefulWidget {
  const BuyerProfile({super.key});

  @override
  State<BuyerProfile> createState() => _BuyerProfileState();
}

class _BuyerProfileState extends State<BuyerProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: PurpleblueText(data: 'Buyer Profile')),
    );
  }
}
