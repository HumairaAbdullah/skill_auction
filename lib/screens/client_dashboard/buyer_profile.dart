import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:skill_auction/custom_widgets/custom_color.dart';
import 'package:skill_auction/custom_widgets/purpleblue_text.dart';
import 'package:skill_auction/custom_widgets/white_text.dart';
import 'package:skill_auction/screens/register_component/login_screen.dart';

class BuyerProfile extends StatefulWidget {
  const BuyerProfile({super.key});

  @override
  State<BuyerProfile> createState() => _BuyerProfileState();
}

class _BuyerProfileState extends State<BuyerProfile> {
final CustomColor customColor=CustomColor();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: PurpleblueText(data: 'Buyer Profile')),
          Container(
            color: customColor.purpleBlue,
            height: 50,
            width: double.infinity,
            child: TextButton(onPressed: (){
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (context){
              return LoginScreen();
             }));
            }, child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout,color: Colors.white,),
                WhiteText(data: 'Logout'),
              ],
            )),
          )
        ],
      ),
    );
  }
}
