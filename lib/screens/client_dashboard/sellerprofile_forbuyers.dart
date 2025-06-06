import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:skill_auction/firebase_model/user_model.dart';
import 'package:skill_auction/firebase_model/skill_model.dart';
import 'package:skill_auction/custom_widgets/custom_color.dart';
import 'package:skill_auction/screens/client_dashboard/detailskill_view.dart';

class SellerprofileForbuyers extends StatefulWidget {
  final String sellerId;
  final String sellerName;

  const SellerprofileForbuyers({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  State<SellerprofileForbuyers> createState() => _SellerprofileForbuyersState();
}

class _SellerprofileForbuyersState extends State<SellerprofileForbuyers> {
  final CustomColor _customColor = CustomColor();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('auctionusers');
  final DatabaseReference _skillsRef = FirebaseDatabase.instance.ref('sellerskills');

  UserModel? _sellerDetails;
  List<SkillModel> _sellerSkills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSellerData();
  }

  Future<void> _fetchSellerData() async {
    try {
      await Future.wait([
        _fetchSellerDetails(),
        _fetchSellerSkills(),
      ]);
    } catch (e) {
      debugPrint('Error fetching seller data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchSellerDetails() async {
    final snapshot = await _dbRef.child(widget.sellerId).get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      if (mounted) {
        setState(() => _sellerDetails = UserModel.fromMap(data));
      }
    }
  }

  Future<void> _fetchSellerSkills() async {
    final snapshot = await _skillsRef
        .orderByChild('sellerId')
        .equalTo(widget.sellerId)
        .get();

    if (snapshot.exists) {
      final List<SkillModel> loadedSkills = [];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        if (value != null) {
          final skillMap = Map<String, dynamic>.from(value as Map);
          skillMap['skillId'] = key;// key for skill
          loadedSkills.add(SkillModel.fromMap(skillMap));
        }
      });

      if (mounted) {
        setState(() => _sellerSkills = loadedSkills);
      }
    }
  }

  Widget _buildSellerProfile() {
    return Card(
      color: _customColor.peach,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _sellerDetails?.imagePath != null
                  ? MemoryImage(base64Decode(_sellerDetails!.imagePath!))
                  : null,
              child: _sellerDetails?.imagePath == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              '${_sellerDetails?.firstname ?? ''} ${_sellerDetails?.lastName ?? ''}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _customColor.purpleText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _sellerDetails?.description ?? 'No description provided',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillCard(SkillModel skill) {
    return InkWell(

        onTap: () {

          debugPrint('Navigating to skill with ID: ${skill.skillId}');
          if (skill.skillId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid skill ID')),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailSkillView(skillId:skill.skillId),
            ),
          );
        },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.memory(
                base64Decode(skill.imagePath),
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Text(
                skill.skillTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _customColor.purpleText,
                ),
              ),
              const SizedBox(height: 4),
              Text(skill.description),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Min Bid: \$${skill.minBid}',
                    style: TextStyle(
                      color: _customColor.purpleBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    skill.category,
                    style: TextStyle(
                      color: _customColor.purpleText,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'About the Seller',
          style: TextStyle(color: _customColor.purpleText),
        ),
        backgroundColor: const Color(0xFFffd7f3),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSellerProfile(),
            const SizedBox(height: 24),
            Text(
              'Skills Offered  '
                  ,
              style: TextStyle(

                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _customColor.purpleBlue,
              ),
            ),
            const SizedBox(height: 8),
            if (_sellerSkills.isEmpty)
              const Text('No skills listed yet'),
            ..._sellerSkills.map(_buildSkillCard).toList(),
          ],
        ),
      ),
    );
  }
}