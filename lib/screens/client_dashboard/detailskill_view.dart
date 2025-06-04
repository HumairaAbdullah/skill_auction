import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:skill_auction/custom_widgets/custom_snackbar.dart';
import 'package:skill_auction/custom_widgets/custom_textfield.dart';
import 'package:skill_auction/custom_widgets/purple_text.dart';
import 'package:skill_auction/custom_widgets/purpleblue_text.dart';
import 'package:skill_auction/custom_widgets/white_text.dart';
import 'package:skill_auction/firebase_model/sellercrud.dart';
import 'package:skill_auction/firebase_model/skill_model.dart';
import 'package:skill_auction/custom_widgets/custom_color.dart';

class DetailSkillView extends StatefulWidget {
  final String skillId;

  const DetailSkillView({
    super.key,
    required this.skillId,
  });

  @override
  State<DetailSkillView> createState() => _DetailSkillViewState();
}

class _DetailSkillViewState extends State<DetailSkillView> {
  final CustomColor customColor = CustomColor();
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref('sellerskills');
  final DatabaseReference bidsRef = FirebaseDatabase.instance.ref('Bidding');
  final FirebaseAuth auth = FirebaseAuth.instance;

  final TextEditingController biddingController = TextEditingController();
  bool showBiddingField = false;
  bool isLoading = true;
  SkillModel? skillDetails;
  Stream<Map<String, dynamic>>? bidStream;

  @override
  void initState() {
    super.initState();
    if (widget.skillId.isEmpty) {
      debugPrint('Error: Empty skillId provided');
      setState(() => isLoading = false);
    } else {
      fetchSkillDetail();
      initializeBidStream();
    }
  }

  void initializeBidStream() {
    final currentUserId = auth.currentUser?.uid ?? '';
    bidStream = fetchBidAmount(widget.skillId, currentUserId);
  }

  Future<void> fetchSkillDetail() async {
    try {
      setState(() => isLoading = true);
      final snapshot = await dbRef.child(widget.skillId).get();

      if (snapshot.exists && snapshot.value != null) {
        // First convert to Map<dynamic, dynamic> then to Map<String, dynamic>
        final dynamicData = snapshot.value as Map<dynamic, dynamic>;
        final data = Map<String, dynamic>.fromEntries(
            dynamicData.entries.map((e) =>
                MapEntry(e.key.toString(), e.value)
            )
        );

        data['skillId'] = widget.skillId;

        setState(() {
          skillDetails = SkillModel.fromMap(data);
          isLoading = false;
        });
      } else {
        debugPrint('Skill not found for ID: ${widget.skillId}');
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Skill not found')));
      }
    } catch (e) {
      debugPrint('Error fetching skill: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error loading skill details')));
    }
  }

  Stream<Map<String, dynamic>> fetchBidAmount(String skillId, String currentUserId) {
    final skillBidsRef = FirebaseDatabase.instance.ref('SkillBids/$skillId');

    return skillBidsRef.orderByChild('timestamp').onValue.map((event) {
      final Map<String, dynamic> result = {
        'allBids': [],
        'currentUserBid': null,
        'highestBid': 0.0,
        'currentUserHighestBid': 0.0,
      };

      if (event.snapshot.exists) {
        final dynamicData = event.snapshot.value;

        if (dynamicData != null) {
          // Convert dynamic data to proper Map format
          final bidsData = (dynamicData as Map<dynamic, dynamic>).map(
                  (key, value) => MapEntry(
                  key.toString(),
                  value as Map<dynamic, dynamic>
              )
          );

          final allBids = bidsData.values.map((bid) {
            final convertedBid = Map<String, dynamic>.from(bid);
            convertedBid['biddingAmount'] = (convertedBid['biddingAmount'] as num).toDouble();
            return convertedBid;
          }).toList();

          result['allBids'] = allBids;

          final userBids = allBids.where((bid) => bid['userId'] == currentUserId).toList();
          if (userBids.isNotEmpty) {
            userBids.sort((a, b) => b['biddingAmount'].compareTo(a['biddingAmount']));
            result['currentUserBid'] = userBids.first;
            result['currentUserHighestBid'] = userBids.first['biddingAmount'];
          }

          if (allBids.isNotEmpty) {
            allBids.sort((a, b) => b['biddingAmount'].compareTo(a['biddingAmount']));
            result['highestBid'] = allBids.first['biddingAmount'];
          }
        }
      }
      return result;
    });
  }

  Future<void> saveBidAmount() async {
    try {
      final bidAmount = double.tryParse(biddingController.text);
      if (bidAmount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackbar.show(content: const Text('Please enter a valid bid amount')),
        );
        return;
      }

      if (skillDetails == null) return;

      // Validate against minimum bid
      if (bidAmount < skillDetails!.minBid) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackbar.show(
              content: Text('Bid must be at least \$${skillDetails!.minBid}')),
        );
        return;
      }

      // Get current highest bid
      final highestBidSnapshot = await FirebaseDatabase.instance
          .ref('SkillBids/${widget.skillId}')
          .orderByChild('biddingAmount')
          .limitToLast(1)
          .once();

      double currentHighestBid = skillDetails!.minBid;

      if (highestBidSnapshot.snapshot.exists) {
        final data = highestBidSnapshot.snapshot.value as Map<dynamic, dynamic>;
        data.values.forEach((bid) {
          final amount = (bid['biddingAmount'] as num).toDouble();
          if (amount > currentHighestBid) {
            currentHighestBid = amount;
          }
        });
      }

      // Validate against current highest bid
      if (bidAmount <= currentHighestBid) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackbar.show(
              content: Text('Your bid must be higher than \$$currentHighestBid')),
        );
        return;
      }

      final currentUser = auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackbar.show(content: const Text('You must be logged in to place a bid')),
        );
        return;
      }

      final String id = bidsRef.push().key ?? DateTime.now().millisecondsSinceEpoch.toString();
      final timestamp = ServerValue.timestamp;

      // Save to main bids collection
      await bidsRef.child(id).set({
        'bidId': id,
        'userId': currentUser.uid,
        'skillId': widget.skillId,
        'biddingAmount': bidAmount,
        'timestamp': timestamp,
      });

      // Also save under skill-specific path for easier querying
      await FirebaseDatabase.instance
          .ref('SkillBids/${widget.skillId}/$id')
          .set({
        'bidId': id,
        'userId': currentUser.uid,
        'biddingAmount': bidAmount,
        'timestamp': timestamp,
      });

      biddingController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackbar.show(content: const Text('Bid placed successfully!')),
      );
    } catch (e) {
      debugPrint('Error saving bid: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place bid. Please try again.')),
      );
    }
  }

  Widget buildBidTextField() {
    return TextField(
      keyboardType: TextInputType.number,
      cursorColor: customColor.purpleText,
      controller: biddingController,
      decoration: InputDecoration(
        labelText: 'Bidding',
        hintText: 'Enter amount higher than current bid',
        hintStyle: TextStyle(color: customColor.purpleText),
        labelStyle: TextStyle(color: customColor.purpleBlue),
        prefixIcon: const Icon(FontAwesomeIcons.handHoldingDollar),
        suffix: IconButton(
          onPressed: saveBidAmount,
          icon: Icon(
            FontAwesomeIcons.arrowRight,
            color: customColor.purpleText,
          ),
        ),
        prefixIconColor: customColor.purpleText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: customColor.purpleBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: customColor.purpleBlue),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget buildBidStatus(AsyncSnapshot<Map<String, dynamic>> snapshot) {
    final bidData = snapshot.data ?? {
      'allBids': [],
      'currentUserBid': null,
      'highestBid': 0.0,
      'currentUserHighestBid': 0.0,
    };

    final highestBid = bidData['highestBid'] as double;
    final currentUserBid = bidData['currentUserBid'] as Map<String, dynamic>?;
    final currentUserHighestBid = bidData['currentUserHighestBid'] as double;

    return Column(
      children: [
        if (highestBid > 0)
          Container(
            color: highestBid == currentUserHighestBid
                ? Colors.green
                : customColor.purpleText,
            height: 50,
            width: double.infinity,
            child: Center(
              child: WhiteText(
                data: 'Highest bid: \$${highestBid.toStringAsFixed(2)}',
              ),
            ),
          ),

        if (currentUserBid != null) ...[
          const SizedBox(height: 20),
          Container(
            color: customColor.purpleText,
            height: 50,
            width: double.infinity,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WhiteText(
                    data: 'Your bid: \$${currentUserBid['biddingAmount'].toStringAsFixed(2)}',
                  ),
                  if (currentUserHighestBid < highestBid)
                    WhiteText(
                      data: '(You are not the highest bidder)',
                    ),
                ],
              ),
            ),
          ),
        ],
SizedBox(height: 20,),
        if (currentUserBid == null && bidData['allBids'].isNotEmpty)
          const SizedBox(height: 20),
        Container(
          color: customColor.peach,
          height: 50,
          width: double.infinity,
          child: Center(
            child: PurpleblueText(
              data: 'Bidding has started - place your bid!',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFffd7f3),
        centerTitle: true,
        toolbarHeight: 90,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PurpleblueText(data: 'Skill Auction'),
            Text(
              'Need a Pro? Bid Smart, Hire Faster!',
              style: TextStyle(
                color: customColor.purpleText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : skillDetails == null
            ? const Center(child: Text('Skill not found'))
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (skillDetails!.imagePath.isNotEmpty)
                Image.memory(
                  base64Decode(skillDetails!.imagePath),
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: Text(
                  overflow: TextOverflow.ellipsis,
                  skillDetails!.skillTitle,
                  style: TextStyle(
                    fontSize: 18,
                    color: customColor.purpleBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 5,),
              // this will show the seller name
              Consumer<SellerCrud>(
                builder: (context , provider,child){
                  final user = provider.currentUser.first;
                  return Row(
                    children: [
                      CircleAvatar(),
                      SizedBox(width: 4,),
                      InkWell(
                        onTap: (){},
                        child: Text(
                          skillDetails!.sellerName,
                          style: TextStyle(
                            fontSize: 17,
                            color: customColor.purpleText,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: customColor.purpleBlue,
                          ),
                        ),
                      ),
                    ],
                  );
                },

              ),
              const SizedBox(height: 10),
              Text(
                skillDetails!.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),

              if (showBiddingField) buildBidTextField(),
              if (showBiddingField) const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      color: customColor.purpleBlue,
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              showBiddingField = true;
                            });
                          },
                          child: const Text(
                            "Start Bidding",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Container(
                      height: 40,
                      color: customColor.purpleBlue,
                      child: Center(
                        child: Text(
                          "Min Bid: \$${skillDetails!.minBid}",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              StreamBuilder<Map<String, dynamic>>(
                stream: bidStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return const Text('Error loading bids');
                  }

                  return buildBidStatus(snapshot);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}