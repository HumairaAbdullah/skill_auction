import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:skill_auction/firebase_model/user_model.dart';

class SellerProfileProvider extends ChangeNotifier{
bool isLoading=false;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  final DatabaseReference userRef = FirebaseDatabase.instance.ref('auctionusers');
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> fetchCurrentUser() async {
    isLoading = true;
    notifyListeners();

    try {
      final User? firebaseUser = auth.currentUser;
      if (firebaseUser == null) return;

      final snapshot = await userRef.orderByChild('uid').equalTo(firebaseUser.uid).get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        // Since we're querying by uid, there should be only one match
        final userData = data.values.first;
        _currentUser = UserModel.fromMap(Map<dynamic, dynamic>.from(userData));
      } else {
        _currentUser = null;
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      // You might want to show an error message to the user
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
