import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:skill_auction/custom_widgets/purpleblue_text.dart';
import 'package:skill_auction/screens/seller_dashboard/chat_page.dart';
import 'package:skill_auction/screens/seller_dashboard/gig_page.dart';
import 'package:skill_auction/screens/seller_dashboard/order_page.dart';
import 'package:skill_auction/screens/seller_dashboard/profile_page.dart';
import 'package:skill_auction/screens/seller_dashboard/seller_home.dart';

class SellerDashboard extends StatefulWidget{
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _selectedItem=0;
  final screens=[
    SellerHome(),
    OrderPage(),
    ChatPage(),
    ProfilePage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: screens[_selectedItem],
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: true,
        selectedLabelStyle: TextStyle(color: Color(0XFF8a2be1)),
        selectedItemColor:Color(0XFF8a2be1) ,
        currentIndex: _selectedItem,
        items: [

        BottomNavigationBarItem(
          
          label: 'Dashboard',
            icon:Icon(Icons.home,color: Color(0xFF0944c8),),),
        BottomNavigationBarItem( label: 'Orders',
          icon: Icon(Icons.developer_board,color: Color(0xFF0944c8),),),
        BottomNavigationBarItem(label: 'Chat',
            icon: Icon(Icons.chat,color: Color(0xFF0944c8),)),
        BottomNavigationBarItem( label: 'Profile',
            icon: Icon(Icons.account_circle,color: Color(0xFF0944c8),)),
      ],
      onTap: (index){
        setState(() {
          _selectedItem=index;
        });
      },),
    );

  }
}
