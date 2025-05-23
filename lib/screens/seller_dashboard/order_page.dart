import 'package:flutter/material.dart';
import 'package:skill_auction/custom_widgets/purple_text.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: PurpleText(data: 'order page')),
    );
  }
}
