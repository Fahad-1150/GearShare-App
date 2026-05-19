# How to Add "Message Owner" Button to Equipment Details

This guide shows you how to integrate the chat system with your equipment details page.

## Example Implementation

### In equipment_details_page.dart

Add this import at the top:
```dart
import '../services/chat_service.dart';
import 'chat_detail_page.dart';
```

### Add a Message Button in Your UI

```dart
// Add this in your equipment details UI (usually after the price section)

ElevatedButton.icon(
  onPressed: () => _startChat(),
  icon: const Icon(Icons.message),
  label: const Text('Message Owner'),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFBB86FC),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
),
```

### Add the Chat Method

```dart
Future<void> _startChat() async {
  try {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to message')),
      );
      return;
    }

    final currentUserId = currentUser.id;
    final currentUserName = currentUser.userMetadata?['full_name'] ?? 
                           currentUser.email?.split('@')[0] ?? 'User';

    // Get equipment owner name (you may need to fetch this)
    final ownerName = equipment.ownerName ?? 'Equipment Owner';

    final chatService = ChatService();
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBB86FC)),
        ),
      ),
    );

    try {
      final chat = await chatService.getOrCreateChat(
        user1Id: currentUserId,
        user2Id: equipment.ownerId,
        user1Name: currentUserName,
        user2Name: ownerName,
        user1Avatar: '', // Add user avatar URL if available
        user2Avatar: '', // Add owner avatar URL if available
      );

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            chat: chat,
            currentUserId: currentUserId,
            currentUserName: currentUserName,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

### Update Equipment Model (if needed)

If your Equipment model doesn't have `ownerName` and `ownerId`, add them:

```dart
class Equipment {
  final String ownerId;        // Already exists
  final String? ownerName;     // Add this
  final String? ownerAvatar;   // Optional: for displaying avatars
  // ... rest of your properties
}
```

### Complete Example File Structure

```dart
import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../services/chat_service.dart';
import '../pages/chat_detail_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EquipmentDetailsPage extends StatefulWidget {
  final Equipment equipment;
  
  const EquipmentDetailsPage({
    required this.equipment,
    super.key,
  });

  @override
  State<EquipmentDetailsPage> createState() => _EquipmentDetailsPageState();
}

class _EquipmentDetailsPageState extends State<EquipmentDetailsPage> {
  late Equipment equipment;

  @override
  void initState() {
    super.initState();
    equipment = widget.equipment;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipment Details')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Equipment details...
            
            // Message button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startChat(),
                  icon: const Icon(Icons.message),
                  label: const Text('Message Owner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBB86FC),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startChat() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to message')),
        );
        return;
      }

      final currentUserId = currentUser.id;
      final currentUserName = currentUser.userMetadata?['full_name'] ?? 
                             currentUser.email?.split('@')[0] ?? 'User';

      final ownerName = equipment.ownerName ?? 'Equipment Owner';

      final chatService = ChatService();
      
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBB86FC)),
          ),
        ),
      );

      final chat = await chatService.getOrCreateChat(
        user1Id: currentUserId,
        user2Id: equipment.ownerId,
        user1Name: currentUserName,
        user2Name: ownerName,
        user1Avatar: '',
        user2Avatar: '',
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            chat: chat,
            currentUserId: currentUserId,
            currentUserName: currentUserName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog if open
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
```

## Alternative: Message from Feed

You can also add a floating action button on the feed:

```dart
// In feed_page.dart (or similar)

FloatingActionButton(
  onPressed: () => _showEquipmentOptions(equipment),
  child: const Icon(Icons.share),
),

// In a menu or dialog:
ListTile(
  leading: const Icon(Icons.message),
  title: const Text('Message Owner'),
  onTap: () {
    _startChat(equipment);
  },
)
```

## Styling Tips

### Match Your Theme
```dart
ElevatedButton.icon(
  onPressed: () => _startChat(),
  icon: const Icon(Icons.message),
  label: const Text('Message Owner'),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFBB86FC), // Your purple theme
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFBB86FC)),
    ),
  ),
)
```

### Add to a Row with Other Actions
```dart
Row(
  children: [
    Expanded(
      child: ElevatedButton.icon(
        onPressed: () => _startChat(),
        icon: const Icon(Icons.message),
        label: const Text('Message'),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: ElevatedButton.icon(
        onPressed: () => _rentEquipment(),
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Rent'),
      ),
    ),
  ],
)
```

## Handling Edge Cases

### User is Equipment Owner
```dart
// Prevent users from messaging themselves
if (currentUserId == equipment.ownerId) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('This is your equipment')),
  );
  return;
}
```

### User Not Signed In
```dart
if (currentUser == null) {
  Navigator.pushNamed(context, '/signin');
  return;
}
```

### Network Error
```dart
try {
  // ... chat creation
} on SocketException {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('No internet connection')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

---

**Status:** Ready to implement
**Integration Time:** 5-10 minutes
