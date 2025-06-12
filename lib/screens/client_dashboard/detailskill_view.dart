import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
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
import 'package:skill_auction/firebase_model/user_model.dart';
import 'package:skill_auction/screens/client_dashboard/cart_page.dart';
import 'package:skill_auction/screens/client_dashboard/sellerprofile_forbuyers.dart';
import 'package:skill_auction/screens/seller_dashboard/seller_information.dart';

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
  UserModel? sellerDetails;
  // SkillModel? skillModel;
  final CustomColor customColor = CustomColor();
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref('sellerskills');
  final DatabaseReference bidsRef = FirebaseDatabase.instance.ref('Bidding');
  final FirebaseAuth auth = FirebaseAuth.instance;
  String? _fileName;
  PlatformFile? _pickedFile;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true, // This ensures we get the file bytes
      );

      if (result == null || result.files.isEmpty) {
        // User canceled the picker
        return;
      }

      PlatformFile file = result.files.first;

      // Validate file size (adjust limit as needed)
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (file.size > maxSize) {
        throw Exception("File size exceeds 10MB limit");
      }

      // Check if we have file bytes
      if (file.bytes == null) {
        // Try to read the file path if bytes aren't available
        if (file.path != null) {
          final fileData = await File(file.path!).readAsBytes();
          file = PlatformFile(
            name: file.name,
            size: file.size,
            path: file.path,
            bytes: fileData,
            identifier: file.identifier,
            readStream: file.readStream,
            //extension: file.extension,
          );
        } else {
          throw Exception("Couldn't access file content");
        }
      }

      // Get current user ID
      final currentUser = FirebaseAuth.instance.currentUser?.uid;
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.extension ?? 'file';
      final uniqueFileName = '${currentUser}_$timestamp.$extension';

      // Store in Firebase
      await bidsRef.child(currentUser).update({
        'buyerRequirements': base64Encode(file.bytes!),
        'fileName': uniqueFileName,
        'fileType': file.extension ?? 'unknown',
        'uploadTime': ServerValue.timestamp,
        'fileSize': file.size,
        'originalFileName': file.name,
      });

      setState(() {
        _pickedFile = file;
        _fileName = file.name;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackbar.show(
              content: const Text('File uploaded successfully!')),
        );
      }
    } catch (e) {
      debugPrint('File upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackbar.show(
            content: Text('Upload failed: ${e.toString()}'),
          ),
        );
      }
    }
  }

  final TextEditingController biddingController = TextEditingController();
  bool showBiddingField = false;
  bool isLoading = true;
  SkillModel? skillDetails;
  Stream<Map<String, dynamic>>? bidStream;
  Map<String, dynamic>? acceptedBid;
  bool isCheckingAcceptedBid = false;

  @override
  void initState() {
    super.initState();
    if (widget.skillId.isEmpty) {
      debugPrint('Error: Empty skillId provided');
      setState(() => isLoading = false);
    } else {
      debugPrint('DetailSkillView initialized with skillId: ${widget.skillId}');
      fetchSkillDetail();
      initializeBidStream();
      fetchAcceptedBid();
      checkForAcceptedBid();
    }
  }

  void initializeBidStream() {
    final currentUserId = auth.currentUser?.uid ?? '';
    bidStream = fetchBidAmount(widget.skillId, currentUserId);
  }

  Future<void> fetchSkillDetail() async {
    try {
      setState(() => isLoading = true);

      //  we can connect to the database reference
      debugPrint(
          'Attempting to fetch skill from path: sellerskills/${widget.skillId}');

      // check if the node exists using once() method (more reliable)
      final DatabaseEvent event = await dbRef.child(widget.skillId).once();
      final DataSnapshot snapshot = event.snapshot;

      debugPrint('Snapshot exists: ${snapshot.exists}');
      debugPrint('Snapshot value: ${snapshot.value}');

      if (snapshot.exists && snapshot.value != null) {
        debugPrint('Raw snapshot value type: ${snapshot.value.runtimeType}');

        final dynamicData = snapshot.value as Map<dynamic, dynamic>;
        final data = Map<String, dynamic>.fromEntries(dynamicData.entries
            .map((e) => MapEntry(e.key.toString(), e.value)));

        // Ensure skillId is included
        data['skillId'] = widget.skillId;

        debugPrint('Processed skill data: $data');

        setState(() {
          skillDetails = SkillModel.fromMap(data);
          isLoading = false;
        });

        debugPrint(
            'SkillModel created successfully: ${skillDetails?.skillTitle}');

        // Fetch seller details after skill details are loaded
        if (skillDetails != null && skillDetails!.sellerId.isNotEmpty) {
          await fetchSellerDetails(skillDetails!.sellerId);
        }
      } else {
        debugPrint('Skill not found for ID: ${widget.skillId}');

        // Let's also check if the skill exists anywhere in the sellerskills node
        await debugSearchForSkill();

        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              CustomSnackbar.show(content: Text('Skill not found')));
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching skill: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error loading skill details')));
      }
    }
  }

  // Debug method to search for the skill in the entire sellerskills node
  Future<void> debugSearchForSkill() async {
    try {
      debugPrint(
          'Searching for skill ${widget.skillId} in entire sellerskills node...');
      final DatabaseEvent event = await dbRef.once();
      final DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        final allSkills = snapshot.value as Map<dynamic, dynamic>;
        debugPrint('Total skills in database: ${allSkills.length}');

        // Check if our skill ID exists as a key
        if (allSkills.containsKey(widget.skillId)) {
          debugPrint('Found skill with matching key!');
          debugPrint('Skill data: ${allSkills[widget.skillId]}');
        } else {
          debugPrint(
              'Skill ID not found as direct key. Checking all skills...');

          // Search through all skills to see if any match
          bool found = false;
          allSkills.forEach((key, value) {
            if (key.toString() == widget.skillId) {
              debugPrint('Found matching skill with key: $key');
              debugPrint('Skill data: $value');
              found = true;
            }
          });

          if (!found) {
            debugPrint(
                'Skill ID ${widget.skillId} not found anywhere in the database');
            debugPrint('Available skill IDs: ${allSkills.keys.toList()}');
          }
        }
      } else {
        debugPrint('No skills found in sellerskills node at all');
      }
    } catch (e) {
      debugPrint('Error during debug search: $e');
    }
  }

  Future<void> fetchSellerDetails(String sellerId) async {
    try {
      debugPrint('Fetching seller details for ID: $sellerId');
      final DatabaseEvent event =
          await FirebaseDatabase.instance.ref('auctionusers/$sellerId').once();
      final DataSnapshot sellerSnapshot = event.snapshot;

      if (sellerSnapshot.exists) {
        final sellerData =
            Map<String, dynamic>.from(sellerSnapshot.value as Map);
        setState(() {
          sellerDetails = UserModel.fromMap(sellerData);
        });
        debugPrint(
            'Seller details fetched successfully: ${sellerDetails?.firstname}');
      } else {
        debugPrint('Seller not found for ID: $sellerId');
      }
    } catch (e) {
      debugPrint('Error fetching seller details: $e');
    }
  }

  Future<void> saveBidAmount() async {
    try {
      final bidAmount = double.tryParse(biddingController.text);
      if (bidAmount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackbar.show(
              content: const Text('Please enter a valid bid amount')),
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
      final highestBidEvent = await FirebaseDatabase.instance
          .ref('Bidding/${widget.skillId}')
          .orderByChild('biddingAmount')
          .limitToLast(1)
          .once();

      double currentHighestBid = skillDetails!.minBid;

      if (highestBidEvent.snapshot.exists) {
        final data = highestBidEvent.snapshot.value as Map<dynamic, dynamic>;
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
              content:
                  Text('Your bid must be higher than \$$currentHighestBid')),
        );
        return;
      }

      final currentUser = auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackbar.show(
              content: const Text('You must be logged in to place a bid')),
        );
        return;
      }

      final String id = bidsRef.push().key ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final timestamp = ServerValue.timestamp;

      // Save to main bids collection
      await bidsRef.child(id).set({
        'bidId': id,
        'userId': currentUser.uid,
        'skillId': widget.skillId,
        'biddingAmount': bidAmount,
        'timestamp': timestamp,
        'sellerId': skillDetails!.sellerId,
      });

      // //  save under skill-specific path for easier querying
      // await FirebaseDatabase.instance
      //     .ref('SkillBids/${widget.skillId}/$id')
      //     .set({
      //   'bidId': id,
      //   'userId': currentUser.uid,
      //   'biddingAmount': bidAmount,
      //   'timestamp': timestamp,
      // });

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

  Stream<Map<String, dynamic>> fetchBidAmount(
      String skillId, String currentUserId) {
    // Query bids specifically for this skill
    final skillBidsRef = FirebaseDatabase.instance
        .ref('Bidding')
        .orderByChild('skillId')
        .equalTo(skillId);

    return skillBidsRef.onValue.map((event) {
      final Map<String, dynamic> result = {
        'allBids': [],
        'currentUserBid': null,
        'highestBid':
            skillDetails?.minBid ?? 0.0, // Default to min bid if no bids
        'currentUserHighestBid': 0.0,
      };

      if (event.snapshot.exists) {
        final dynamicData = event.snapshot.value;

        if (dynamicData != null) {
          // Convert dynamic data to proper Map format
          final bidsData = (dynamicData as Map<dynamic, dynamic>).map(
              (key, value) =>
                  MapEntry(key.toString(), value as Map<dynamic, dynamic>));

          // Convert all bids and filter for this skill (redundant but safe)
          final allBids = bidsData.values
              .where((bid) => bid['skillId'] == skillId)
              .map((bid) {
            final convertedBid = Map<String, dynamic>.from(bid);
            convertedBid['biddingAmount'] =
                (convertedBid['biddingAmount'] as num).toDouble();
            return convertedBid;
          }).toList();

          result['allBids'] = allBids;

          // Find current user's bids
          final userBids =
              allBids.where((bid) => bid['userId'] == currentUserId).toList();
          if (userBids.isNotEmpty) {
            // Sort to get highest user bid
            userBids.sort(
                (a, b) => b['biddingAmount'].compareTo(a['biddingAmount']));
            result['currentUserBid'] = userBids.first;
            result['currentUserHighestBid'] = userBids.first['biddingAmount'];
          }

          // Find overall highest bid
          if (allBids.isNotEmpty) {
            allBids.sort(
                (a, b) => b['biddingAmount'].compareTo(a['biddingAmount']));
            result['highestBid'] = allBids.first['biddingAmount'];
          }
        }
      }

      return result;
    });
  }

  Future<Map<String, dynamic>?> fetchAcceptedBid() async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        debugPrint('User not logged in');
        return null;
      }

      // Query all accepted bids where buyerId matches current user
      final acceptedBidRef = FirebaseDatabase.instance
          .ref('AcceptedBids')
          .orderByChild('buyerId')
          .equalTo(currentUser.uid);

      final DatabaseEvent event = await acceptedBidRef.once();
      final DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        final dynamicData = snapshot.value as Map<dynamic, dynamic>;

        // Convert to proper Map and find the bid for this specific skill
        for (final entry in dynamicData.entries) {
          final bid = Map<String, dynamic>.from(entry.value as Map);
          if (bid['skillId'] == widget.skillId) {
            return {
              ...bid,
              'acceptedBidId':
                  entry.key.toString(), // The key from AcceptedBids node
            };
          }
        }
      }
      debugPrint('No accepted bids found for this user and skill');
      return null;
    } catch (e) {
      debugPrint('Error fetching accepted bid: $e');
      return null;
    }
  }

  Future<void> checkForAcceptedBid() async {
    setState(() => isCheckingAcceptedBid = true);
    try {
      final bid = await fetchAcceptedBid();
      setState(() {
        acceptedBid = bid;
        isCheckingAcceptedBid = false;
      });
    } catch (e) {
      setState(() => isCheckingAcceptedBid = false);
      debugPrint('Error checking for accepted bid: $e');
    }
  }

  Widget buildBidTextField() {
    return TextField(
      keyboardType: TextInputType.number,
      cursorColor: customColor.purpleText,
      controller: biddingController,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'Bid higher than current bid',
        hintText: 'Bid higher than current bid',
        hintStyle: TextStyle(color: customColor.purpleText),
        labelStyle: TextStyle(color: customColor.purpleBlue),
        prefixIcon: const Icon(FontAwesomeIcons.handHoldingDollar),
        suffix: IconButton(
          onPressed: saveBidAmount,
          icon: Icon(Icons.send, color: customColor.purpleText),
          iconSize: 20,
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
    final bidData = snapshot.data ??
        {
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
                    data:
                        'Your bid: \$${currentUserBid['biddingAmount'].toStringAsFixed(2)}',
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
        SizedBox(
          height: 20,
        ),
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
                        SizedBox(
                          height: 5,
                        ),
                        // this will show the seller name
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return SellerprofileForbuyers(
                                    sellerId: skillDetails!.sellerId,
                                    sellerName: skillDetails!.sellerName,
                                  );
                                }));
                              },
                              child: CircleAvatar(
                                backgroundImage: sellerDetails
                                            ?.imagePath?.isNotEmpty ==
                                        true
                                    ? MemoryImage(
                                        base64Decode(sellerDetails!.imagePath!))
                                    : null,
                                child: sellerDetails?.imagePath == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                            ),
                            SizedBox(
                              width: 4,
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return SellerprofileForbuyers(
                                    sellerId: skillDetails!.sellerId,
                                    sellerName: skillDetails!.sellerName,
                                  );
                                }));
                              },
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
                        ),
                        const SizedBox(height: 10),
                        Text(
                          skillDetails!.description,
                          style: const TextStyle(fontSize: 16),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              overflow: TextOverflow.ellipsis,
                              'Delivery In: ${skillDetails!.delivery}',
                              style: TextStyle(
                                color: customColor.purpleText,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
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
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            if (snapshot.hasError) {
                              return const Text('Error loading bids');
                            }

                            return buildBidStatus(snapshot);
                          },
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        if (acceptedBid != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '🎉Congratulations!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  'Your Bid has been Accepted!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Accepted Amount: \$${(acceptedBid!['amount'] as num).toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: customColor.purpleText),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Accepted At: ${DateTime.fromMillisecondsSinceEpoch(acceptedBid!['acceptedAt'] as int)}',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: customColor.purpleText),
                                ),
                                SizedBox(
                                  height: 15,
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context){
                                      return CartPage();
                                    }));

                                  },
                                  child: Text(
                                    'Proceed to Next',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: customColor.purpleBlue,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
