import 'package:flutter/material.dart';
import 'package:skill_auction/custom_widgets/purple_text.dart';
import 'package:skill_auction/screens/seller_dashboard/gig_page.dart';
import 'package:skill_auction/screens/seller_dashboard/review_screen.dart';
import 'package:skill_auction/screens/seller_dashboard/seller_information.dart';
import 'package:skill_auction/screens/seller_dashboard/sellerskill_shows.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 200,
            title: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 70,
                  ),
                  Text('Seller Name'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star,color: Colors.amber,),
                      Text('5(100)'),
                    ],
                  )
                ],
              ),
            ),
            bottom: TabBar(
                labelColor: Color(0xFF0944c8),
                labelStyle: TextStyle(fontWeight: FontWeight.bold,
                ),
                tabs: [
                  PurpleText(data: 'ABout'),
                  PurpleText(data: 'Skills'),
                  PurpleText(data: 'Reviews'),

                ]
            ),
          ),
          body:  TabBarView(children: [
            SellerInformation(),
            SellerSkillShow(),
            ReviewScreen(),

          ]),
        ),
            ),
      );
  }
}
