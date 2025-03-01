import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Initialize notifications and request permissions
  Future<void> initNotifications() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await _messaging.getToken();
        if (token != null && _auth.currentUser != null) {
          await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
            'fcmToken': token,
          });
        }

        _messaging.onTokenRefresh.listen((newToken) {
          if (_auth.currentUser != null) {
            _firestore.collection('users').doc(_auth.currentUser!.uid).update({
              'fcmToken': newToken,
            });
          }
        });
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  // Get all notifications for a user
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      QuerySnapshot notificationSnapshot = await _firestore
          .collection('notifications')
          .where('receiverId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return notificationSnapshot.docs.map((doc) {
        return NotificationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      QuerySnapshot notifications = await _firestore
          .collection('notifications')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      rethrow;
    }
  }

  // Send a notification
  Future<void> sendNotification(NotificationModel notification) async {
    try {
      await _firestore.collection('notifications').add(notification.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Stream notifications in real-time
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
        .toList());
  }
}