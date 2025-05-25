import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:skill_auction/firebase_model/user_model.dart';

class SellerProfileProvider extends ChangeNotifier {
  bool isLoading = false;
  List<UserModel> _currentUser=[];

  List<UserModel> get currentUser => _currentUser;

  final DatabaseReference userRef = FirebaseDatabase.instance.ref('auctionusers');
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> fetchSellerInfo() async {
    final sellerId = auth.currentUser!.uid;
    isLoading = true;
    notifyListeners();

    try {
      final snapshot = await userRef.child(sellerId).get();
      if (snapshot.exists) {
        final sellerInfo = UserModel.fromMap(
          Map<String, dynamic>.from(snapshot.value as Map),
        );
        _currentUser = [sellerInfo];
      } else {
        _currentUser = [];
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      _currentUser = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}