import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_auction/custom_widgets/custom_snackbar.dart';
import 'package:skill_auction/firebase_model/sellercrud.dart';
import 'package:skill_auction/screens/admin_dashboard/admin_dashboard.dart';
import 'package:skill_auction/screens/client_dashboard/buyer_screen.dart';
import 'package:skill_auction/screens/register_component/login_screen.dart';
import 'package:skill_auction/screens/register_component/splash_screen.dart';
import 'package:skill_auction/screens/seller_dashboard/gig_page.dart';
import 'package:skill_auction/screens/seller_dashboard/seller_dashboard.dart';
import 'package:skill_auction/screens/seller_dashboard/seller_home.dart';
import 'package:skill_auction/screens/seller_dashboard/seller_information.dart';
import 'package:skill_auction/screens/seller_dashboard/sellerprofile_provider.dart';
import 'package:skill_auction/screens/seller_dashboard/sellerskill_shows.dart';

import 'custom_widgets/white_text.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SellerCrud()),
        ChangeNotifierProvider(create: (context) => SellerProfileProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('auctionusers');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isInitialCheckComplete = false;
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(Duration(seconds: 3));
      final user = _auth.currentUser;

      if (user != null) {
        // User is logged in, check their role
        final snapshot = await _usersRef.child(user.uid).get();

        if (snapshot.exists) {
          final role = snapshot.child('role').value as int?;

          setState(() {
            _initialScreen = _getScreenForRole(role);
            _isInitialCheckComplete = true;
          });
          return;
        }
      }

      // If we get here, either no user or invalid data
      setState(() {
        _initialScreen = LoginScreen();
        _isInitialCheckComplete = true;
      });
    } catch (e) {
      debugPrint('Initialization error: $e');
      setState(() {
        _initialScreen = LoginScreen();
        _isInitialCheckComplete = true;
      });
    }
  }

  Widget _getScreenForRole(int? role) {
    switch (role) {
      case 0:
        return AdminDashboard();
      case 1:
        return SellerDashboard();
      case 2:
        return BuyerScreen();
      default:
        return LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialCheckComplete) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
        // Scaffold(
        //   body: Center(child: CircularProgressIndicator()),
        // ),
      );
    }

    return MaterialApp(
      theme: ThemeData(
        iconTheme: IconThemeData(color: Color(0XFF8a2be1)),
        primaryColor: Color(0xFF0944c8),
      ),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;

            if (user == null) {
              return LoginScreen();
            }

            // User is logged in, check their role
            return FutureBuilder<DataSnapshot>(
              future: _usersRef.child(user.uid).get(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.done) {
                  if (!roleSnapshot.hasData || !roleSnapshot.data!.exists) {
                    return LoginScreen();
                  }

                  final role = roleSnapshot.data!.child('role').value as int?;
                  return _getScreenForRole(role);
                }

                // While loading role, show initial screen (which might be correct)
                return _initialScreen ?? LoginScreen();
              },
            );
          }

          // While auth state is being checked, show initial screen
          return _initialScreen ?? LoginScreen();
        },
      ),
    );
  }}