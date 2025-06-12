import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:skill_auction/custom_widgets/custom_color.dart';
import 'package:skill_auction/custom_widgets/custom_snackbar.dart';
import 'package:skill_auction/custom_widgets/custom_textfield.dart';
import 'package:skill_auction/firebase_model/skill_model.dart';
import 'package:skill_auction/payment/payment_response.dart';

class CartPage extends StatefulWidget {
  final String skillId;
  CartPage({super.key, required this.skillId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final instruction = TextEditingController();
  final CustomColor customColor = CustomColor();
  final bidsRef = FirebaseDatabase.instance.ref();
  final auth = FirebaseAuth.instance;
  Map<String, dynamic>? acceptedBid;
  bool isCheckingAcceptedBid = false;
  String? _fileName;
  PlatformFile? _pickedFile;
  SkillModel? skillDetails;
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
      // await bidsRef.child(currentUser).update({
      //   'buyerRequirements': base64Encode(file.bytes!),
      //   'fileName': uniqueFileName,
      //   'fileType': file.extension ?? 'unknown',
      //   'uploadTime': ServerValue.timestamp,
      //   'fileSize': file.size,
      //   'originalFileName': file.name,
      // });

      setState(() {
        _pickedFile = file;
        _fileName = file.name;
      });

      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     CustomSnackbar.show(
      //         content: const Text('File uploaded successfully!')),
      //   );
      // }
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

  Future<void> saveOrderDetails() async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }

      if (acceptedBid == null) {
        throw Exception("No accepted bid found");
      }

      // Create a reference first to get the key
      final orderRef = FirebaseDatabase.instance.ref('orderdetails').push();
      final uid = orderRef.key!; // Get the auto-generated key

      // Create a map with the order details including the entryId
      Map<String, dynamic> orderDetails = {
        'skillId': widget.skillId,
        'buyerId': currentUser.uid,
        'sellerId': acceptedBid!['sellerId'],
        'bidId': acceptedBid!['acceptedBidId'],
        'amount': acceptedBid!['amount'],
        'instructions': instruction.text.trim(),
        'createdAt': ServerValue.timestamp,
        'status': 'pending',
        'entryId': uid, // Save the auto-generated key here
      };

      // If a file was picked, add file details
      if (_pickedFile != null && _pickedFile!.bytes != null) {
        orderDetails.addAll({
          'fileName': _pickedFile!.name,
          'fileType': _pickedFile!.extension ?? 'unknown',
          'fileSize': _pickedFile!.size,
          'fileData': base64Encode(_pickedFile!.bytes!),
          'uploadedAt': ServerValue.timestamp,
        });
      }

      // Save to Firebase using the reference we created
      await orderRef.set(orderDetails);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackbar.show(
            content: const Text('Order details saved successfully!'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving order details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackbar.show(
            content: Text('Failed to save order: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchAcceptedBid();
    checkForAcceptedBid();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Proceed For Payment',
          style: TextStyle(
            color: customColor.purpleText,
          ),
        ),
        backgroundColor: customColor.peach,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                            fontSize: 14, color: customColor.purpleText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Accepted At: ${DateTime.fromMillisecondsSinceEpoch(acceptedBid!['acceptedAt'] as int)}',
                        style: TextStyle(
                            fontSize: 14, color: customColor.purpleText),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                    ],
                  ),
                ),

              CustomtextField(
                hint: 'Enter Special Instructions',
                label: Text('Special Instructions'),
                postfix: IconButton(
                    onPressed: _pickFile, icon: Icon(Icons.attach_file)),
                obscure: false,
                maxlines: 4,
                customcontroller: instruction,
              ),

              //  show the selected file

              if (_fileName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.attach_file,
                        color: customColor.purpleBlue,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _fileName!,
                          style: TextStyle(color: customColor.purpleText),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() {
                            _fileName = null;
                            _pickedFile = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 10),
              Container(
                color: customColor.purpleBlue,
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () async {
                    await saveOrderDetails();
                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return firstpage();
                    }));
                  },
                  child: Text('PayOut',
                      style: TextStyle(color: customColor.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
