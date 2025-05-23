import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_auction/firebase_model/sellercrud.dart';
import 'package:skill_auction/screens/register_component/login_screen.dart';
import 'package:skill_auction/screens/seller_dashboard/gig_page.dart';
import 'package:skill_auction/screens/seller_dashboard/seller_home.dart';
import 'package:skill_auction/screens/seller_dashboard/seller_information.dart';
import 'package:skill_auction/screens/seller_dashboard/sellerprofile_provider.dart';
import 'package:skill_auction/screens/seller_dashboard/sellerskill_shows.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //Provider.debugCheckInvalidValueType=null;
  runApp(MultiProvider(
   providers: [
     ChangeNotifierProvider(create: (context)=>SellerCrud(),),
     ChangeNotifierProvider(create: (context)=>SellerProfileProvider(),),
   ],
    child: MyApp(),
  ),);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        iconTheme: IconThemeData(
          color: Color(0XFF8a2be1),
        ),
        primaryColor: Color(0xFF0944c8),
      ),
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
