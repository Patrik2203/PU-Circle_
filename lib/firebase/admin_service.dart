// lib/firebase/admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users (for admin dashboard)
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();

      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get all reports
  Future<QuerySnapshot> getAllReports() async {
    try {
      return await _firestore
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .get();
    } catch (e) {
      rethrow;
    }
  }

  // Update report status
  Future<void> updateReportStatus(String reportId, String status) async {
    await _firestore.collection('reports').doc(reportId).update({
      'status': status,
    });
  }

  // Delete a user (admin function)
  Future<void> deleteUser(String userId) async {
    // Get user's posts
    QuerySnapshot userPosts = await _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .get();

    // Delete all user posts
    WriteBatch batch = _firestore.batch();
    for (var doc in userPosts.docs) {
      batch.delete(doc.reference);
    }

    // Delete user document
    batch.delete(_firestore.collection('users').doc(userId));

    // Execute batch
    await batch.commit();
  }

  // Get all messages between two users (for monitoring)
  Future<QuerySnapshot> getMessagesBetweenUsers(String user1Id, String user2Id) async {
    // Sort user IDs to match how chat IDs are created
    List<String> sortedIds = [user1Id, user2Id]..sort();

    // First find the chat ID
    QuerySnapshot chatSnapshot = await _firestore
        .collection('chats')
        .where('participants', isEqualTo: sortedIds)
        .limit(1)
        .get();

    if (chatSnapshot.docs.isEmpty) {
      // No chat exists between these users
      return await _firestore.collection('temp').limit(0).get();
    }

    String chatId = chatSnapshot.docs.first.id;

    // Return messages
    return await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .get();
  }
}