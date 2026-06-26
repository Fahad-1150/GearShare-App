import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipment.dart';
import '../services/admin_auth_service.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _supabase = Supabase.instance.client;

  final List<_AdminTableConfig> _tables = const [
    _AdminTableConfig(
      label: 'Users',
      tableName: 'users',
      icon: Icons.people_outline,
      fields: ['id', 'email', 'name', 'phone'],
    ),
    _AdminTableConfig(
      label: 'Equipment',
      tableName: 'equipment',
      icon: Icons.inventory_2_outlined,
      fields: [
        'id',
        'owner_id',
        'name',
        'description',
        'category',
        'per_day_price',
        'discount_percentage',
        'discount_min_days',
        'status',
        'available_from',
        'location_name',
        'location_latitude',
        'location_longitude',
        'pickup_address',
        'is_public',
      ],
    ),
    _AdminTableConfig(
      label: 'Images',
      tableName: 'equipment_images',
      icon: Icons.image_outlined,
      fields: ['id', 'equipment_id', 'image_url', 'display_order'],
    ),
    _AdminTableConfig(
      label: 'Public',
      tableName: 'public_equipment',
      icon: Icons.public_outlined,
      fields: ['id', 'equipment_id', 'owner_id', 'display_order', 'featured'],
    ),
    _AdminTableConfig(
      label: 'Rentals',
      tableName: 'rentals',
      icon: Icons.receipt_long_outlined,
      fields: [
        'id',
        'equipment_id',
        'owner_id',
        'requester_id',
        'start_date',
        'end_date',
        'total_days',
        'per_day_price',
        'discount_percentage',
        'subtotal',
        'discount_amount',
        'total_amount',
        'rental_status',
        'payment_status',
        'payment_time',
        'payment_method',
        'transaction_id',
        'notes',
        'cancellation_reason',
        'refund_amount',
      ],
    ),
    _AdminTableConfig(
      label: 'Payments',
      tableName: 'rental_payments',
      icon: Icons.payments_outlined,
      fields: [
        'id',
        'rental_id',
        'requester_id',
        'owner_id',
        'amount',
        'payment_method',
        'transaction_id',
        'payment_status',
        'payment_time',
      ],
    ),
    _AdminTableConfig(
      label: 'Logs',
      tableName: 'rental_activity_logs',
      icon: Icons.history_outlined,
      fields: ['id', 'rental_id', 'action', 'actor_id', 'old_status', 'new_status', 'details'],
    ),
    _AdminTableConfig(
      label: 'Chats',
      tableName: 'chats',
      icon: Icons.chat_bubble_outline,
      fields: [
        'id',
        'user1_id',
        'user2_id',
        'user1_name',
        'user2_name',
        'user1_avatar',
        'user2_avatar',
        'last_message',
        'last_message_time',
        'unread_count',
      ],
    ),
    _AdminTableConfig(
      label: 'Messages',
      tableName: 'messages',
      icon: Icons.message_outlined,
      fields: [
        'id',
        'chat_id',
        'sender_id',
        'sender_name',
        'sender_avatar',
        'content',
        'is_read',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tables.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadRows(String tableName) async {
    final response = await _supabase.from(tableName).select().limit(200);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Equipment>> _loadAllEquipment() async {
    final response = await _supabase
        .from('equipment')
        .select('*, equipment_images(id, image_url, display_order)')
        .order('created_at', ascending: false)
        .limit(200);

    return (response as List)
        .map((row) => Equipment.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> _deleteRow(_AdminTableConfig config, Map<String, dynamic> row) async {
    final id = row['id'];
    if (id == null) {
      _showMessage('This row has no id column to delete.', Colors.orange);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${config.label} Row'),
        content: const Text('This will permanently delete the selected row.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _supabase.from(config.tableName).delete().eq('id', id);
      if (!mounted) return;
      _showMessage('Deleted from ${config.tableName}.', Colors.green);
      setState(() {});
    } catch (e) {
      _showMessage('Delete failed: $e', Colors.red);
    }
  }

  Future<void> _openEditor(
    _AdminTableConfig config, {
    Map<String, dynamic>? row,
  }) async {
    final controllers = <String, TextEditingController>{};
    final fieldNames = {
      ...config.fields,
      if (row != null) ...row.keys,
    }.toList();

    for (final field in fieldNames) {
      controllers[field] = TextEditingController(
        text: row?[field]?.toString() ?? '',
      );
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(row == null ? 'Add ${config.label}' : 'Edit ${config.label}'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: fieldNames.map((field) {
                  final isReadOnly = row != null && field == 'id';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: controllers[field],
                      readOnly: isReadOnly,
                      minLines: field.contains('description') ||
                              field.contains('message') ||
                              field.contains('details') ||
                              field.contains('image_url')
                          ? 2
                          : 1,
                      maxLines: field.contains('image_url') ? 4 : 2,
                      decoration: InputDecoration(
                        labelText: field,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true) {
      for (final controller in controllers.values) {
        controller.dispose();
      }
      return;
    }

    final data = <String, dynamic>{};
    for (final entry in controllers.entries) {
      final field = entry.key;
      if (field == 'created_at' || field == 'updated_at') continue;
      if (row != null && field == 'id') continue;
      if (row?[field] is List || row?[field] is Map) continue;

      final rawValue = entry.value.text.trim();
      if (row == null && rawValue.isEmpty && field == 'id') continue;
      data[field] = _parseInput(rawValue);
    }

    for (final controller in controllers.values) {
      controller.dispose();
    }

    try {
      if (row == null) {
        await _supabase.from(config.tableName).insert(data);
        _showMessage('Added row to ${config.tableName}.', Colors.green);
      } else {
        await _supabase.from(config.tableName).update(data).eq('id', row['id']);
        _showMessage('Updated ${config.tableName}.', Colors.green);
      }
      if (mounted) setState(() {});
    } catch (e) {
      _showMessage('Save failed: $e', Colors.red);
    }
  }

  dynamic _parseInput(String value) {
    if (value.isEmpty || value.toLowerCase() == 'null') return null;
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue;
    final doubleValue = double.tryParse(value);
    if (doubleValue != null) return doubleValue;
    return value;
  }

  void _showDetails(_AdminTableConfig config, Map<String, dynamic> row) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${config.label} Details'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: row.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: Color(0xFFBB86FC),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(entry.value?.toString() ?? 'null'),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openEditor(config, row: row);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AdminAuthService.isAdminSignedIn) {
      return const Scaffold(body: Center(child: Text('Admin access required.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () {
              AdminAuthService.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tables
              .map((config) => Tab(icon: Icon(config.icon), text: config.label))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tables.map(_buildTableTab).toList(),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final config = _tables[_tabController.index];
          return FloatingActionButton.extended(
            onPressed: () => _openEditor(config),
            icon: const Icon(Icons.add),
            label: Text('Add ${config.label}'),
          );
        },
      ),
    );
  }

  Widget _buildTableTab(_AdminTableConfig config) {
    if (config.tableName == 'users') {
      return _buildUsersTab(config);
    }

    if (config.tableName == 'equipment') {
      return _buildEquipmentTab(config);
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadRows(config.tableName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _AdminErrorState(
            tableName: config.tableName,
            error: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }

        final rows = snapshot.data ?? [];
        if (rows.isEmpty) {
          return _AdminEmptyState(
            label: config.label,
            onAdd: () => _openEditor(config),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(_rowTitle(config, row)),
                  subtitle: Text(
                    _rowSubtitle(row),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _showDetails(config, row),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _openEditor(config, row: row),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => _deleteRow(config, row),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUsersTab(_AdminTableConfig config) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadRows(config.tableName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _AdminErrorState(
            tableName: config.tableName,
            error: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return _AdminEmptyState(
            label: config.label,
            onAdd: () => _openEditor(config),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final name = user['name']?.toString();
              final email = user['email']?.toString() ?? 'No email';
              final initial = (name?.isNotEmpty == true ? name! : email)
                  .characters
                  .first
                  .toUpperCase();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE87C31),
                    foregroundColor: Colors.white,
                    child: Text(initial),
                  ),
                  title: Text(name?.isNotEmpty == true ? name! : 'Unnamed User'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(email),
                      if (user['phone'] != null) Text('Phone: ${user['phone']}'),
                      if (user['created_at'] != null)
                        Text('Joined: ${user['created_at']}'),
                    ],
                  ),
                  onTap: () => _showDetails(config, user),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _openEditor(config, row: user),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => _deleteRow(config, user),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEquipmentTab(_AdminTableConfig config) {
    return FutureBuilder<List<Equipment>>(
      future: _loadAllEquipment(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _AdminErrorState(
            tableName: config.tableName,
            error: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }

        final equipment = snapshot.data ?? [];
        if (equipment.isEmpty) {
          return _AdminEmptyState(
            label: config.label,
            onAdd: () => _openEditor(config),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              if (isWide) {
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth >= 1050 ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: equipment.length,
                  itemBuilder: (context, index) =>
                      _buildAdminEquipmentCard(config, equipment[index]),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: equipment.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildAdminEquipmentCard(config, equipment[index]),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAdminEquipmentCard(
    _AdminTableConfig config,
    Equipment equipment,
  ) {
    final row = equipment.toJson();
    row['equipment_images'] = equipment.images
        .map((image) => {'image_url': image})
        .toList(growable: false);

    return GestureDetector(
      onTap: () => _showDetails(config, row),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildEquipmentImage(equipment.firstImage),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _buildStatusBadge(equipment.status),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _buildStatusBadge(
                      equipment.isPublic ? 'public' : 'private',
                      color: equipment.isPublic ? Colors.blue : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (equipment.category?.isNotEmpty == true)
                      Text(
                        equipment.category!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    const Spacer(),
                    Text(
                      'TK ${equipment.perDayPrice.toStringAsFixed(2)}/day',
                      style: const TextStyle(
                        color: Color(0xFFE87C31),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (equipment.locationName?.isNotEmpty == true)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              equipment.locationName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openEditor(config, row: row),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Delete',
                          onPressed: () => _deleteRow(config, row),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentImage(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return Container(
        color: const Color(0xFF0F0F0F),
        child: const Icon(Icons.image_outlined, color: Colors.grey, size: 42),
      );
    }

    if (imageData.startsWith('http')) {
      return Image.network(
        imageData,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: Color(0xFF0F0F0F),
          child: Center(
            child: Icon(Icons.image_not_supported, color: Colors.grey),
          ),
        ),
      );
    }

    try {
      final base64Data = imageData.contains(',')
          ? imageData.split(',').last
          : imageData;
      final bytes = base64Decode(base64Data.replaceAll('\n', ''));
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      return Container(
        color: const Color(0xFF0F0F0F),
        child: const Icon(
          Icons.image_not_supported,
          color: Colors.grey,
          size: 42,
        ),
      );
    }
  }

  Widget _buildStatusBadge(String text, {Color? color}) {
    final badgeColor = color ?? _statusColor(text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'unavailable':
        return Colors.red;
      case 'available_from':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _rowTitle(_AdminTableConfig config, Map<String, dynamic> row) {
    for (final key in [
      'name',
      'email',
      'content',
      'message',
      'action',
      'transaction_id',
      'id',
    ]) {
      final value = row[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return config.tableName;
  }

  String _rowSubtitle(Map<String, dynamic> row) {
    final usefulEntries = row.entries
        .where((entry) => entry.value != null && entry.key != 'image_url')
        .take(4)
        .map((entry) => '${entry.key}: ${entry.value}');
    return usefulEntries.join('  |  ');
  }
}

class _AdminTableConfig {
  final String label;
  final String tableName;
  final IconData icon;
  final List<String> fields;

  const _AdminTableConfig({
    required this.label,
    required this.tableName,
    required this.icon,
    required this.fields,
  });
}

class _AdminEmptyState extends StatelessWidget {
  final String label;
  final VoidCallback onAdd;

  const _AdminEmptyState({required this.label, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 12),
          Text('No $label rows found'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text('Add $label'),
          ),
        ],
      ),
    );
  }
}

class _AdminErrorState extends StatelessWidget {
  final String tableName;
  final String error;
  final VoidCallback onRetry;

  const _AdminErrorState({
    required this.tableName,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            Text(
              'Could not load $tableName',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
