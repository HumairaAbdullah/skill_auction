class UserModel {
  String firstname;
  String lastName;
  String email;
  String password;
  String uId;
  String phoneNumber;
  int role;

  UserModel({
    required this.role,
    required this.uId,
    required this.firstname,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phoneNumber,

  });

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      role: map['role'] is int ? map['role'] : int.tryParse(map['role'].toString()) ?? 0,
      firstname: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      uId: map['uid'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      password: map['password'] ?? '',

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'firstName': firstname,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'uid': uId,
    };
  }
}
