import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skill_auction/custom_widgets/custom_color.dart';
import 'package:skill_auction/firebase_model/skill_model.dart';
import 'package:skill_auction/firebase_model/user_model.dart';

class BuyerprofileForseller extends StatefulWidget {
  final String userId;

  const BuyerprofileForseller({super.key, required this.userId});

  @override
  State<BuyerprofileForseller> createState() => _BuyerprofileForsellerState();
}

class _BuyerprofileForsellerState extends State<BuyerprofileForseller> {
  final CustomColor customColor = CustomColor();
  final dbRef = FirebaseDatabase.instance.ref();
  final auth = FirebaseAuth.instance;

  UserModel? userModel;
  List<Map<String, dynamic>> bids = [];
  bool isLoading = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    await Future.wait([
      fetchBuyerInfo(),
      fetchBids(),
    ]);
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> fetchBuyerInfo() async {
    try {
      final snapshot = await dbRef.child('auctionusers').child(widget.userId).get();
      if (snapshot.exists && mounted) {
        setState(() {
          userModel = UserModel.fromMap(
            Map<String, dynamic>.from(snapshot.value as Map),
          );
        });
      }
    } catch (e) {
      print('Error fetching buyer info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load buyer information')),
        );
      }
    }
  }

  Future<void> fetchBids() async {
    try {
      final currentSellerId = auth.currentUser?.uid;
      if (currentSellerId == null) return;

      final snapshot = await dbRef.child('Bidding').get();
      if (!snapshot.exists) return;

      final bidsData = snapshot.value as Map<dynamic, dynamic>;
      final loadedBids = bidsData.entries
          .where((entry) =>
      entry.value['sellerId'] == currentSellerId &&
          entry.value['userId'] == widget.userId)
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
        };
      }).toList();

      loadedBids.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

      if (mounted) {
        setState(() {
          bids = loadedBids;
          isRefreshing = false;
        });
      }
    } catch (e) {
      print('Error fetching bids: $e');
      if (mounted) {
        setState(() => isRefreshing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bids: ${e.toString()}')),
        );
      }
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

      // Update the original bid status
      await dbRef.child('Bidding').child(bid['bidId']).update({
        'status': 'accepted',
      });

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

  Future<void> _refreshData() async {
    setState(() => isRefreshing = true);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: customColor.peach,
        centerTitle: true,
        title: Text(
          'Buyer Information',
          style: TextStyle(
            color: customColor.purpleText,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildBuyerProfileCard(),
              const SizedBox(height: 30),
              _buildBidsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuyerProfileCard() {
    return Card(
      color: customColor.peach,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: userModel?.imagePath != null
                      ? MemoryImage(base64Decode(userModel!.imagePath!))
                      : null,
                  child: userModel?.imagePath == null
                      ? const Icon(Icons.person, size: 50, color: Colors.red)
                      : null,
                ),
                const SizedBox(width: 16),
                Text(
                  '${userModel?.firstname ?? ''} ${userModel?.lastName ?? ''}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: customColor.purpleBlue,
                  ),
                ),
              ],
            ),
            if (userModel?.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  userModel!.description,
                  style: TextStyle(
                    color: customColor.purpleText,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBidsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bidding on your Skills',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: customColor.purpleBlue,
          ),
        ),
        const SizedBox(height: 10),
        if (bids.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No bids found from this buyer',
                style: TextStyle(
                  color: customColor.purpleText,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: bids.length,
              itemBuilder: (context, index) => _buildBidCard(bids[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildBidCard(Map<String, dynamic> bid) {
    final date = DateTime.fromMillisecondsSinceEpoch(bid['timestamp']);
    final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bid Amount',
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
            const SizedBox(height: 12),
            Text(
              'Received: $formattedDate',
              style: TextStyle(
                color: customColor.purpleText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton(
            //     onPressed: () => acceptBid(bid),
            //     child: const Text('Accept Bid'),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: customColor.peach,
            //       foregroundColor: customColor.purpleText,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}