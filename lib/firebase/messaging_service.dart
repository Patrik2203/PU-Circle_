import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Get chat ID between two users
  Future<String> getChatId(String user1Id, String user2Id) async {
    // Sort user IDs to ensure consistent chat ID
    List<String> sortedIds = [user1Id, user2Id]..sort();

    // Check if chat already exists
    QuerySnapshot existingChat = await _firestore
        .collection('chats')
        .where('participants', isEqualTo: sortedIds)
        .limit(1)
        .get();

    // If chat exists, return its ID
    if (existingChat.docs.isNotEmpty) {
      return existingChat.docs.first.id;
    }

    // Create new chat
    String chatId = _uuid.v4();
    await _firestore.collection('chats').doc(chatId).set({
      'chatId': chatId,
      'participants': sortedIds,
      'lastMessage': '',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'unreadCount': {
        user1Id: 0,
        user2Id: 0,
      },
    });

    return chatId;
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
    String? mediaUrl,
  }) async {
    String messageId = _uuid.v4();

    // Create message document
    await _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).set({
      'messageId': messageId,
      'senderId': senderId,
      'content': content,
      'mediaUrl': mediaUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Update chat metadata
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': content,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'unreadCount.$receiverId': FieldValue.increment(1),
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    // Get unread messages
    QuerySnapshot unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();

    // Mark messages as read
    WriteBatch batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    // Reset unread count for this user
    batch.update(_firestore.collection('chats').doc(chatId), {
      'unreadCount.$userId': 0,
    });

    await batch.commit();
  }

  // Get user's chats
  Stream<QuerySnapshot> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  // Get messages in a chat
  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50) // Limit for pagination
        .snapshots();
  }

  // Get older messages for pagination
  Future<QuerySnapshot> getOlderMessages(String chatId, DateTime beforeTimestamp) async {
    return await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([beforeTimestamp])
        .limit(20)
        .get();
  }

  // Send predefined message
  Future<void> sendPreDefinedMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
  }) async {
    const String predefinedMessage = "Wanna meet at PU circle or on a tea post?";

    await sendMessage(
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      content: predefinedMessage,
    );
  }
}