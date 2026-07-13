import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/models/user_model.dart';

class MatcherService {
  final FirebaseFirestore _firestore;

  MatcherService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches online listeners matching the seeker's preferred languages.
  Future<List<UserModel>> getOnlineListeners(List<String> preferredLanguages) async {
    if (preferredLanguages.isEmpty) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'listener')
          .where('listenerData.isOnline', isEqualTo: true)
          .where('listenerData.languagesSpoken',
              arrayContainsAny: preferredLanguages)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching listeners: $e');
      return [];
    }
  }
}
