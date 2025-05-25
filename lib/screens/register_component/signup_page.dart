import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:skill_auction/custom_widgets/custom_snackbar.dart';
import 'package:skill_auction/custom_widgets/custom_textfield.dart';
import 'package:skill_auction/custom_widgets/purple_text.dart';
import 'package:skill_auction/custom_widgets/purpleblue_text.dart';
import 'package:skill_auction/custom_widgets/white_text.dart';
import 'package:skill_auction/firebase_model/user_model.dart';
import 'package:skill_auction/screens/client_dashboard/buyer_screen.dart';
import 'package:skill_auction/screens/register_component/login_screen.dart';
import 'package:skill_auction/screens/seller_dashboard/seller_dashboard.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}
final ref = FirebaseDatabase.instance.ref();
final auth = FirebaseAuth.instance;
class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  bool obscureValue = true;
  int selectedvalue = 1;
  List<dynamic> userRole = ['Seller', 'Buyer'];
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final description=TextEditingController();
  late int roleValue;
  Future<void> saveData() async {
    try {
      // Create user with email and password
      final UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final userId = userCredential.user!.uid;

      // 1 for Seller, 2 for Buyer
      final roleValue = selectedvalue + 1;

      // Create user model
      UserModel userModel = UserModel(
        uId: userId,
        firstname: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        description: description.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: phoneNumberController.text.trim(),
        password: passwordController.text.trim(),
        role: roleValue,
      );

      // Save user data under 'users/{userId}'
      await ref.child('auctionusers').child(userId).set(userModel.toMap());

      ScaffoldMessenger.of(context).showSnackBar(CustomSnackbar.show(
        content:
        WhiteText(data: 'User Registered Successfully')
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(CustomSnackbar.show(
        content: Text(
          'Something went wrong: $e',
          style: TextStyle(color: Colors.white),
        ),
      ));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          // padding: const EdgeInsets.only(
          //     left: 15.0,
          // right: 15.0,
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                //mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                          height: 100,
                          width: 100,
                          child: Image.asset('assets/skill auction new.png'),),
                      Text(
                        'Create An Account',
                        style: TextStyle(
                          color: Color(0xFF0944c8),
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: CustomtextField(
                            obscure: false,
                            prefix: const Icon(
                              Icons.person,
                            ),
                            hint: 'First Name',
                            label: const Text('First Name'),
                            customcontroller: firstNameController,
                           ),
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      Expanded(
                        child: CustomtextField(
                            obscure: false,
                            hint: 'Last Name',
                            label: const Text('Last Name'),
                            customcontroller: lastNameController,
                           ),
                      ),
                    ],
                  ),
                 // const SizedBox(height: 5),
                  CustomtextField(
                    prefix: const Icon(
                      Icons.email,
                    ),
                    hint: 'Enter Email',
                    label: const Text('Email'),
                    customcontroller: emailController,
                    obscure: false,
                    
                  ),
                 // const SizedBox(height: 5),
                  CustomtextField(
                    maxlines: 4,
                    prefix: const Icon(
                      Icons.description,
                    ),
                    hint: 'Describe about your self',
                    label: const Text('About yourself'),
                    customcontroller: description,
                    obscure: false,

                  ),
                  //const SizedBox(height: 10),
                  CustomtextField(
                      obscure: false,
                      prefix: const Icon(
                        Icons.phone,
                      ),
                      keyboardtype: TextInputType.number,
                      hint: 'Enter Phone Number',
                      label: const Text('Phone Number'),
                      customcontroller: phoneNumberController,
                   ),
                  //const SizedBox(height: 10),
                  CustomtextField(
                      prefix: const Icon(
                        Icons.lock,
                      ),
                      obscure: obscureValue,
                      postfix: IconButton(
                        icon: Icon(
                          obscureValue
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureValue = !obscureValue;
                          });
                        },
                      ),
                      obscureChracter: '*',
                      maxlines: 1,
                      hint: 'Enter Password',
                      label: const Text('Password'),
                      customcontroller: passwordController,
                      ),
                  SizedBox(
                    height: 10,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      iconColor: Color(0xFF0944c8),
                      labelText: 'Select Role',
                      labelStyle: const TextStyle(color: Color(0XFF8a2be1),),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF0944c8)),
                      ),
                    ),
                    value: userRole[selectedvalue],
                    items: userRole.map((role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedvalue = userRole.indexOf(value!);
                      });
                    },
                   
                  ),
                  SizedBox(height: 20),
                  Container(
                    color: Color(0xFF0944c8),
                    height: 50,
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(backgroundColor: Color(0xFF0944c8)),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await saveData();
                          if (userRole[selectedvalue] == 'Seller') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SellerDashboard()),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => BuyerScreen()),
                            );
                          }
                        } else {
                          // Optional: show a general error message
                          ScaffoldMessenger.of(context).showSnackBar(
                          CustomSnackbar.show(content: WhiteText(data: 'Please fix the errors in the form')
                    
                          ), );
                        }
                      },
                      child:WhiteText(data: 'SIGNUP')
                    ),
                  ),
                  SizedBox(height: 10,),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        PurpleblueText(data: 'Already Have an Account?'),
                        TextButton(onPressed:(){
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context){
                            return LoginScreen();
                          }));
                        }, child:PurpleText(data: 'Login'))
                      ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
