import 'package:flutter/material.dart';

class WhiteText extends StatelessWidget {
  const WhiteText({super.key,required this.data});
 final String data;
  @override
  Widget build(BuildContext context) {
    return Text(data,style: TextStyle(color: Color(0xFFffffff)));
  }
}
