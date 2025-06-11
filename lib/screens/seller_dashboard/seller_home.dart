import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_auction/custom_widgets/custom_color.dart';
import 'package:skill_auction/custom_widgets/custom_snackbar.dart';
import 'package:skill_auction/custom_widgets/purple_text.dart';
import 'package:skill_auction/custom_widgets/purpleblue_text.dart';
import 'package:skill_auction/custom_widgets/white_text.dart';
import 'package:skill_auction/firebase_model/sellercrud.dart';
import 'package:skill_auction/firebase_model/skill_model.dart';
import 'package:skill_auction/screens/register_component/login_screen.dart';
import 'package:skill_auction/screens/seller_dashboard/gig_page.dart';
import 'package:skill_auction/screens/seller_dashboard/order_page.dart';
import 'package:skill_auction/screens/seller_dashboard/profile_page.dart';
import 'package:skill_auction/screens/seller_dashboard/review_screen.dart';
import 'package:skill_auction/screens/seller_dashboard/seller_information.dart';
import 'package:skill_auction/screens/seller_dashboard/sellerprofile_provider.dart';
import 'package:skill_auction/screens/seller_dashboard/sellerskill_shows.dart';
import 'package:skill_auction/screens/seller_dashboard/skill_information.dart';

class SellerHome extends StatefulWidget {
  const SellerHome({super.key});

  @override
  State<SellerHome> createState() => _SellerHomeState();
}

class _SellerHomeState extends State<SellerHome> {
  final customColor = CustomColor();
  int productCount=0;
  bool isLoading = true;
  String? errorMessage;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<void> fetchDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      final snapshot = await _database
          .child('sellerskills')
          .orderByChild('sellerId')
          .equalTo(currentUser.uid)
          .once();

      setState(() {
        productCount = snapshot.snapshot.children.length;
      });

      if (snapshot.snapshot.exists) {
        // Convert the snapshot to a list of ProductModel objects
        final products = snapshot.snapshot.children.map((child) {
          return SkillModel.fromMap(child.value as Map<dynamic, dynamic>);
        }).toList();

        setState(() {
          productCount = products.length;
        });
      } else {
        setState(() {
          productCount = 0;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch products: ${e.toString()}';
        productCount = 0;
      });
      debugPrint(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }



  @override
  void initState() {
    super.initState();
    fetchDashboardData();
    // Fetch data when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SellerCrud>(context, listen: false).fetchData();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<SellerProfileProvider>(context, listen: false)
            .fetchSellerInfo();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(9.0),
            child: Column(
              children: [
                Card(
                  color: customColor.peach,
                  child: ListTile(
                    title: Consumer<SellerProfileProvider>(
                        builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final sellerInfoList = provider.currentUser;
                      if (sellerInfoList.isEmpty) {
                        return Center(
                            child: const PurpleblueText(
                                data: 'No user data available'));
                      }

                      // Get the first user (assuming there's only one matching user)
                      final sellerInfo = sellerInfoList.first;
                      return Row(
                        children: [
                          PurpleblueText(data: 'Hi, ${sellerInfo.firstname}'),
                          PurpleblueText(data: ' ${sellerInfo.lastName}'),
                        ],
                      );
                    }),
                    subtitle: PurpleText(
                      data: 'Welcome Back',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Container(
                        child:
                            Image.asset('assets/buyers skill auction.png'),

                    ),
                  ),
                ),
                SizedBox(height: 25),
                Row(
                  children: [
                    Text(
                      'DashBoard Overview',
                      style: TextStyle(
                        color: customColor.purpleBlue,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return SellerSkillShow();
                            }));
                          },
                          child: Card(
                            color: customColor.peach,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: 10),
                                Icon(
                                  Icons.category,
                                  size: 40,
                                ),
                                SizedBox(height: 15),
                                // Show loading indicator or product count

                                Text('${productCount}',style: TextStyle(
                                  color: customColor.purpleBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20
                                ),),
                                SizedBox(height: 15,),
                                PurpleText(
                                  data: 'Active Skills',
                                ),
                                SizedBox(height: 10,),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return OrderPage();
                            }));
                          },
                          child: Card(
                            color: customColor.peach,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: 10),
                                Icon(
                                  Icons.receipt_long,
                                  size: 40,
                                ),
                                SizedBox(height:15),
                                Text('0',style: TextStyle(
                                    color: customColor.purpleBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20
                                ),),
                                SizedBox(height: 15,),
                                PurpleText(
                                  data: 'Completed Orders',
                                ),
                                SizedBox(height: 10,),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        child: Card(
                          color: customColor.peach,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: 10),
                              Icon(
                                Icons.monetization_on_rounded,
                                size: 40,
                              ),
                              SizedBox(height:15),
                              Text('0',style: TextStyle(
                                  color: customColor.purpleBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20
                              ),),
                              SizedBox(height: 15,),
                              PurpleText(
                                data: ' Total Earnings',
                              ),
                              SizedBox(height: 10,),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return ProfilePage();
                            }));
                          },
                          child: Card(
                            color: customColor.peach,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: 10),
                                Icon(
                                  Icons.star,
                                  size:40,
                                ),
                                SizedBox(height:15),
                                Text('0',style: TextStyle(
                                    color: customColor.purpleBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20
                                ),),
                                SizedBox(height: 15,),
                                PurpleText(
                                  data: 'Rating',
                                ),
                                SizedBox(height: 10,),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      width: 7,
                    ),
                    Text(
                      'Earnings',
                      style: TextStyle(
                        color: customColor.purpleBlue,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Card(
                  color: customColor.peach,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PurpleText(data: 'Available for Withdrawal'),
                                SizedBox(height: 5,),
                                Text( ' 0\$',style: TextStyle(
                                  color: customColor.purpleBlue,
                                  fontWeight: FontWeight.bold,
                                ),),
                                SizedBox(
                                  height: 25,
                                ),
                                PurpleText(data: 'Avg.Bid Price'),
                                SizedBox(height: 5,),
                                Text( ' 80\$',style: TextStyle(
                                  color: customColor.purpleBlue,
                                  fontWeight: FontWeight.bold,
                                ),),
                                SizedBox(
                                  height: 25,
                                ),
                                PurpleText(data: 'Payment Being Cleared '),
                                SizedBox(height: 5,),
                                Text( ' 0\$',style: TextStyle(
                                  color: customColor.purpleBlue,
                                  fontWeight: FontWeight.bold,
                                ),),
                              ],
                            ),
                            Divider(
                              color: customColor.purpleBlue,
                              thickness: 10,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PurpleText(data: 'Earnings in Month'),
                                SizedBox(height: 5,),
                                Text( ' 0\$',style: TextStyle(
                                  color: customColor.purpleBlue,
                                  fontWeight: FontWeight.bold,
                                ),),
                                SizedBox(
                                  height: 25,
                                ),
                                PurpleText(data: 'Active Orders'),
                                SizedBox(height: 5,),
                                Text( ' 0\$',style: TextStyle(
                                  color: customColor.purpleBlue,
                                  fontWeight: FontWeight.bold,
                                ),),
                                SizedBox(
                                  height: 25,
                                ),
                                PurpleText(data: 'Cancelled Orders'),
                                SizedBox(height: 5,),
                                Text( ' 0\$',style: TextStyle(
                                  color: customColor.purpleBlue,
                                  fontWeight: FontWeight.bold,
                                ),),
                              ],
                            ),
                            SizedBox(
                              height: 20,
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Text('Your Skills',
// style: TextStyle(fontSize: 18, color: Color(0XFF8a2be1))),
// SizedBox(height: 10),
// Consumer<SellerCrud>(
// builder: (context, sellerCrud, child) {
// final skills = sellerCrud.skills;
//
// if (skills.isEmpty) {
// return Center(
// child: Padding(
// padding: const EdgeInsets.all(20.0),
// child: Text("No Skills Added Yet."),
// ),
// );
// }
//
// return ListView.builder(
// shrinkWrap: true,
// physics: NeverScrollableScrollPhysics(),
// itemCount: skills.length,
// itemBuilder: (context, index) {
// final skill = skills[index];
// return Stack(
// alignment: AlignmentDirectional.topCenter,
// children: [
// Card(
// margin: EdgeInsets.symmetric(vertical: 6),
// child: ListTile(
// leading: skill.imagePath.isNotEmpty &&
// skill.imagePath != "null"
// ? Container(
// width: 50,
// height: 50,
// decoration: BoxDecoration(
// image: DecorationImage(
// image: MemoryImage(
// base64Decode(skill.imagePath),
// ),
// fit: BoxFit.cover,
// ),
// ),
// )
//     : Icon(Icons.image_not_supported),
// title: Text(skill.skillTitle),
// subtitle: Text(
// skill.description,
// maxLines: 2,
// overflow: TextOverflow.ellipsis,
// ),
// trailing: Text('Min Bid: \$${skill.minBid}'),
// ),
// ),
// Positioned(
// left: 250,
// child: Row(
// children: [
// IconButton(
// onPressed: () {
// Navigator.push(
// context,
// MaterialPageRoute(
// builder: (context) => GigPage(
// isUpdating: true,
// skillToUpdate: skill,
// ),
// ),
// );
// },
// icon: Icon(Icons.edit),
// ),
// IconButton(
// onPressed: () async {
// try {
// await Provider.of<SellerCrud>(context,
// listen: false)
//     .deleteData(skill.skillId);
// ScaffoldMessenger.of(context)
//     .showSnackBar(CustomSnackbar.show(
// content: WhiteText(
// data:
// 'Skill Deleted Successfully')));
// } catch (e) {
// ScaffoldMessenger.of(context)
//     .showSnackBar(CustomSnackbar.show(
// content: WhiteText(
// data:
// 'Delete Failed: ${e.toString()}')));
// }
// },
// icon: Icon(Icons.delete),
// ),
// ],
// ),
// ),
// ]);
// },
// );
// },
// ),

// floatingActionButton: Column(
// mainAxisAlignment: MainAxisAlignment.end,
// children: [
// PurpleblueText(data: 'Add Skill'),
// SizedBox(height: 8),
// FloatingActionButton(
// onPressed: () {
// Navigator.push(
// context,
// MaterialPageRoute(builder: (context) => GigPage()),
// ).then((_) {
// // Refresh skills when returning from GigPage
// Provider.of<SellerCrud>(context, listen: false).fetchData();
// });
// },
// child: Icon(Icons.add),
// backgroundColor: Color(0XFF8a2be1),
// ),
// ],
// ),
// floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
// drawer: Drawer(
// width: screenWidth * 0.7,
// backgroundColor: Colors.white,
// child: Column(
// children: [
// DrawerHeader(
// decoration: BoxDecoration(color: Color(0xFF0944c8)),
// child: Container(
// width: double.infinity,
// child: Center(
// child: Column(
// crossAxisAlignment: CrossAxisAlignment.center,
// mainAxisAlignment: MainAxisAlignment.center,
// children: [
// CircleAvatar(
// radius: 30,
// backgroundColor: Colors.white,
// child: PurpleblueText(
// data:  'A',
// ),
// ),
// SizedBox(
// height: 10,
// ),
// WhiteText(data: 'Seller Name'),
//
//
//
// ],
// ),
// ),
// ),
// ),
// Divider(),
// TextButton(onPressed: (){
// Navigator.pushReplacement(context, MaterialPageRoute(builder: (context){
// return LoginScreen();
// }));
// }, child: Row(
// children: [Icon(Icons.logout),
// PurpleblueText(data: 'LogOut')],
// ))
// ],
// ),
// ),
