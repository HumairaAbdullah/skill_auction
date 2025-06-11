import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_auction/custom_widgets/custom_color.dart';
import 'package:skill_auction/custom_widgets/purple_text.dart';
import 'package:skill_auction/custom_widgets/purpleblue_text.dart';
import 'package:skill_auction/custom_widgets/white_text.dart';
import 'package:skill_auction/screens/register_component/login_screen.dart';
import 'package:skill_auction/screens/seller_dashboard/sellerprofile_provider.dart';

class SellerInformation extends StatefulWidget {
  const SellerInformation({super.key});

  @override
  State<SellerInformation> createState() => _SellerInformationState();
}

class _SellerInformationState extends State<SellerInformation> {
  final CustomColor customColor=CustomColor();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SellerProfileProvider>(context, listen: false)
          .fetchSellerInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 15,
            ),
            Text(
              'User Information',
              style: TextStyle(
                color: Color(
                  0XFF8a2be1,
                ),
                fontSize: 20,
              ),
            ),
            Consumer<SellerProfileProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sellerInfoList = provider.currentUser;
                if (sellerInfoList.isEmpty) {
                  return Center(
                      child:
                          const PurpleblueText(data: 'No user data available'));
                }

                // Get the first user (assuming there's only one matching user)
                final sellerInfo = sellerInfoList.first;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color:  customColor.peach,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              SizedBox(height: 5,),
                              Row(
                                children: [
                                  Icon(Icons.perm_contact_cal,color: customColor.purpleBlue,),
                                  Text(
                                    'About:',
                                    style: TextStyle(
                                      color: customColor.purpleBlue,
                                      fontSize: 18,

                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10,),
                              Text('${sellerInfo.description}.',style: TextStyle(
                                color: customColor.purpleText
                              ),),
                              SizedBox(
                                height: 15,
                              ),
                              Row(
                                children: [
                                  Icon(Icons.email,color: customColor.purpleBlue,),
                                  Text(
                                    'Email:',
                                    style: TextStyle(
                                      color: customColor.purpleBlue,
                                      fontSize: 18,

                                    ),
                                  ),
                                  Text(
                                    '  ${sellerInfo.email}',
                                    style: TextStyle(fontWeight: FontWeight.bold,color: customColor.purpleText),
                                  ),
                                ],
                              ),

                              SizedBox(
                                height: 15,
                              ),
                              Row(
                                children: [
                                  Icon(Icons.phone,color: customColor.purpleBlue,),
                                  Text(
                                    'Phone:',
                                    style: TextStyle(
                                      color: customColor.purpleBlue,
                                      fontSize: 18,

                                    ),
                                  ),
                                  Text(
                                    '  ${sellerInfo.phoneNumber}',
                                    style: TextStyle(fontWeight: FontWeight.bold,color: customColor.purpleText),
                                  ),
                                ],
                              ),

                              SizedBox(height: 30,),
                              Container(
                                width: double.infinity,
                                height: 50,
                                color: Color(0xFF0944c8),
                                child: TextButton(
                                  onPressed: ()async {
                                    await FirebaseAuth.instance.signOut();
                                    Navigator.pushReplacement(context,
                                        MaterialPageRoute(builder: (context) {
                                          return LoginScreen();
                                        }));
                                  },
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.logout,
                                        color: Colors.white,
                                      ),
                                      WhiteText(data: 'LogOut'),
                                    ],
                                  ),
                                ),
                              ),

                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
