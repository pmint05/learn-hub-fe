import 'package:cloud_firestore/cloud_firestore.dart';

final defaultReferences = {'darkMode': false, 'notifications': true};

class AppUser {
  String? uid;
  String? displayName;
  String? username;
  String? email;
  String? photoURL;
  String? token;
  DateTime? vipExpiration;
  DateTime? createdAt;
  int? credits;
  DateTime? freeCreditsLastReset;
  bool? isVIP;
  Map<String, dynamic>? preferences;
  String? role;
  String? gender;
  String? phoneNumber;
  String? birthday;

  AppUser({
    this.uid,
    this.email,
    this.token,
    this.displayName,
    this.username,
    this.photoURL,
    this.vipExpiration,
    this.createdAt,
    this.credits,
    this.freeCreditsLastReset,
    this.isVIP,
    this.preferences,
    this.role,
    this.gender,
    this.phoneNumber,
    this.birthday,
  });

  AppUser.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    email = json['email'];
    token = json['token'];
    displayName = json['displayName'];
    username = json['username'];
    photoURL = json['photoURL'];
    credits = json['credits'] is int ? json['credits'] : 0;
    if (json['VIPExpiration'] is Timestamp) {
      vipExpiration = (json['VIPExpiration'] as Timestamp).toDate();
    } else if (json['VIPExpiration'] is String) {
      vipExpiration = DateTime.tryParse(json['VIPExpiration']);
    }

    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.tryParse(json['createdAt']);
    }

    if (json['freeCreditsLastReset'] is Timestamp) {
      freeCreditsLastReset = (json['freeCreditsLastReset'] as Timestamp).toDate();
    } else if (json['freeCreditsLastReset'] is String) {
      freeCreditsLastReset = DateTime.tryParse(json['freeCreditsLastReset']);
    }
    isVIP = json['isVIP'];
    preferences = json['preferences'] ?? {};
    role = json['role'];
    gender = json['gender'];
    phoneNumber = json['phoneNumber'];
    birthday = json['birthday'];
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'token': token,
      'displayName': displayName,
      'username': username,
      'photoURL': photoURL,
      'vipExpiration': vipExpiration?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'credits': credits,
      'freeCreditsLastReset': freeCreditsLastReset?.toIso8601String(),
      'isVIP': isVIP,
      'preferences': preferences ?? {},
      'role': role,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'birthday': birthday,
    };
  }
}
