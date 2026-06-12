import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipment.dart';
import '../services/equipment_service.dart';
import 'add_equipment_page.dart';
import 'my_requests_page.dart';

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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(100),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(splashColor: Colors.transparent),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFFBB86FC),
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: const Color(0xFFBB86FC),
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(icon: Icon(Icons.inventory), text: 'My Gear'),
                      Tab(icon: Icon(Icons.add_circle_outline), text: 'Add'),
                      Tab(icon: Icon(Icons.bar_chart), text: 'Analytics'),
                      Tab(icon: Icon(Icons.mail), text: 'Requests'),
                      Tab(icon: Icon(Icons.history), text: 'History'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMyEquipmentTab(),
            const AddEquipmentPage(),
            _buildAnalyticsTab(),
            _buildRequestsTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

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

  Widget _buildEquipmentCard(Equipment equipment) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0),
                        Colors.black.withOpacity(0.3),
                      ],
                      stops: const [0, 1],
                    ).createShader(rect);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    color: const Color(0xFF2A2A2A),
                    child: equipment.images.isNotEmpty
                        ? Image.memory(
                            convert.base64Decode(equipment.images.first),
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.image_not_supported_outlined,
                            size: 64,
                            color: Colors.grey[700],
                          ),
                  ),
                ),

                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(equipment.status)
                          .withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      equipment.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                if (equipment.images.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image_outlined,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${equipment.images.length}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBB86FC)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFBB86FC)
                                  .withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            'TK ${equipment.perDayPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Color(0xFFBB86FC)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return const Center(child: Text('Analytics Coming Soon'));
  }

  Widget _buildRequestsTab() {
    return const MyRequestsPage();
  }

  Widget _buildHistoryTab() {
    return const Center(child: Text('History Coming Soon'));
  }

  Color _getStatusColor(String status) {
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

  void _deleteEquipment(String id) async {
    await _equipmentService.deleteEquipment(id);
    setState(() {});
  }
}