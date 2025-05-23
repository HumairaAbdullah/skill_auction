import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:skill_auction/firebase_model/skill_model.dart';

import '../custom_widgets/custom_snackbar.dart';
class SellerCrud extends ChangeNotifier {
  bool isloading=false;

  final dbRef = FirebaseDatabase.instance.ref('sellerskills');
  final auth = FirebaseAuth.instance;
  List<SkillModel> _skills = [];
  List<SkillModel> get skills => _skills;
  List<SkillModel> _sellerInfo=[];
  List<SkillModel> get sellerInfo=>_sellerInfo;


  Future<void> saveData(SkillModel skillmodel) async {
    final skillId = dbRef.push().key;
    skillmodel.sellerId = auth.currentUser!.uid;
    await dbRef.child('$skillId').set(skillmodel.toMap());
    notifyListeners();
  }

  Future<void> fetchData() async {
    final sellerId = auth.currentUser!.uid;
    //if (sellerId == null) return;

    try {
      final snapshot = await dbRef.get();
      if (snapshot.exists) {
        final List<SkillModel> loadedSkills = [];
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final skill = SkillModel.fromMap(Map<String, dynamic>.from(value));
          if (skill.sellerId == sellerId) {
            loadedSkills.add(skill);
          }
        });
        _skills = loadedSkills;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }
  // get the seller Information
  Future<void>fetchSellerInfo()async{
    final dataref=FirebaseDatabase.instance.ref('auctionusers');
    final sellerId = auth.currentUser!.uid;
    //if (sellerId == null) return;

    try {
      final snapshot = await dataref.get();
      if (snapshot.exists) {
        final List<SkillModel> loadedsellerInfo = [];
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final sellerInfo = SkillModel.fromMap(Map<String, dynamic>.from(value));
          if (sellerInfo.sellerId == sellerId) {
            loadedsellerInfo.add(sellerInfo);
          }
        });
        _sellerInfo = loadedsellerInfo;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }

  }
  Future<void> updateData(SkillModel updateSkill) async {
    final sellerId = auth.currentUser!.uid;
    if (updateSkill.skillId.isEmpty || updateSkill.sellerId != sellerId) {
      throw Exception("Unauthorized or missing Skill ID");
    }

    // Find the correct path to update
    final snapshot = await dbRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      String? correctPath;

      data.forEach((key, value) {
        if (value['skillId'] == updateSkill.skillId) {
          correctPath = key;
        }
      });

      if (correctPath != null) {
        await dbRef.child(correctPath!).update(updateSkill.toMap());
        notifyListeners();
        await fetchData();
      } else {
        throw Exception("Skill not found in database");
      }
    }
  }

  // Future<void> deleteData(String skillId) async {
  //   final sellerId = auth.currentUser!.uid;
  //
  //   final snapshot = await dbRef.child(skillId).get();
  //   if (snapshot.exists) {
  //     final data = Map<String, dynamic>.from(snapshot.value as Map);
  //     if (data['sellerId'] == sellerId) {
  //       await dbRef.child(skillId).remove();
  //       notifyListeners();
  //       await fetchData();
  //     } else {
  //       throw Exception("You are not authorized to delete this skill.");
  //     }
  //   } else {
  //     throw Exception("Skill not found.");
  //   }
  // }





//  Future<void> updateData(SkillModel updateSkill)async{
 // updateSkill.sellerId=auth.currentUser!.uid;
 // await dbRef.child(updateSkill.skillId).update(updateSkill.toMap());
 // notifyListeners();
 // await fetchData();
 //  }

  // Future<void> updateSkill(SkillModel updatedSkill) async {
  //   try {
  //     // Ensure we have a skillId to update
  //     if (updatedSkill.skillId == null || updatedSkill.skillId.isEmpty) {
  //       throw Exception('Skill ID is missing for update operation');
  //     }
  //
  //     // Make sure the seller ID matches current user
  //     updatedSkill.sellerId = auth.currentUser!.uid;
  //
  //     // Update the skill in Firebase
  //     await dbRef.child(updatedSkill.skillId).update(updatedSkill.toMap());
  //     notifyListeners();
  //
  //     // Refresh the skills list
  //     await fetchData();
  //     // Return success
  //     return Future.value();
  //   } catch (e) {
  //     debugPrint('Error updating skill: $e');
  //     return Future.error(e);
  //   }
  // }
  //
  // // Method to get a skill by ID
  // SkillModel? getSkillById(String skillId) {
  //   try {
  //     return _skills.firstWhere((skill) => skill.skillId == skillId);
  //
  //   } catch (e) {
  //     return null;
  //   }
  // }
  Future<void> deleteData(String skillId) async {
    final sellerId = auth.currentUser!.uid;

    // Find the correct path to delete
    final snapshot = await dbRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      String? correctPath;

      data.forEach((key, value) {
        if (value['skillId'] == skillId && value['sellerId'] == sellerId) {
          correctPath = key;
        }
      });

      if (correctPath != null) {
        await dbRef.child(correctPath!).remove();
        notifyListeners();
        await fetchData();
      } else {
        throw Exception("Skill not found or unauthorized");
      }
    }
  }
}
