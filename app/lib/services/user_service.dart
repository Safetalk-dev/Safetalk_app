import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches a user's document from the 'users' collection.
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching user document: $e');
      return null;
    }
  }

  /// Creates or updates a user document in the 'users' collection.
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toJson());
    } catch (e) {
      print('Error creating user document: $e');
      throw Exception('Could not create user profile');
    }
  }
}
