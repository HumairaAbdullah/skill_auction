import 'package:flutter/cupertino.dart';

class SkillModel extends ChangeNotifier {
  String skillTitle;
  String description;
  String category;
  String skillId;
  String minBid;
  String imagePath;
  String sellerName;
  String sellerId;
  String delivery;
  String agency;

  SkillModel(
      {required this.skillTitle,
      required this.description,
      required this.category,
      required this.skillId,
      required this.minBid,
      required this.imagePath,
      required this.sellerId,
      required this.sellerName,
      required this.delivery,
      required this.agency});

  Map<String, String> toMap() {
    return {
      'skillTitle': skillTitle,
      'description': description,
      'sellerName': sellerName,
      'sellerId': sellerId,
      'category': category,
      'minBid': minBid,
      'image': imagePath,
      'skillId': skillId,
      'delivery': delivery,
      'agency': agency,
    };
  }

  factory SkillModel.fromMap(Map<dynamic, dynamic> map) {
    return SkillModel(
      skillTitle: map['skillTitle'] ?? '',
      description: map['description'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerId: map['sellerId'] ?? '',
      category: map['category'] ?? '',
      minBid: (map['minBid'] ?? '').toString(),
      delivery: map['delivery'] ?? '',
      imagePath: map['image'] ?? '',
      skillId: map['skillId'] ?? '',
      agency: map['agency']??'',
    );
  }
}
