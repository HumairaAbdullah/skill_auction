import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skill_auction/custom_widgets/custom_snackbar.dart';
import 'package:skill_auction/custom_widgets/custom_textfield.dart';
import 'package:skill_auction/custom_widgets/purple_text.dart';
import 'package:skill_auction/custom_widgets/white_text.dart';
import 'package:skill_auction/firebase_model/sellercrud.dart';
import 'package:skill_auction/firebase_model/skill_model.dart';

class GigPage extends StatefulWidget {
  final SkillModel? skillToUpdate;
  final SkillModel? skillSave;// Add this parameter for updates
  final bool isUpdating;
   GigPage(
      {super.key,
        this.skillSave,
      this.skillToUpdate, // Optional - if null, we're creating a new skill
      this.isUpdating = false});
  final sellerCrud=SellerCrud();

  @override
  State<GigPage> createState() => _GigPageState();
}

final dbRef = FirebaseDatabase.instance.ref();

class _GigPageState extends State<GigPage> {
  String sellerId = '';
  String sellerName = '';

  @override
  @override
  void initState() {
    super.initState();
    _getSellerInfo();

    if (widget.isUpdating && widget.skillToUpdate != null) {
      final skill = widget.skillToUpdate!;
      gigTitle.text = skill.skillTitle;
      description.text = skill.description;
      agencyName.text = skill.agency;
      minBid.text = skill.minBid.toString();
      delivery.text = skill.delivery;
      selectedvalue = skill.category;
      _base64image = skill.imagePath;
    }
  }

  Future<void> _getSellerInfo() async {
    // Get current user ID
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Reference to the users node in database
      DatabaseReference ref =
          FirebaseDatabase.instance.ref('auctionusers').child(user.uid);

      // Get the user data
      DataSnapshot snapshot = (await ref.get());
      if (snapshot.exists) {
        setState(() {
          sellerId = user.uid;
          sellerName = snapshot
              .child('firstName')
              .value
              .toString(); // Assuming 'name' field exists
        });
      }
    }
  }

  SellerCrud sellercrud = SellerCrud();
  String selectedvalue = '';
  final List<String> categories = [
    'Writing and Editing',
    'Graphic Design',
    'Visual Communication',
    'Software Development',
    'Marketing and Sales',
    'Business and Consulting',
    'Translation ',
    'Virtual Assistance',
    'Customer Service and Support',
    'Photography and Videography',
    'Music and Sound Design',
    'Teaching and Education',
    'Arts and Crafts',
    'Healthcare and Wellness',
  ];
  final gigTitle = TextEditingController();
  final description = TextEditingController();
  final agencyName = TextEditingController();
  final minBid = TextEditingController();
  final delivery = TextEditingController();
  XFile? _image;
  String? _base64image;
  final ImagePicker _picker = ImagePicker();

  Future<void> imagepickfunc() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = image;
      });
      final bytes = await image.readAsBytes();
      _base64image = base64Encode(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Color(0XFF8a2be1),
          centerTitle: true,
          title: WhiteText(data: 'Add A Skill')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: imagepickfunc,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    border: Border.all(
                      color: Color(0xFF0944c8),
                    ),
                  ),
                  height: 200,
                  width: double.infinity,
                  child: _image != null
                ? kIsWeb
                ? Image.network(_image!.path, width: 400, height: 200)
                  : Image.file(File(_image!.path), width: 400, height: 200)
              : _base64image != null && _base64image!.isNotEmpty
      ? Image.memory(
          base64Decode(_base64image!),
      width: 400,
      height: 200,
      fit: BoxFit.cover,
    )
        : IconButton(
    onPressed: imagepickfunc,
    icon: Icon(Icons.camera_alt_outlined, color: Color(0XFF8a2be1)),
    ),
                ),
              ),
              CustomtextField(
                  hint: 'eg.App Developer',
                  label: PurpleText(data: 'Title'),
                  obscure: false,
                  customcontroller: gigTitle),
              CustomtextField(
                  hint: 'Describe your Skill',
                  label: PurpleText(data: 'Description'),
                  obscure: false,
                  maxlines: 4,
                  customcontroller: description),
              CustomtextField(
                  hint: 'Agency Name',
                  label: PurpleText(data: 'Agency Name'),
                  obscure: false,
                  customcontroller: agencyName),
              CustomtextField(
                  hint: 'Min Bid',
                  label: PurpleText(data: 'Min.Bid'),
                  obscure: false,
                  customcontroller: minBid),
              SizedBox(
                height: 10,
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  iconColor: Color(0XFF8a2be1),
                  labelText: 'Category',
                  labelStyle: TextStyle(color: Color(0XFF8a2be1)),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0944c8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0944c8)),
                  ),
                ),
                value: selectedvalue.isEmpty ? null : selectedvalue,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedvalue = newValue!;
                  });
                },
                items: categories.map<DropdownMenuItem<String>>((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      //style: TextStyle(color: Color(0XFF8a2be1)),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please select a category'
                    : null,
              ),
              SizedBox(
                height: 10,
              ),
              CustomtextField(
                  hint: 'Delivery Time in days/month',
                  label: PurpleText(data: 'Delivery'),
                  obscure: false,
                  customcontroller: delivery),
              SizedBox(
                height: 20,
              ),
              Container(
                color: Color(0XFF8a2be1),
                width: double.infinity,
                child: TextButton(
                  // Add this to your GigPage onPressed method for the save/update button
                  onPressed: () async {
                    try {
                      // Validate inputs first
                      final bidValue = double.tryParse(minBid.text.trim());
                      if (gigTitle.text.trim().isEmpty ||
                          description.text.trim().isEmpty ||
                          selectedvalue.isEmpty ||
                          minBid.text.trim().isEmpty ||
                          delivery.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            CustomSnackbar.show(
                                content: WhiteText(data: 'Please fill all fields')
                            )
                        );
                        return;

                      }

                      // Use existing skillId if updating
                      final skillId = widget.isUpdating && widget.skillToUpdate != null
                          ? widget.skillToUpdate!.skillId
                          : dbRef.push().key;

                      final skillModel = SkillModel(
                        skillId: skillId!,
                        skillTitle: gigTitle.text.trim(),
                        description: description.text.trim(),
                        category: selectedvalue,
                        minBid: bidValue!,
                        imagePath: _base64image ?? widget.skillToUpdate?.imagePath ?? '',
                        sellerId: sellerId,
                        sellerName: sellerName,
                        delivery: delivery.text.trim(),
                        agency: agencyName.text.trim(),
                      );

                      if (widget.isUpdating) {
                        await Provider.of<SellerCrud>(context, listen: false)
                            .updateData(skillModel);
                        ScaffoldMessenger.of(context).showSnackBar(
                            CustomSnackbar.show(
                                content: WhiteText(data: 'Skill Updated Successfully')
                            )
                        );
                      } else {
                        await Provider.of<SellerCrud>(context, listen: false)
                            .saveData(skillModel);
                        ScaffoldMessenger.of(context).showSnackBar(
                            CustomSnackbar.show(
                                content: WhiteText(data: 'Skill Saved Successfully')
                            )
                        );
                      }

                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          CustomSnackbar.show(
                              content: WhiteText(data: 'Error: ${e.toString()}')
                          )
                      );
                    }
                  },
                  child: WhiteText(data: widget.isUpdating ? 'Update Skill' : 'Save Skill'),

                  // onPressed: () async {
                    //   SkillModel skillmodel = SkillModel(
                    //       skillTitle: gigTitle.text.trim(),
                    //       description: description.text.trim(),
                    //       category: selectedvalue,
                    //       skillId: sellercrud.dbRef.push().key.toString(),
                    //       minBid: minBid.text.trim(),
                    //       imagePath: _base64image.toString(),
                    //       sellerId: sellerId,
                    //       sellerName: sellerName,
                    //       delivery: delivery.text.trim(),
                    //       agency: agencyName.text.trim());
                    //   if (skillmodel != null) {
                    //     await Provider.of<SellerCrud>(context, listen: true)
                    //         .updateData(skillmodel);
                    //       ScaffoldMessenger.of(context).showSnackBar(CustomSnackbar.show(content: WhiteText(data: 'Skill Updated Successfully')));
                    //       Navigator.pop(context);
                    //
                    //   } else
                    //     await Provider.of<SellerCrud>(context, listen: false)
                    //         .saveData(skillmodel);
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //       CustomSnackbar.show(
                    //           content:
                    //               WhiteText(data: 'Skill Saved Successfully')));
                    //   Navigator.pop(context);
                    // },
                    // child: WhiteText(data:
                    // 'Save Skill'),),
              ),),
            ],
          ),
        ),
      ),
    );
  }
}
