import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skill_auction/custom_widgets/purpleblue_text.dart';
import 'package:skill_auction/screens/seller_dashboard/gig_page.dart';
import 'package:skill_auction/screens/seller_dashboard/review_screen.dart';
import 'package:skill_auction/screens/seller_dashboard/seller_information.dart';
import 'package:skill_auction/screens/seller_dashboard/sellerprofile_provider.dart';
import 'package:skill_auction/screens/seller_dashboard/sellerskill_shows.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SellerProfileProvider>(context, listen: false)
          .fetchSellerInfo();
    });
  }

  XFile? _image;
  String? _base64image;
  final ImagePicker _picker = ImagePicker();

  Future<void> imagepickfunc() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = image;
      });
      final bytes = await image.readAsBytes();
      _base64image = base64Encode(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            toolbarHeight: 200,
            title: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  InkWell(
                    onTap: imagepickfunc,
                    child: CircleAvatar(
                        radius: 60,
                        backgroundImage: _image != null
                            ? kIsWeb
                                ? NetworkImage(_image!.path)
                                : FileImage(File(_image!.path))
                            : _base64image != null && _base64image!.isNotEmpty
                                ? MemoryImage(base64Decode(_base64image!))
                                : null,
                        child: _image == null &&
                                (_base64image == null || _base64image!.isEmpty)
                            ? IconButton(
                                onPressed: imagepickfunc,
                                icon: Icon(
                                  Icons.camera_alt_outlined,
                                  color: Color(0XFF8a2be1),
                                ),
                              )
                            : null),
                  ),
                  Consumer<SellerProfileProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const CircularProgressIndicator();
                      }

                      if (provider.currentUser.isEmpty) {
                        return const Text("No user data available.");
                      }

                      final user = provider.currentUser.first;
                      return Text(
                        "${user.firstname} ${user.lastName}", // Note: lastName (capital 'N')
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.amber),
                      Text('5 (100)'),
                    ],
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              labelColor: const Color(0xFF0944c8),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'About'),
                Tab(text: 'Skills'),
                Tab(text: 'Reviews'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              SellerInformation(),
              SellerSkillShow(),
              ReviewScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
