import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AcceptedBid extends ChangeNotifier {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> acceptBid({
    required String bidId,
    required String buyerId,
    required String skillId,
    required double biddingAmount,
    //required String additionalNotes,
    required DateTime deliveryDate,
    BuildContext? context, // Make context optional since we're not showing dialogs
  }) async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Get the bid details from Firebase
      final bidSnapshot = await dbRef.child('Bidding').child(bidId).get();
      if (!bidSnapshot.exists) {
        throw Exception('Bid not found');
      }

      final bidData = bidSnapshot.value as Map<dynamic, dynamic>;

      await dbRef.child('AcceptedBids').push().set({
        'sellerId': currentUser.uid,
        'buyerId': buyerId,
        'skillId': skillId,
        'biddingAmount': biddingAmount,
       // 'additionalNotes': additionalNotes,
        'deliveryDate': deliveryDate.millisecondsSinceEpoch,
        'acceptanceDate': DateTime.now().millisecondsSinceEpoch,
        // Include any other relevant fields from the original bid
        ...bidData.map((key, value) => MapEntry(key.toString(), value)),
      });

      // Remove the bid from the Bidding node
      await dbRef.child('Bidding').child(bidId).remove();

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid accepted successfully!')),
        );
      }
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept bid: ${e.toString()}')),
        );
      }
      rethrow; // Re-throw the error if you want to handle it elsewhere
    }
    notifyListeners();
  }

  // You might want to add a method to get the required data from Firebase
  Future<Map<String, dynamic>> getBidDetails(String bidId) async {
    final snapshot = await dbRef.child('Bidding').child(bidId).get();
    if (!snapshot.exists) {
      throw Exception('Bid not found');
    }
    final data = snapshot.value as Map<dynamic, dynamic>;
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
}