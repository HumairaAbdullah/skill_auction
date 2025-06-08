import 'dart:convert';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skill_auction/custom_widgets/custom_color.dart';
import 'package:skill_auction/custom_widgets/custom_textfield.dart';
import 'package:skill_auction/custom_widgets/purple_text.dart';
import 'package:skill_auction/custom_widgets/purpleblue_text.dart';
import 'package:skill_auction/custom_widgets/white_text.dart';
import 'package:skill_auction/firebase_model/skill_model.dart';
import 'package:skill_auction/screens/client_dashboard/buyer_profile.dart';
import 'package:skill_auction/screens/client_dashboard/detailskill_view.dart';
import 'package:skill_auction/screens/seller_dashboard/sellerprofile_provider.dart';

class BuyerScreen extends StatefulWidget {
  const BuyerScreen({super.key});

  @override
  State<BuyerScreen> createState() => _BuyerScreenState();
}

class _BuyerScreenState extends State<BuyerScreen> {
  List<SkillModel> dataList = [];
  List<SkillModel> filteredList = [];
  XFile? _image;
  String? _base64image;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = true;
  final CustomColor customColor = CustomColor();
  final searchController = TextEditingController();
  final dbRef = FirebaseDatabase.instance.ref().child('sellerskills');

// fetch all skills
  Future<void> fetchAllSkills() async {
    try {
      setState(() {
        isLoading = true;
      });

      final skills = await _fetchSkillsFromFirebase();

      setState(() {
        dataList = skills;
        filteredList = List.from(dataList); // Initialize filteredList
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching skills: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Future<List<SkillModel>> _fetchSkillsFromFirebase() async {
  //   final snapshot = await dbRef.get();
  //   if (snapshot.exists) {
  //     Map<dynamic, dynamic> skillsMap = snapshot.value as Map<dynamic, dynamic>;
  //     // return skillsMap.entries.map((entry) {
  //     //   return SkillModel.fromMap(entry.value as Map<dynamic, dynamic>);
  //     // }).toList();
  //     return skillsMap.entries.map((entry) {
  //       final skillData = Map<String, dynamic>.from(entry.value as Map);
  //       skillData['skillId'] = entry.key; // firebase key as a skillId
  //       return SkillModel.fromMap(skillData);
  //     }).toList();
  //   }
  //   return [];
  // }
  Future<List<SkillModel>> _fetchSkillsFromFirebase() async {
    try {
      final snapshot = await dbRef.get();
      if (snapshot.exists) {
        final skillsMap = snapshot.value as Map<dynamic, dynamic>;
        debugPrint('Fetched skills: ${skillsMap.keys}'); // Debug print

        return skillsMap.entries
            .map((entry) {
              try {
                final skillData = Map<String, dynamic>.from(entry.value as Map);
                skillData['skillId'] = entry.key;
                return SkillModel.fromMap(skillData);
              } catch (e) {
                debugPrint('Error parsing skill ${entry.key}: $e');
                return null;
              }
            })
            .where((skill) => skill != null)
            .toList()
            .cast<SkillModel>();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching skills: $e');
      return [];
    }
  }

  void _filterSkills() {
    final query = searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        filteredList = List.from(dataList);
      });
      return;
    }

    setState(() {
      filteredList = dataList.where((skill) {
        return skill.skillTitle.toLowerCase().contains(query) ||
            skill.sellerName.toLowerCase().contains(query) ||
            skill.description.toLowerCase().contains(query) ||
            skill.minBid.toString().contains(query);
      }).toList();
    });
  }


  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterSkills);
    fetchAllSkills();
    final provider = Provider.of<SellerProfileProvider>(context, listen: false);
    provider.fetchSellerInfo();
  }
  @override
  void dispose() {
    searchController.removeListener(_filterSkills);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFffd7f3),
        centerTitle: true,
        toolbarHeight: 90,
        leading: Consumer<SellerProfileProvider>(
            builder: (context, provider, child){
              final user = provider.currentUser.isNotEmpty ? provider.currentUser.first : null;

              return InkWell(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context){
                    return BuyerProfile();
                  }));
                },
                 child: CircleAvatar(
              backgroundImage: _image != null
              ? (kIsWeb
                  ? NetworkImage(_image!.path)
                  : FileImage(File(_image!.path)) as ImageProvider)
                  : (user != null && user.imagePath != null && user.imagePath!.isNotEmpty
              ? MemoryImage(base64Decode(user.imagePath!))
                  : null),
              child: (_image == null && (user == null || user.imagePath == null || user.imagePath!.isEmpty))
              ? Icon(
              Icons.camera_alt_outlined,
              color: Color(0XFF8a2be1),
              )
                  : null,
              ),


              // child: CircleAvatar(
                //     radius: 60,
                //     backgroundImage: _image != null
                //         ? kIsWeb
                //         ? NetworkImage(_image!.path)
                //         : FileImage(File(_image!.path))
                //         : _base64image != null && _base64image!.isNotEmpty
                //         ? MemoryImage(base64Decode(user.imagePath!))
                //         : null,
                //     child: _image == null &&
                //         (_base64image == null || _base64image!.isEmpty)
                //         ? IconButton(
                //       onPressed: imagepickfunc,
                //       icon: Icon(
                //         Icons.camera_alt_outlined,
                //         color: Color(0XFF8a2be1),
                //       ),
                //     )
                //         : null),
              );}
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PurpleblueText(data: 'Skill Auction'),
            Text(
              'Need a Pro? Bid Smart, Hire Faster!',
              style: TextStyle(
                color: customColor.purpleText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Search',
                  labelStyle: TextStyle(
                    color: customColor.purpleBlue,
                  ),
                  hintText: 'Search for skills',
                  hintStyle: TextStyle(color: customColor.purpleText),
                  suffixIcon: IconButton(onPressed: _filterSkills

                 , icon: Icon(Icons.search,color: customColor.purpleText,)),
                  prefixIconColor: customColor.purpleText,
                  iconColor: customColor.purpleText,
                  enabled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(60),
                    borderSide: BorderSide(
                      color: customColor.purpleBlue,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(60),
                    borderSide: BorderSide(
                      color: customColor.purpleText,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(60),
                    borderSide: BorderSide(
                      color: customColor.purpleBlue,
                    ),
                  ),
                ),
              ),
              CarouselSlider(
                items: [
                  Image.asset(
                    'assets/skill auction banner new.png',
                  ),
                  Image.asset(
                    'assets/skillauction second banners.png',
                  ),
                  Image.asset(
                    'assets/skill auction third banner.png',
                  ),

                  // Add more banners here if needed
                ],
                options: CarouselOptions(
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.8,
                  aspectRatio: 16 / 9,
                  initialPage: 0,
                ),
              ),
              SizedBox(
                height: 10,
              ),
              GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 5,
                  childAspectRatio: 0.68,
                ),
                  itemCount: filteredList.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final skill = filteredList[index] as SkillModel;
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return DetailSkillView(skillId: skill.skillId);
                        }),
                      );
                    },
                    child: Card(
                      child: Column(
                        children: [
                          skill.imagePath.isNotEmpty
                              ? SizedBox(
                                  height: 150,
                                  child: Image.memory(
                                    base64Decode(skill.imagePath),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : SizedBox(
                                  height: 100,
                                  child: Icon(Icons.image, size: 50),
                                ),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, right: 8.0),
                            child: Row(
                              children: [
                                Text(
                                  overflow: TextOverflow.ellipsis,
                                  skill.sellerName,
                                  style: TextStyle(
                                      fontSize: 17,
                                      color: customColor.purpleBlue,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    overflow: TextOverflow.ellipsis,
                                    skill.skillTitle,
                                    style: TextStyle(
                                      color: customColor.purpleText,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    overflow: TextOverflow.ellipsis,
                                    'MinBid From:',
                                    style: TextStyle(
                                        color: customColor.purpleBlue),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    overflow: TextOverflow.ellipsis,
                                    '\$${skill.minBid}',
                                    style: TextStyle(
                                      color: customColor.purpleText,
                                    ),
                                  ),
                                ]),
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
      ),
    );
  }
}
