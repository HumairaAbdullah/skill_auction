import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_auction/custom_widgets/purple_text.dart';
import 'package:skill_auction/screens/seller_dashboard/gig_page.dart';
import 'package:skill_auction/screens/seller_dashboard/profile_page.dart';
import 'package:skill_auction/screens/seller_dashboard/sellerprofile_provider.dart';

class SellerInformation extends StatefulWidget {
  const SellerInformation({super.key});

  @override
  State<SellerInformation> createState() => _SellerInformationState();
}

class _SellerInformationState extends State<SellerInformation> {
  @override
  Widget build(BuildContext context) {
   return Scaffold(
     body: Center(child: PurpleText(data: 'About Seller Information')),
   );
  }
}
