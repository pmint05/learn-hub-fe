import 'package:cloud_firestore/cloud_firestore.dart';

class DB {
  static final DB instance = DB._internal();

  factory DB() {
    return instance;
  }

  DB._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> checkUsernameExist(String username) async {
    // print("Checking if username exists: $username");
    final userRef = _firestore
        .collection('users')
        .where("username", isEqualTo: username);
    return await userRef.get().then((QuerySnapshot snapshot) {
      if (snapshot.docs.isNotEmpty) {
        // print(snapshot.docs.first.data());
        return true;
      } else {
        return false;
      }
    });
  }

  Future<Map<String, dynamic>> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
      return data;
    } catch (e) {
      print("Error updating document: $e");
      return {};
    }
  }

  Future<Map<String, dynamic>> getDocument(
    String collection,
    String documentId,
  ) async {
    try {
      final docSnapshot =
          await _firestore.collection(collection).doc(documentId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data() ?? {};
      } else {
        print("Document does not exist");
        return {};
      }
    } catch (e) {
      print("Error getting document: $e");
      return {};
    }
  }

  Future<void> deleteDocument(String collection, String documentId) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print("Error deleting document: $e");
    }
  }

  Future<void> addDocument(String collection, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).add(data);
    } catch (e) {
      print("Error adding document: $e");
    }
  }
}
