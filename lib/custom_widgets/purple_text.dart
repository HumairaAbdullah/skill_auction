import 'package:flutter/material.dart';

class PurpleText extends StatelessWidget {
  const PurpleText({super.key,required this.data,this.style});
 final String data;
 final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    return Text(data,
      style: TextStyle(color: Color(0XFF8a2be1)),);
  }
}
