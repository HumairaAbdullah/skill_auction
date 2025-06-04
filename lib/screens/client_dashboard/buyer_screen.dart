import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:skill_auction/custom_widgets/custom_color.dart';
import 'package:skill_auction/custom_widgets/custom_textfield.dart';
import 'package:skill_auction/custom_widgets/purple_text.dart';
import 'package:skill_auction/custom_widgets/purpleblue_text.dart';
import 'package:skill_auction/custom_widgets/white_text.dart';
import 'package:skill_auction/firebase_model/skill_model.dart';
import 'package:skill_auction/screens/client_dashboard/buyer_profile.dart';
import 'package:skill_auction/screens/client_dashboard/detailskill_view.dart';

class BuyerScreen extends StatefulWidget {
  const BuyerScreen({super.key});

  @override
  State<BuyerScreen> createState() => _BuyerScreenState();
}

class _BuyerScreenState extends State<BuyerScreen> {
  List<dynamic> dataList = [];
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
  // it will fetch the amount of the bid


  @override
  void initState() {
    super.initState();
    fetchAllSkills();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFffd7f3),
        centerTitle: true,
        toolbarHeight: 90,
        leading: Image.asset('assets/buyers skill auction.png'),
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return BuyerProfile();
              }));
            },
            child: CircleAvatar(
              radius: 35,
            ),
          ),
        ],
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
              CustomtextField(
                hint: 'search',
                label: PurpleText(data: 'Search'),
                obscure: false,
                customcontroller: searchController,
                prefix: Icon(Icons.search),
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
                itemCount: dataList.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final skill = dataList[index] as SkillModel;
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
                          Column(
                            textDirection: TextDirection.ltr,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                overflow: TextOverflow.ellipsis,
                                skill.skillTitle,
                                style: TextStyle(
                                  color: customColor.purpleText,
                                ),
                              ),
                            ],
                          ),
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  'MinBid From:',
                                  style:
                                      TextStyle(color: customColor.purpleBlue),
                                ),
                                SizedBox(
                                  width: 15,
                                ),
                                Text(
                                  overflow: TextOverflow.ellipsis,
                                  '${skill.minBid}',
                                  style: TextStyle(
                                    color: customColor.purpleText,
                                  ),
                                ),
                              ]),
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
