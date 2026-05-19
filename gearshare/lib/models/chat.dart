class Chat {
  final String id;
  final String user1Id;
  final String user2Id;
  final String user1Name;
  final String user2Name;
  final String user1Avatar;
  final String user2Avatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chat({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.user1Name,
    required this.user2Name,
    required this.user1Avatar,
    required this.user2Avatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String,
      user1Name: json['user1_name'] as String? ?? 'Unknown',
      user2Name: json['user2_name'] as String? ?? 'Unknown',
      user1Avatar: json['user1_avatar'] as String? ?? '',
      user2Avatar: json['user2_avatar'] as String? ?? '',
      lastMessage: json['last_message'] as String? ?? '',
      lastMessageTime: DateTime.parse(
        json['last_message_time'] as String? ??
            DateTime.now().toIso8601String(),
      ),
      unreadCount: json['unread_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'user1_name': user1Name,
      'user2_name': user2Name,
      'user1_avatar': user1Avatar,
      'user2_avatar': user2Avatar,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime.toIso8601String(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Get other user's name and avatar
  String getOtherUserName(String currentUserId) {
    return currentUserId == user1Id ? user2Name : user1Name;
  }

  String getOtherUserAvatar(String currentUserId) {
    return currentUserId == user1Id ? user2Avatar : user1Avatar;
  }

  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }
}
