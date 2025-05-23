import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_auction/firebase_model/sellercrud.dart';

class SkillInformation extends StatefulWidget {
  const SkillInformation({super.key});

  @override
  State<SkillInformation> createState() => _SkillInformationState();
}

class _SkillInformationState extends State<SkillInformation> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  Consumer<SellerCrud>(
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
                      child: InkWell(
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
                          trailing:
                          Text('Min Bid: \$${skill.minBid}'),
                        ),
                      ),
                    ),

                  ]);
            },
          );
        },
      )
    );
  }
}
