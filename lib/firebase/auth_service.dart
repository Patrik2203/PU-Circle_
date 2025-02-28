import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Signup with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String username,
    required String gender,
    required bool isSingle,
    String? profileImageUrl,
    String? bio,
  }) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'username': username,
        'profileImageUrl': profileImageUrl ?? '',
        'bio': bio ?? '',
        'gender': gender,
        'isSingle': isSingle,
        'isAdmin': false,
        'followers': [],
        'following': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Login with email and password
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Admin login with passkey
  Future<bool> adminLogin({
    required String email,
    required String password,
    required String passkey,
  }) async {
    // Check if passkey is correct
    if (passkey != "79770051419136567648") {
      return false;
    }

    try {
      // First login with email and password
      UserCredential userCredential = await login(
        email: email,
        password: password,
      );

      // Update user as admin
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'isAdmin': true,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Follow user
  Future<void> followUser(String currentUserId, String targetUserId) async {
    // Add targetUserId to current user's following list
    await _firestore.collection('users').doc(currentUserId).update({
      'following': FieldValue.arrayUnion([targetUserId]),
    });

    // Add currentUserId to target user's followers list
    await _firestore.collection('users').doc(targetUserId).update({
      'followers': FieldValue.arrayUnion([currentUserId]),
    });

    // Create notification
    await _firestore.collection('notifications').add({
      'type': 'follow',
      'senderId': currentUserId,
      'receiverId': targetUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Unfollow user
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    // Remove targetUserId from current user's following list
    await _firestore.collection('users').doc(currentUserId).update({
      'following': FieldValue.arrayRemove([targetUserId]),
    });

    // Remove currentUserId from target user's followers list
    await _firestore.collection('users').doc(targetUserId).update({
      'followers': FieldValue.arrayRemove([currentUserId]),
    });
  }

  // Report user
  Future<void> reportUser(String reporterId, String reportedUserId, String reason) async {
    await _firestore.collection('reports').add({
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }
}