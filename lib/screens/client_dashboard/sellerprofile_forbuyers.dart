import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_auction/firebase_model/user_model.dart';
import 'package:skill_auction/firebase_model/skill_model.dart';
import 'package:skill_auction/custom_widgets/custom_color.dart';
import 'package:skill_auction/screens/client_dashboard/detailskill_view.dart';

class SellerprofileForbuyers extends StatefulWidget {
  final String sellerId;
  final String sellerName;

  const SellerprofileForbuyers({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  State<SellerprofileForbuyers> createState() => _SellerprofileForbuyersState();
}

class _SellerprofileForbuyersState extends State<SellerprofileForbuyers> {
  final CustomColor customColor = CustomColor();
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref('auctionusers');
  final DatabaseReference skillsRef =
      FirebaseDatabase.instance.ref('sellerskills');

  UserModel? sellerDetails;
  List<SkillModel> sellerSkills = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSellerDetails();
    fetchSellerSkills();
  }

  Future<void> fetchSellerDetails() async {
    try {
      final snapshot = await dbRef.child(widget.sellerId).get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          sellerDetails = UserModel.fromMap(data);
        });
      }
    } catch (e) {
      debugPrint('Error fetching seller details: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchSellerSkills() async {
    try {
      debugPrint('Fetching skills for sellerId: ${widget.sellerId}');
      final snapshot = await skillsRef
          .orderByChild('sellerId')
          .equalTo(widget.sellerId)
          .get();

      if (snapshot.exists) {
        final List<SkillModel> loadedSkills = [];
        final data = snapshot.value as Map<dynamic, dynamic>;
        debugPrint('Found ${data.length} skills');

        data.forEach((key, value) {
          if (value != null) {
            final skillMap = Map<String, dynamic>.from(value as Map);
            debugPrint('Skill loaded: ${skillMap['skillTitle']}');
            loadedSkills.add(SkillModel.fromMap(skillMap));
          }
        });

        setState(() {
          sellerSkills = loadedSkills;
        });
      } else {
        debugPrint('No skills found for this seller.');
      }
    } catch (e) {
      debugPrint('Error fetching seller skills: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'About the Seller',
          style: TextStyle(color: customColor.purpleText),
        ),
        backgroundColor: const Color(0xFFffd7f3),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Seller Profile Section
                  Card(
                    color: customColor.peach,
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: sellerDetails?.imagePath != null
                                ? MemoryImage(
                                    base64Decode(sellerDetails!.imagePath!))
                                : null,
                            child: sellerDetails?.imagePath == null
                                ? const Icon(Icons.person, size: 50)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${sellerDetails?.firstname ?? ''} ${sellerDetails?.lastName ?? ''}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: customColor.purpleText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            sellerDetails?.description ??
                                'No description provided',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Seller Skills Section
                  Column(
                    children: [
                      Text(
                        'Skills Offered',
                        style: TextStyle(
                          decorationColor: customColor.purpleText,
                          decoration: TextDecoration.underline,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: customColor.purpleBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (sellerSkills.isEmpty) const Text('No skills listed yet'),

                  ...sellerSkills
                      .map((skill) => InkWell(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context){
                         return DetailSkillView(skillId: skill.skillId);
                      },),);
                    },
                        child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.memory(
                                      base64Decode(skill.imagePath),
                                      height: 250,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                    Text(
                                      skill.skillTitle,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: customColor.purpleText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(skill.description),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Min Bid: \$${skill.minBid}',
                                          style: TextStyle(
                                            color: customColor.purpleBlue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          skill.category,
                                          style: TextStyle(
                                            color: customColor.purpleText,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ))
                      .toList(),
                ],
              ),
            ),
    );
  }
}
