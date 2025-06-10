import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:skill_auction/custom_widgets/custom_color.dart';
import 'package:intl/intl.dart'; // For date formatting

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
  bool isLoading = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    fetchBids();
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

      final loadedBids = bidsData.entries
          .where((entry) => entry.value['sellerId'] == currentSellerId)
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

      print('Found ${loadedBids.length} bids for current seller');

      // Sort bids by timestamp (newest first)
      loadedBids.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

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
              valueColor: AlwaysStoppedAnimation<Color>(customColor.purpleText),
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
                color: customColor.purpleText.withOpacity(0.5),
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
                  color: customColor.purpleText.withOpacity(0.7),
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
            final date = DateTime.fromMillisecondsSinceEpoch(bid['timestamp']);
            final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(date);

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User ID',
                                style: TextStyle(
                                  color: customColor.purpleText,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                bid['userId'].toString().substring(0, 8) + '...',
                                style: TextStyle(
                                  color: customColor.purpleText,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Skill ID',
                                style: TextStyle(
                                  color: customColor.purpleText,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                bid['skillId'].toString().substring(0, 8) + '...',
                                style: TextStyle(
                                  color: customColor.purpleText,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Received:'
                            ' $formattedDate',
                        style: TextStyle(
                          color: customColor.purpleText,
                          fontSize: 12,
                        ),
                      ),
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