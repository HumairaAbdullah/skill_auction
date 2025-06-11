import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_auction/custom_widgets/custom_color.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:skill_auction/firebase_model/acceptedbid.dart';
import 'package:skill_auction/firebase_model/user_model.dart';
import 'package:skill_auction/firebase_model/skill_model.dart';
import 'package:skill_auction/screens/seller_dashboard/buyerprofile_forseller.dart';

class BidPage extends StatefulWidget {
  const BidPage({super.key});

  @override
  State<BidPage> createState() => _BidPageState();
}

class _BidPageState extends State<BidPage> {
  final CustomColor customColor = CustomColor();
  final dbRef = FirebaseDatabase.instance.ref();
  final auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> bids = [];
  Map<String, UserModel> buyers = {};
  Map<String, SkillModel> skills = {};
  bool isLoading = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    fetchBids();
  }

  Future<void> fetchBuyerInfo(String userId) async {
    if (buyers.containsKey(userId)) return;

    try {
      final snapshot = await dbRef.child('auctionusers').child(userId).get();
      if (snapshot.exists) {
        final buyerInfo = UserModel.fromMap(
          Map<String, dynamic>.from(snapshot.value as Map),
        );
        setState(() {
          buyers[userId] = buyerInfo;
        });
      }
    } catch (e) {
      print('Error fetching buyer info: $e');
    }
  }

  Future<void> fetchSkillInfo(String skillId) async {
    if (skills.containsKey(skillId)) return;

    try {
      final snapshot = await dbRef.child('sellerskills').child(skillId).get();
      if (snapshot.exists) {
        final skillInfo = SkillModel.fromMap(
          Map<String, dynamic>.from(snapshot.value as Map),
        );
        setState(() {
          skills[skillId] = skillInfo;
        });
      }
    } catch (e) {
      print('Error fetching skill info: $e');
    }
  }

  Future<void> fetchBids() async {
    try {
      setState(() => isLoading = true);
      final currentSellerId = auth.currentUser?.uid;
      if (currentSellerId == null) {
        print('No user logged in');
        setState(() => isLoading = false);
        return;
      }

      print('Fetching bids for seller: $currentSellerId');

      final snapshot = await dbRef.child('Bidding').get();

      if (!snapshot.exists) {
        print('No bids found in database at all');
        setState(() => isLoading = false);
        return;
      }

      final bidsData = snapshot.value as Map<dynamic, dynamic>;
      print('Total bids in database: ${bidsData.length}');

      // final loadedBids = bidsData.entries
      //     .where((entry) => entry.value['sellerId'] == currentSellerId)
      //     .map((entry) {
      //   final value = entry.value as Map<dynamic, dynamic>;
      //   return {
      //     'bidId': entry.key,
      //     'userId': value['userId'] ?? '',
      //     'skillId': value['skillId'] ?? '',
      //     'biddingAmount': (value['biddingAmount'] is String)
      //         ? double.tryParse(value['biddingAmount']) ?? 0.0
      //         : (value['biddingAmount'] ?? 0.0).toDouble(),
      //     'timestamp': value['timestamp'] is int
      //         ? value['timestamp']
      //         : int.tryParse(value['timestamp'].toString()) ?? 0,
      //     'sellerId': value['sellerId'] ?? '',
      //   };
      // }).toList();

      final loadedBids = bidsData.entries
          .where((entry) {
        final value = entry.value as Map<dynamic, dynamic>;
        return value['sellerId'] == currentSellerId &&
            (value['status'] == null || value['status'] != 'accepted');
      })
          .map((entry) {
        final value = entry.value as Map<dynamic, dynamic>;
        return {
          'bidId': entry.key,
          'userId': value['userId'] ?? '',
          'skillId': value['skillId'] ?? '',
          'biddingAmount': (value['biddingAmount'] is String)
              ? double.tryParse(value['biddingAmount']) ?? 0.0
              : (value['biddingAmount'] ?? 0.0).toDouble(),
          'timestamp': value['timestamp'] is int
              ? value['timestamp']
              : int.tryParse(value['timestamp'].toString()) ?? 0,
          'sellerId': value['sellerId'] ?? '',
          'status': value['status'] ?? 'pending', // Add status to the bid map
        };
      })
          .toList();

      print('Found ${loadedBids.length} bids for current seller');

      // Fetch buyer and skill info for each bid
      for (var bid in loadedBids) {
        await fetchBuyerInfo(bid['userId']);
        await fetchSkillInfo(bid['skillId']);
      }

      // Sort bids by timestamp (newest first)
      loadedBids.sort(
          (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

      setState(() {
        bids = loadedBids;
        isLoading = false;
        isRefreshing = false;
      });
    } catch (e) {
      print('Error fetching bids: $e');
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bids: ${e.toString()}')),
      );
    }
  }

  Future<void> acceptBid(Map<String, dynamic> bid) async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) return;

      // Create a new accepted bid record
      await dbRef.child('AcceptedBids').push().set({
        'bidId': bid['bidId'],
        'skillId': bid['skillId'],
        'sellerId': bid['sellerId'],
        'buyerId': bid['userId'],
        'originalBidTimestamp': bid['timestamp'],
        'acceptedAt': DateTime.now().millisecondsSinceEpoch,
        'amount': bid['biddingAmount'],
      });

      // Remove the bid from the Bidding node entirely
      await dbRef.child('Bidding').child(bid['bidId']).remove();

      // Remove the bid from the local list
      if (mounted) {
        setState(() {
          bids.removeWhere((b) => b['bidId'] == bid['bidId']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid accepted successfully!')),
        );
      }
    } catch (e) {
      print('Error accepting bid: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept bid: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _refreshBids() async {
    setState(() => isRefreshing = true);
    await fetchBids();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: customColor.white,
      appBar: AppBar(
        backgroundColor: customColor.peach,
        title: Text(
          'All Bids',
          style: TextStyle(
            color: customColor.purpleText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: customColor.purpleText),
            onPressed: _refreshBids,
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(customColor.purpleText),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading bids...',
                    style: TextStyle(
                      color: customColor.purpleText,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshBids,
              color: customColor.peach,
              backgroundColor: customColor.white,
              child: bids.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.money_off,
                            size: 64,
                            color: customColor.purpleText,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No bids found',
                            style: TextStyle(
                              color: customColor.purpleText,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'When you receive bids, they will appear here',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: customColor.purpleText,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      itemCount: bids.length,
                      itemBuilder: (context, index) {
                        final bid = bids[index];
                        final date = DateTime.fromMillisecondsSinceEpoch(
                            bid['timestamp']);
                        final formattedDate =
                            DateFormat('MMM dd, yyyy - hh:mm a').format(date);

                        final buyer = buyers[bid['userId']];
                        final skill = skills[bid['skillId']];

                        return Card(
                          margin:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              // Add bid details navigation if needed
                            },
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Bid Amount:',
                                        style: TextStyle(
                                          color: customColor.purpleText,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '\$${bid['biddingAmount'].toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: customColor.purpleText,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Buyer:',
                                        style: TextStyle(
                                          color: customColor.purpleText,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(context,
                                              MaterialPageRoute(
                                                  builder: (context) {
                                            return BuyerprofileForseller(
                                                userId: buyer!.uId);
                                          }));
                                        },
                                        child: Row(
                                          children: [
                                            Text(
                                              " ${buyer?.firstname ?? 'Loading...'} ${buyer?.lastName ?? 'Loading...'}",
                                              style: TextStyle(
                                                  color: customColor.purpleText,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor:
                                                      customColor.purpleText),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Related to Skill:',
                                        style: TextStyle(
                                          color: customColor.purpleText,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        skill?.skillTitle ?? 'Loading...',
                                        style: TextStyle(
                                          color: customColor.purpleText,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Received: $formattedDate',
                                    style: TextStyle(
                                      color: customColor.purpleText,
                                      fontSize: 12,
                                    ),
                                  ),
                                  // SizedBox(height: 10,),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Consumer<AcceptedBid>(
                                          builder: (context, provider, child) {
                                        return ElevatedButton(
                                            onPressed: () {
                                              acceptBid(bid);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                            ),
                                            child: Text(
                                              'Accept',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ));
                                      }),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
