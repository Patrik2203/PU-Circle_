import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../firebase/notification_service.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/home/post_detail_screen.dart';
import '../screens/match/match_detail_screen.dart';
import '../screens/messaging/chat_screen.dart';

class NotificationHelper {
  static final NotificationService _notificationService = NotificationService();

  // Handle notification tap based on notification type
  static Future<void> handleNotificationTap(
      BuildContext context,
      NotificationModel notification,
      ) async {
    // Mark notification as read
    await _notificationService.markNotificationAsRead(notification.id);

    // Navigate based on notification type
    switch (notification.type) {
      case 'follow':
      // Navigate to profile screen
        _navigateToProfile(context, notification.senderId);
        break;

      case 'like':
      // Navigate to post detail
        if (notification.postId != null) {
          _navigateToPost(context, notification.postId!);
        }
        break;

      case 'match':
      case 'algorithmMatch':
      // Navigate to match detail
        if (notification.matchId != null) {
          _navigateToMatch(context, notification.matchId!);
        }
        break;

      case 'message':
      // Navigate to chat
        _navigateToChat(context, notification.senderId);
        break;

      default:
        break;
    }
  }

  // Helper navigation methods
  static void _navigateToProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  static void _navigateToPost(BuildContext context, String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(postId: postId),
      ),
    );
  }

  static void _navigateToMatch(BuildContext context, String matchId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchDetailScreen(matchId: matchId),
      ),
    );
  }

  static void _navigateToChat(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(receiverId: userId),
      ),
    );
  }
}