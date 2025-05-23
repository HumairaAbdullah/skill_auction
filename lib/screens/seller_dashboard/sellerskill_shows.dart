import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_auction/custom_widgets/custom_snackbar.dart';
import 'package:skill_auction/custom_widgets/white_text.dart';
import 'package:skill_auction/firebase_model/sellercrud.dart';
import 'package:skill_auction/screens/seller_dashboard/gig_page.dart';

class SellerSkillShow extends StatefulWidget {
  const SellerSkillShow({super.key});

  @override
  State<SellerSkillShow> createState() => _SellerSkillShowState();
}

class _SellerSkillShowState extends State<SellerSkillShow> {
  @override

  void initState() {
    super.initState();
    // Fetch data when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SellerCrud>(context, listen: false).fetchData();
    });
  }
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            
            SizedBox(height: 10),
            Consumer<SellerCrud>(
              builder: (context, sellerCrud, child) {
                final skills = sellerCrud.skills;

                if (skills.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text("No Skills Added Yet."),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: skills.length,
                  itemBuilder: (context, index) {
                    final skill = skills[index];
                    return Stack(
                        alignment: AlignmentDirectional.topCenter,
                        children: [
                          Card(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: skill.imagePath.isNotEmpty &&
                                  skill.imagePath != "null"
                                  ? Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: MemoryImage(
                                      base64Decode(skill.imagePath),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                                  : Icon(Icons.image_not_supported),
                              title: Text(skill.skillTitle),
                              subtitle: Text(
                                skill.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text('Min Bid: \$${skill.minBid}'),
                            ),
                          ),
                          Positioned(
                            left: 250,
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => GigPage(
                                          isUpdating: true,
                                          skillToUpdate: skill,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.edit,color: Color(0XFF8a2be1),),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    try {
                                      await Provider.of<SellerCrud>(context,
                                          listen: false)
                                          .deleteData(skill.skillId);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(CustomSnackbar.show(
                                          content: WhiteText(
                                              data:
                                              'Skill Deleted Successfully')));
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(CustomSnackbar.show(
                                          content: WhiteText(
                                              data:
                                              'Delete Failed: ${e.toString()}')));
                                    }
                                  },
                                  icon: Icon(Icons.delete,color: Color(0XFF8a2be1),),
                                ),
                              ],
                            ),
                          ),
                        ]);
                  },
                );
              },
            ),
          ],

        ),
      ),
    );
  }
}
