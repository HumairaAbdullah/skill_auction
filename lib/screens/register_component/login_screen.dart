import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:skill_auction/custom_widgets/custom_snackbar.dart';
import 'package:skill_auction/custom_widgets/custom_textfield.dart';
import 'package:skill_auction/custom_widgets/purple_text.dart';
import 'package:skill_auction/custom_widgets/purpleblue_text.dart';
import 'package:skill_auction/custom_widgets/white_text.dart';
import 'package:skill_auction/screens/register_component/signup_page.dart';

import '../admin_dashboard/admin_dashboard.dart';
import '../client_dashboard/buyer_screen.dart';
import '../seller_dashboard/seller_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final DatabaseReference ref = FirebaseDatabase.instance.ref();
  bool _obscurePassword = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  Future<void> login() async {
    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final userId = userCredential.user?.uid;
      if (userId == null) throw Exception('User ID is null');

      final snapshot = await ref.child('auctionusers/$userId').get();
      if (!snapshot.exists) {
        throw Exception('User not found');
      }

      final role = snapshot.child('role').value as int?;
      if(role==0){
        Navigator.pushReplacement(context,MaterialPageRoute(builder: (BuildContext context){
          return AdminDashboard();
        }));
      }
      else if (role == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SellerDashboard()),
        );
      } else if (role == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BuyerScreen()),
        );
      } else {
        throw Exception('Unknown user role');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackbar.show(content: WhiteText(data: '$e')),
      );
    }
  }



  Future<void> forgotPassword() async {
    try {
      auth
          .sendPasswordResetEmail(email: emailController.text.trim())
          .then((value) {
        ScaffoldMessenger.of(context).showSnackBar(CustomSnackbar.show(
            content: Text(
              'Reset Password Email has been sent',
              style: TextStyle(color: Colors.white),
            )));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(CustomSnackbar.show(
          content: Text(
            '$e',
            style: TextStyle(color: Colors.white),
          )));
    }
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 15.0,right: 15.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20,),
                    CircleAvatar(
                      radius:90,
                      backgroundImage: AssetImage('assets/skill auction.png'),
                    ),

                    CustomtextField(
                        obscure: false,
                        hint: 'Enter Email',
                        label: Text('Email'),
                        prefix: Icon(Icons.email),
                        customcontroller: emailController,
                       ),
                    SizedBox(
                      height: 10,
                    ),
                    CustomtextField(
                        prefix: Icon(Icons.lock),
                        postfix: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },),
                        hint: 'Enter Password',
                        label: Text('Password'),
                        customcontroller: passwordController,
                        obscure: _obscurePassword,
                        maxlines: 1,
                        obscureChracter: '*',
                       ),
                    TextButton(
                        onPressed: () {
                          forgotPassword();
                        },
                        child:PurpleText(data: 'Forgot Password?'),),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0944c8),
                      ),
                        onPressed: () {
                          login();
                        },

                        child: Text(
                          'LOGIN',
                          style: TextStyle(color: Colors.white),
                        )),
                    // SizedBox(height: 10,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                       PurpleblueText(data: 'Not Have an Account?'),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                                  return SignupPage();
                                }));
                          },
                          child: PurpleText(data: 'SignUp'),

                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      
      ),
    );
  }
}
