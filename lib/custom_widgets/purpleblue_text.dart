import 'package:flutter/widgets.dart';

class PurpleblueText extends StatelessWidget {
  const PurpleblueText({super.key,required this.data,this.style});
final String data;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    return Text(data,style: TextStyle(color: Color(0xFF0944c8)));
  }
}

