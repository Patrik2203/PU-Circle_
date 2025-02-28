import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../firebase/auth_service.dart';
import '../../firebase/messaging_service.dart';
import '../../firebase/storage_service.dart';
import '../../models/chat_model.dart';
import '../../utils/colors.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    Key? key,
    required this.receiverId,
    required this.receiverName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AuthService _authService = AuthService();
  final MessagingService _messagingService = MessagingService();
  final StorageService _storageService = StorageService();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late String _currentUserId;
  String _chatId = '';
  bool _isLoading