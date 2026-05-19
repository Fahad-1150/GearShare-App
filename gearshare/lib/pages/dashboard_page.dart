import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipment.dart';
import '../services/equipment_service.dart';
import 'add_equipment_page.dart';
import 'chat_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EquipmentService _equipmentService = EquipmentService();
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    final user = Supabase.instance.client.auth.currentUser;
    _userId = user?.id ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------- IMAGE ----------------
  Widget _buildPlaceholder() {
    return Container(
      color: const Color.fromARGB(255, 67, 67, 67),
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }

  Widget _buildEquipmentImage(String? imageData) {
    if (imageData == null || imageData.trim().isEmpty) {
      return _buildPlaceholder();
    }

    try {
      if (imageData.length > 1000) {
        final base64Str = imageData.contains(',')
            ? imageData.split(',').last
            : imageData;
        final bytes = convert.base64Decode(base64Str);
        return Image.memory(bytes, fit: BoxFit.cover);
      } else {
        return Image.network(
          imageData,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }
    } catch (_) {
      return _buildPlaceholder();
    }
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              expandedHeight: 140,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: const Text(
                    'My Gear',
                    style: TextStyle(color: Colors.white, fontSize: 26),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFBB86FC),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFBB86FC),
                tabs: const [
                  Tab(icon: Icon(Icons.inventory), text: 'My Gear'),
                  Tab(icon: Icon(Icons.add), text: 'Add'),
                  Tab(icon: Icon(Icons.bar_chart), text: 'Analytics'),
                  Tab(icon: Icon(Icons.message), text: 'Messages'),
                  Tab(icon: Icon(Icons.history), text: 'History'),
                ],
              ),
            ),
          ];
        },

        // ✅ Correct placement
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMyEquipmentTab(),
            const AddEquipmentPage(),
            _buildAnalyticsTab(),
            const ChatPage(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  // ---------------- MY EQUIPMENT ----------------
  Widget _buildMyEquipmentTab() {
    return FutureBuilder<List<Equipment>>(
      future: _equipmentService.getUserEquipment(_userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final list = snapshot.data ?? [];

        if (list.isEmpty) {
          return const Center(child: Text('No Equipment'));
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) => _buildEquipmentCard(list[i]),
        );
      },
    );
  }

  Widget _buildEquipmentCard(Equipment e) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.all(10),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: _buildEquipmentImage(
              e.images.isNotEmpty ? e.images.first : null,
            ),
          ),
          ListTile(
            title: Text(e.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              'TK ${e.perDayPrice}',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => _showEditDialog(e),
                child: const Text('Edit'),
              ),
              TextButton(
                onPressed: () => _deleteEquipment(e.id),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- EDIT ----------------
  void _showEditDialog(Equipment e) {
    final name = TextEditingController(text: e.name);
    final price = TextEditingController(text: e.perDayPrice.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name),
            TextField(controller: price, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _equipmentService.updateEquipment(
                equipmentId: e.id,
                name: name.text,
                perDayPrice: double.tryParse(price.text) ?? 0,
              );
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ---------------- DELETE ----------------
  void _deleteEquipment(String id) async {
    await _equipmentService.deleteEquipment(id);
    setState(() {});
  }

  // ---------------- OTHER TABS ----------------
  Widget _buildAnalyticsTab() {
    return const Center(child: Text('Analytics Coming Soon'));
  }

  Widget _buildHistoryTab() {
    return const Center(child: Text('History Coming Soon'));
  }
}
