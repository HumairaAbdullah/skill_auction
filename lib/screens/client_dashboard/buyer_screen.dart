import 'package:flutter/material.dart';
import 'package:skill_auction/custom_widgets/custom_color.dart';
import 'package:skill_auction/custom_widgets/custom_textfield.dart';
import 'package:skill_auction/custom_widgets/purple_text.dart';
import 'package:skill_auction/custom_widgets/purpleblue_text.dart';
import 'package:skill_auction/custom_widgets/white_text.dart';
import 'package:skill_auction/screens/client_dashboard/buyer_profile.dart';

class BuyerScreen extends StatefulWidget {
  const BuyerScreen({super.key});

  @override
  State<BuyerScreen> createState() => _BuyerScreenState();
}

class _BuyerScreenState extends State<BuyerScreen> {
  final CustomColor customColor=CustomColor();
  final searchController=TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
       backgroundColor: Color(0xFFffd7f3),
        centerTitle: true,
       toolbarHeight:90,
        leading: Image.asset('assets/buyers skill auction.png'),
        actions: [

          InkWell( onTap: (){
            Navigator.push(context, MaterialPageRoute(builder: (context){
              return BuyerProfile();
            }));
          },
              child: CircleAvatar(
            radius: 35,
          ))
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PurpleblueText(data: 'Skill Auction'),
            Text('Need a Pro? Bid Smart, Hire Faster!',style: TextStyle(
              color: customColor.purpleText,
              fontSize: 12,
            ),),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomtextField(hint: 'search', label: PurpleText(data: 'Search'), obscure: false,
                  customcontroller: searchController,
              prefix: Icon(Icons.search),)
            ],

          ),
        ),
      ) ,
    );
  }
}
