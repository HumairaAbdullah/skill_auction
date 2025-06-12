import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:skill_auction/custom_widgets/custom_color.dart';
import 'package:skill_auction/custom_widgets/custom_snackbar.dart';
import 'package:skill_auction/custom_widgets/custom_textfield.dart';
import 'package:skill_auction/payment/payment_response.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final instruction=TextEditingController();
  final CustomColor customColor=CustomColor();
final bidsRef=FirebaseDatabase.instance.ref();
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Proceed For Payment',style: TextStyle(
          color: customColor.purpleText,
        ),),
        backgroundColor: customColor.peach,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomtextField(hint: 'Enter Special Instructions',
                label: Text('Instructions'),
                postfix: IconButton(onPressed: _pickFile, icon:Icon(Icons.attach_file)),
                obscure: false,
                maxlines: 4,
                customcontroller: instruction),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: customColor.purpleBlue
              ),
                onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context){
                  return firstpage();
                }));
                },
                child: Text('PayOut',style: TextStyle(
              color: customColor.white
            ),)),

          ],
        ),
      ),
    );
  }
}
