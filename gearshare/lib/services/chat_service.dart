import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();

  factory ChatService() {
    return _instance;
  }

  ChatService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // Get or create a chat between two users
  Future<Chat> getOrCreateChat({
    required String user1Id,
    required String user2Id,
    required String user1Name,
    required String user2Name,
    required String user1Avatar,
    required String user2Avatar,
  }) async {
    try {
      // Check if chat already exists
      final existingChat = await _client
          .from('chats')
          .select()
          .or(
            'and(user1_id.eq.$user1Id,user2_id.eq.$user2Id),and(user1_id.eq.$user2Id,user2_id.eq.$user1Id)',
          )
          .maybeSingle();

      if (existingChat != null) {
        return Chat.fromJson(existingChat);
      }

      // Create new chat
      final chatId = DateTime.now().millisecondsSinceEpoch.toString();

      final newChat = {
        'id': chatId,
        'user1_id': user1Id,
        'user2_id': user2Id,
        'user1_name': user1Name,
        'user2_name': user2Name,
        'user1_avatar': user1Avatar,
        'user2_avatar': user2Avatar,
        'last_message': '',
        'last_message_time': DateTime.now().toIso8601String(),
        'unread_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('chats')
          .insert(newChat)
          .select()
          .single();

      return Chat.fromJson(response);
    } catch (e) {
      print('Error getting or creating chat: $e');
      rethrow;
    }
  }

  // Mark a chat as read
  Future<void> markChatAsRead(String chatId) async {
    try {
      await _client.from('chats').update({'unread_count': 0}).eq('id', chatId);
    } catch (e) {
      print('Error marking chat as read: $e');
      rethrow;
    }
  }

  // Get all chats for a user
  Future<List<Chat>> getUserChats(String userId) async {
    try {
      final response = await _client
          .from('chats')
          .select()
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('last_message_time', ascending: false);

      return (response as List)
          .map((item) => Chat.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching user chats: $e');
      rethrow;
    }
  }

  // Send a message
  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String content,
  }) async {
    try {
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();

      final messageData = {
        'id': messageId,
        'chat_id': chatId,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_avatar': senderAvatar,
        'content': content,
        'created_at': now.toIso8601String(),
        'is_read': false,
      };

      // Insert message
      final response = await _client
          .from('messages')
          .insert(messageData)
          .select()
          .single();

      // Update chat's last message
      await _client
          .from('chats')
          .update({
            'last_message': content,
            'last_message_time': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', chatId);

      return Message.fromJson(response);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages for a chat
  Future<List<Message>> getChatMessages(
    String chatId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Message.fromJson(item as Map<String, dynamic>))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      print('Error fetching chat messages: $e');
      rethrow;
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('id', messageId);
    } catch (e) {
      print('Error marking message as read: $e');
      rethrow;
    }
  }

  // Subscribe to messages in a chat
  Stream<List<Message>> subscribeToMessages(String chatId) {
    return Stream.periodic(const Duration(milliseconds: 500), (_) async {
      return await getChatMessages(chatId);
    }).asyncMap((event) => event).asBroadcastStream();
  }

  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages first
      await _client.from('messages').delete().eq('chat_id', chatId);

      // Delete the chat
      await _client.from('chats').delete().eq('id', chatId);
    } catch (e) {
      print('Error deleting chat: $e');
      rethrow;
    }
  }
}
