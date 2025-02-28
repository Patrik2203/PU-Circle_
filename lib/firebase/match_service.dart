import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/match_model.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Get potential matches for a user
  Future<List<UserModel>> getPotentialMatches(String userId, String gender) async {
    try {
      // Get the opposite gender for matchmaking
      String oppositeGender = gender == 'male' ? 'female' : 'male';

      // Get current user's swipe history (right and left swipes)
      QuerySnapshot rightSwipes = await _firestore
          .collection('swipes')
          .where('swiperId', isEqualTo: userId)
          .get();

      // Extract user IDs that have already been swiped
      List<String> swipedUserIds = rightSwipes.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['swipedUserId'] as String)
          .toList();

      // Add current user ID to swiped list to exclude from results
      swipedUserIds.add(userId);

      // Get users of opposite gender who haven't been swiped yet
      QuerySnapshot matchSnapshot;

      if (swipedUserIds.length > 10) {
        // If there are many swiped users, we need to use "not-in" clause with chunking
        // Firestore has a limit of 10 items in a not-in query, so we'll get all users and filter
        matchSnapshot = await _firestore
            .collection('users')
            .where('gender', isEqualTo: oppositeGender)
            .limit(50)
            .get();

        // Filter out already swiped users
        List<UserModel> potentialMatches = [];
        for (var doc in matchSnapshot.docs) {
          String docId = doc.id;
          if (!swipedUserIds.contains(docId)) {
            potentialMatches.add(UserModel.fromMap(doc.data() as Map<String, dynamic>));
          }
        }

        return potentialMatches;
      } else {
        // If swiped users list is small, we can use "not-in" directly
        matchSnapshot = await _firestore
            .collection('users')
            .where('gender', isEqualTo: oppositeGender)
            .where(FieldPath.documentId, whereNotIn: swipedUserIds.isEmpty ? ['placeholder'] : swipedUserIds)
            .limit(20)
            .get();

        return matchSnapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      return [];
    }
  }

  // Swipe right on a user
  Future<bool> swipeRight(String swiperId, String swipedUserId) async {
    try {
      // Record the right swipe
      await _firestore.collection('swipes').add({
        'swiperId': swiperId,
        'swipedUserId': swipedUserId,
        'type': 'right',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Check if the other user has already swiped right on this user
      QuerySnapshot matchCheck = await _firestore
          .collection('swipes')
          .where('swiperId', isEqualTo: swipedUserId)
          .where('swipedUserId', isEqualTo: swiperId)
          .where('type', isEqualTo: 'right')
          .get();

      // If there's a mutual right swipe, create a match
      if (matchCheck.docs.isNotEmpty) {
        String matchId = _uuid.v4();

        // Create match document
        await _firestore.collection('matches').doc(matchId).set({
          'matchId': matchId,
          'user1Id': swiperId,
          'user2Id': swipedUserId,
          'matchedAt': FieldValue.serverTimestamp(),
          'isAlgorithmMatched': false,
        });

        // Create notifications for both users
        await _firestore.collection('notifications').add({
          'type': 'match',
          'matchId': matchId,
          'senderId': swiperId,
          'receiverId': swipedUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('notifications').add({
          'type': 'match',
          'matchId': matchId,
          'senderId': swipedUserId,
          'receiverId': swiperId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        return true; // Return true if match created
      }

      return false; // Return false if no match yet
    } catch (e) {
      return false;
    }
  }

  // Swipe left on a user
  Future<void> swipeLeft(String swiperId, String swipedUserId) async {
    try {
      // Record the left swipe
      await _firestore.collection('swipes').add({
        'swiperId': swiperId,
        'swipedUserId': swipedUserId,
        'type': 'left',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Handle error
    }
  }

  // Get user's matches
  Stream<QuerySnapshot> getUserMatches(String userId) {
    return _firestore
        .collection('matches')
        .where(Filter.or(
      Filter('user1Id', isEqualTo: userId),
      Filter('user2Id', isEqualTo: userId),
    ))
        .orderBy('matchedAt', descending: true)
        .snapshots();
  }

  // Admin match two users
  Future<void> adminMatchUsers(String user1Id, String user2Id) async {
    String matchId = _uuid.v4();

    // Create match document
    await _firestore.collection('matches').doc(matchId).set({
      'matchId': matchId,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'matchedAt': FieldValue.serverTimestamp(),
      'isAlgorithmMatched': true,
    });

    // Create notifications for both users
    await _firestore.collection('notifications').add({
      'type': 'algorithmMatch',
      'matchId': matchId,
      'senderId': 'admin',
      'receiverId': user1Id,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('notifications').add({
      'type': 'algorithmMatch',
      'matchId': matchId,
      'senderId': 'admin',
      'receiverId': user2Id,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}