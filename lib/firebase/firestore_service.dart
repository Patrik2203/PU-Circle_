import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create a new post
  Future<String> createPost({
    required String userId,
    required String username,
    required String userProfileImageUrl,
    required String mediaUrl,
    required bool isVideo,
    required String caption,
  }) async {
    try {
      String postId = _uuid.v4();

      await _firestore.collection('posts').doc(postId).set({
        'postId': postId,
        'userId': userId,
        'username': username,
        'userProfileImageUrl': userProfileImageUrl,
        'mediaUrl': mediaUrl,
        'isVideo': isVideo,
        'caption': caption,
        'likes': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      return postId;
    } catch (e) {
      rethrow;
    }
  }

  // Get posts from followed users for home screen
  Stream<QuerySnapshot> getFollowingPosts(List<String> followingIds, String currentUserId) {
    return _firestore
        .collection('posts')
        .where('userId', whereIn: [...followingIds, currentUserId])
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get posts from a specific user
  Stream<QuerySnapshot> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Like a post
  Future<void> likePost(String postId, String userId) async {
    await _firestore.collection('posts').doc(postId).update({
      'likes': FieldValue.arrayUnion([userId]),
    });

    // Get the post owner's ID to create a notification
    DocumentSnapshot postDoc = await _firestore.collection('posts').doc(postId).get();
    String postOwnerId = (postDoc.data() as Map<String, dynamic>)['userId'];

    // Don't create notification if liking your own post
    if (postOwnerId != userId) {
      await _firestore.collection('notifications').add({
        'type': 'like',
        'postId': postId,
        'senderId': userId,
        'receiverId': postOwnerId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    await _firestore.collection('posts').doc(postId).update({
      'likes': FieldValue.arrayRemove([userId]),
    });
  }

  // Delete a post (for user or admin)
  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  // Search for users
  Future<List<UserModel>> searchUsers(String query) async {
    List<UserModel> users = [];

    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    for (var doc in snapshot.docs) {
      users.add(UserModel.fromMap(doc.data() as Map<String, dynamic>));
    }

    return users;
  }

  // Get user notifications
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}