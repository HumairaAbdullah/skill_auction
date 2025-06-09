import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skill_auction/custom_widgets/purpleblue_text.dart';
import 'package:skill_auction/screens/seller_dashboard/bid_page.dart';
import 'package:skill_auction/screens/seller_dashboard/gig_page.dart';
import 'package:skill_auction/screens/seller_dashboard/order_page.dart';
import 'package:skill_auction/screens/seller_dashboard/profile_page.dart';
import 'package:skill_auction/screens/seller_dashboard/seller_home.dart';
import 'package:skill_auction/screens/seller_dashboard/sellerprofile_provider.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _selectedItem = 0;
  XFile? _image;
  final screens = [
    SellerHome(),
    OrderPage(),
    BidPage(),
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
        selectedItemColor: Color(0XFF8a2be1),
        currentIndex: _selectedItem,
        type: BottomNavigationBarType.fixed, // Add this line
        items: [
          BottomNavigationBarItem(
            label: 'Dashboard',
            icon: Icon(
              Icons.home,
              color: Color(0xFF0944c8),
            ),
          ),
          BottomNavigationBarItem(
            label: 'Orders',
            icon: Icon(
              Icons.developer_board,
              color: Color(0xFF0944c8),
            ),
          ),
          BottomNavigationBarItem(
            label: 'All Bids',
            icon: Icon(
              Icons.gavel,
              color: Color(0xFF0944c8),
            ),
          ),
          BottomNavigationBarItem(
            label: 'Profile',
            icon: SizedBox(
              width: 24,
              child: SellerAvatarIcon(image: _image),
            ),
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedItem = index;
          });
        },
      ),
    );
  }
}

class SellerAvatarIcon extends StatelessWidget {
  final XFile? image;

  const SellerAvatarIcon({this.image});

  @override
  Widget build(BuildContext context) {
    return Consumer<SellerProfileProvider>(
      builder: (context, provider, child) {
        if (provider.currentUser.isEmpty) {
          return Icon(
            Icons.account_circle,
            color: Color(0xFF0944c8),
          );
        }

        final user = provider.currentUser.first;

        return CircleAvatar(
          radius: 12,
          backgroundImage: image != null
              ? FileImage(File(image!.path)) as ImageProvider
              : (user.imagePath != null && user.imagePath!.isNotEmpty
              ? MemoryImage(base64Decode(user.imagePath!))
              : null),
          child: image == null &&
              (user.imagePath == null || user.imagePath!.isEmpty)
              ? Icon(
            Icons.account_circle,
            color: Color(0xFF0944c8),
          )
              : null,
        );
      },
    );
  }
}
