import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_auction/custom_widgets/custom_snackbar.dart';
import 'package:skill_auction/custom_widgets/purple_text.dart';
import 'package:skill_auction/custom_widgets/purpleblue_text.dart';
import 'package:skill_auction/custom_widgets/white_text.dart';
import 'package:skill_auction/firebase_model/sellercrud.dart';
import 'package:skill_auction/screens/register_component/login_screen.dart';
import 'package:skill_auction/screens/seller_dashboard/gig_page.dart';
import 'package:skill_auction/screens/seller_dashboard/seller_information.dart';
import 'package:skill_auction/screens/seller_dashboard/skill_information.dart';

class SellerHome extends StatefulWidget {
  const SellerHome({super.key});

  @override
  State<SellerHome> createState() => _SellerHomeState();
}

class _SellerHomeState extends State<SellerHome> {

  @override
  void initState() {
    super.initState();
    // Fetch data when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SellerCrud>(context, listen: false).fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth=MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(9.0),
            child: Column(
              children: [
                Card(
                  child: ListTile(
      //               leading: Builder(
      //           builder: (context) =>
      //         InkWell(
      //         onTap: (){
      //   Scaffold.of(context).openDrawer();
      //   },
      //     child: CircleAvatar(
      //       radius: 40,
      //     ),
      //   )
      //
      // ),
                    title: PurpleblueText(data: 'HI, Seller'),
                    subtitle: PurpleText(
                      data: 'Welcome Back',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      
                    ),
                 trailing: Expanded(
                   child: CircleAvatar(
                     backgroundImage: AssetImage('assets/Skill Auction seller.png'),
                   ),
                 ),
                  ),
                ),
                SizedBox(height: 16),
                Text('Your Skills',
                    style: TextStyle(fontSize: 18, color: Color(0XFF8a2be1))),
                SizedBox(height: 10),
                Consumer<SellerCrud>(
                  builder: (context, sellerCrud, child) {
                    final skills = sellerCrud.skills;

                    if (skills.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text("No Skills Added Yet."),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: skills.length,
                      itemBuilder: (context, index) {
                        final skill = skills[index];
                        return Stack(
                            alignment: AlignmentDirectional.topCenter,
                            children: [
                              Card(
                                margin: EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: skill.imagePath.isNotEmpty &&
                                          skill.imagePath != "null"
                                      ? Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: MemoryImage(
                                                base64Decode(skill.imagePath),
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      : Icon(Icons.image_not_supported),
                                  title: Text(skill.skillTitle),
                                  subtitle: Text(
                                    skill.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text('Min Bid: \$${skill.minBid}'),
                                ),
                              ),
                              Positioned(
                                left: 250,
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => GigPage(
                                              isUpdating: true,
                                              skillToUpdate: skill,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: Icon(Icons.edit),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        try {
                                          await Provider.of<SellerCrud>(context,
                                                  listen: false)
                                              .deleteData(skill.skillId);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(CustomSnackbar.show(
                                                  content: WhiteText(
                                                      data:
                                                          'Skill Deleted Successfully')));
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(CustomSnackbar.show(
                                                  content: WhiteText(
                                                      data:
                                                          'Delete Failed: ${e.toString()}')));
                                        }
                                      },
                                      icon: Icon(Icons.delete),
                                    ),
                                  ],
                                ),
                              ),
                            ]);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PurpleblueText(data: 'Add Skill'),
            SizedBox(height: 8),
            FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GigPage()),
                ).then((_) {
                  // Refresh skills when returning from GigPage
                  Provider.of<SellerCrud>(context, listen: false).fetchData();
                });
              },
              child: Icon(Icons.add),
              backgroundColor: Color(0XFF8a2be1),
            ),
          ],
        ),
        floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
        drawer: Drawer(
          width: screenWidth * 0.7,
          backgroundColor: Colors.white,
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF0944c8)),
                child: Container(
                  width: double.infinity,
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: PurpleblueText(
                           data:  'A',
                            ),
                          ),
                        SizedBox(
                          height: 10,
                        ),
                       WhiteText(data: 'Seller Name'),



                      ],
                    ),
                  ),
                ),
              ),
              Divider(),
              TextButton(onPressed: (){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context){
                  return LoginScreen();
                }));
              }, child: Row(
                children: [Icon(Icons.logout),
                  PurpleblueText(data: 'LogOut')],
              ))
            ],
          ),
        ),
      ),
    );
  }
}
