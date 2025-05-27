import 'package:flutter/material.dart';
import 'package:skill_auction/custom_widgets/purple_text.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: PurpleText(data: 'Live Bidding will show here ')),
    );
  }
}
