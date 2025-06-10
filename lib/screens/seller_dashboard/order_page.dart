import 'package:flutter/material.dart';
import 'package:skill_auction/custom_widgets/custom_color.dart';
import 'package:skill_auction/custom_widgets/purple_text.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final CustomColor customColor = CustomColor();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: customColor.peach,
        title: Text(
          'Orders Information',
          style: TextStyle(color: customColor.purpleText),
        ),
        centerTitle: true,
      ),
      body: Center(child: PurpleText(data: 'No Order Yet!')),
    );
  }
}
