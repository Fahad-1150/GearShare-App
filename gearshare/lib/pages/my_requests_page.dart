import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rental.dart';
import 'rental_details_page.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Rental> _rentalRequests = [];
  List<Rental> _rentalRequestsAsOwner = [];
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRentalRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRentalRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      // Load rental requests where user is the requester (with equipment details)
      final requesterData = await _supabase
          .from('rentals')
          .select(
            '*, equipment:equipment_id(id, name, status, category, description, location_name)',
          )
          .eq('requester_id', currentUser.id)
          .order('created_at', ascending: false);

      // Load rental requests where user is the owner (with equipment details)
      final ownerData = await _supabase
          .from('rentals')
          .select(
            '*, equipment:equipment_id(id, name, status, category, description, location_name)',
          )
          .eq('owner_id', currentUser.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _rentalRequests = (requesterData as List)
              .map((r) => Rental.fromJson(r))
              .toList();
          _rentalRequestsAsOwner = (ownerData as List)
              .map((r) => Rental.fromJson(r))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading rental requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveRequest(Rental rental) async {
    try {
      await _supabase
          .from('rentals')
          .update({'rental_status': 'approved'})
          .eq('id', rental.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request approved!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRentalRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(Rental rental) async {
    try {
      await _supabase
          .from('rentals')
          .update({'rental_status': 'rejected'})
          .eq('id', rental.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request rejected!'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadRentalRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelRequest(Rental rental) async {
    try {
      await _supabase
          .from('rentals')
          .update({'rental_status': 'canceled_by_requester'})
          .eq('id', rental.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request canceled!'),
            backgroundColor: Colors.red,
          ),
        );
        _loadRentalRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error canceling request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processPayment(Rental rental) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Process Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: TK ${rental.totalAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('Select payment method:'),
            const SizedBox(height: 8),
            const Text(
              'Note: In a real app, integrate with Stripe/PayPal here',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Simulate payment processing
              _simulatePaymentProcessing(rental);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBB86FC),
            ),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _simulatePaymentProcessing(Rental rental) async {
    try {
      // Update rental status to mark payment as completed
      await _supabase
          .from('rentals')
          .update({
            'payment_status': 'completed',
            'rental_status': 'accepted',
            'payment_time': DateTime.now().toIso8601String(),
            'transaction_id': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
          })
          .eq('id', rental.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRentalRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmGiven(Rental rental) async {
    try {
      await _supabase
          .from('rentals')
          .update({
            'owner_gave_confirmation_at': DateTime.now().toIso8601String(),
            'rental_status': 'running',
          })
          .eq('id', rental.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Confirmed equipment given!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRentalRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmReceived(Rental rental) async {
    try {
      await _supabase
          .from('rentals')
          .update({
            'requester_received_confirmation_at': DateTime.now()
                .toIso8601String(),
            'rental_status': 'running',
          })
          .eq('id', rental.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Confirmed equipment received!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRentalRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeRental(Rental rental) async {
    try {
      await _supabase
          .from('rentals')
          .update({
            'rental_status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', rental.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rental completed! Equipment is now available.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRentalRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing rental: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRentalCard(Rental rental, bool isOwner) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Equipment Information Section
          if (rental.equipmentName != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rental.equipmentName ?? 'Unknown Equipment',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBB86FC),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (rental.equipmentCategory != null)
                    Row(
                      children: [
                        const Text(
                          'Category: ',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          rental.equipmentCategory!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Equipment Status',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getEquipmentStatusColor(
                                rental.equipmentStatus,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              rental.equipmentStatus
                                      ?.replaceAll('_', ' ')
                                      .toUpperCase() ??
                                  'UNKNOWN',
                              style: TextStyle(
                                color: _getEquipmentStatusColor(
                                  rental.equipmentStatus,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (rental.equipmentLocationName != null)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rental.equipmentLocationName!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (rental.equipmentDescription != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      rental.equipmentDescription!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rental ID: ${rental.id.substring(0, 8)}...',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rental.startDate.toString().split(' ')[0]} to ${rental.endDate.toString().split(' ')[0]}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: rental.getStatusColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rental.getStatusDisplay(),
                  style: TextStyle(
                    color: rental.getStatusColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TK ${rental.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBB86FC),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: rental.getPaymentStatusColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rental.getPaymentStatusDisplay(),
                  style: TextStyle(
                    color: rental.getPaymentStatusColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons based on status and user role
          _buildActionButtons(rental, isOwner),
        ],
      ),
    );
  }

  Color _getEquipmentStatusColor(String? status) {
    if (status == null) return Colors.grey;
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

  Widget _buildClickableRentalCard(Rental rental, bool isOwner) {
    return GestureDetector(
      onTap: () async {
        final shouldRefresh = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RentalDetailsPage(rental: rental, isOwner: isOwner),
          ),
        );

        if (shouldRefresh == true && mounted) {
          _loadRentalRequests();
        }
      },
      child: _buildRentalCard(rental, isOwner),
    );
  }

  Widget _buildActionButtons(Rental rental, bool isOwner) {
    final buttons = <Widget>[];

    if (isOwner) {
      // Owner actions
      if (rental.rentalStatus == RentalStatus.requested) {
        buttons.addAll([
          ElevatedButton(
            onPressed: () => _approveRequest(rental),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _rejectRequest(rental),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(fontSize: 12)),
          ),
        ]);
      } else if (rental.rentalStatus == RentalStatus.accepted &&
          rental.paymentStatus == PaymentStatusEnum.completed) {
        if (rental.ownerGaveConfirmationAt == null) {
          buttons.add(
            ElevatedButton(
              onPressed: () => _confirmGiven(rental),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text(
                'Confirm Given',
                style: TextStyle(fontSize: 12),
              ),
            ),
          );
        } else if (rental.requesterReceivedConfirmationAt != null &&
            rental.rentalStatus == RentalStatus.running) {
          if (DateTime.now().isAfter(rental.endDate)) {
            buttons.add(
              ElevatedButton(
                onPressed: () => _completeRental(rental),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  'Complete Rental',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            );
          }
        }
      }
    } else {
      // Requester actions
      if (rental.rentalStatus == RentalStatus.requested ||
          rental.rentalStatus == RentalStatus.pending) {
        buttons.add(
          ElevatedButton(
            onPressed: () => _cancelRequest(rental),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
        );
      } else if (rental.rentalStatus == RentalStatus.approved &&
          rental.paymentStatus == PaymentStatusEnum.pending) {
        buttons.add(
          ElevatedButton(
            onPressed: () => _processPayment(rental),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBB86FC),
            ),
            child: const Text(
              'Complete Payment',
              style: TextStyle(fontSize: 12),
            ),
          ),
        );
      } else if (rental.rentalStatus == RentalStatus.accepted &&
          rental.paymentStatus == PaymentStatusEnum.completed) {
        if (rental.requesterReceivedConfirmationAt == null) {
          buttons.add(
            ElevatedButton(
              onPressed: () => _confirmReceived(rental),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text(
                'Confirm Received',
                style: TextStyle(fontSize: 12),
              ),
            ),
          );
        } else if (rental.ownerGaveConfirmationAt != null &&
            rental.rentalStatus == RentalStatus.running) {
          if (DateTime.now().isAfter(rental.endDate)) {
            buttons.add(
              ElevatedButton(
                onPressed: () => _completeRental(rental),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  'Complete Rental',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            );
          }
        }
      }
    }

    if (buttons.isEmpty) {
      buttons.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const Text(
            'No actions available',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: buttons);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('My Rental Requests'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Requests'),
            Tab(text: 'Booking Requests'),
            Tab(text: 'Active Rentals'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBB86FC)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadRentalRequests,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: My Requests (as requester)
                  _rentalRequests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 48,
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              const Text('No rental requests yet'),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: _rentalRequests
                              .map((r) => _buildClickableRentalCard(r, false))
                              .toList(),
                        ),
                  // Tab 2: Booking Requests (as owner)
                  _rentalRequestsAsOwner
                          .where(
                            (r) =>
                                r.rentalStatus == RentalStatus.requested ||
                                r.rentalStatus == RentalStatus.pending,
                          )
                          .isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 48,
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              const Text('No booking requests'),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: _rentalRequestsAsOwner
                              .where(
                                (r) =>
                                    r.rentalStatus == RentalStatus.requested ||
                                    r.rentalStatus == RentalStatus.pending,
                              )
                              .map((r) => _buildClickableRentalCard(r, true))
                              .toList(),
                        ),
                  // Tab 3: Active Rentals
                  _rentalRequests
                          .where(
                            (r) =>
                                r.rentalStatus == RentalStatus.running ||
                                (r.rentalStatus == RentalStatus.accepted &&
                                    r.paymentStatus ==
                                        PaymentStatusEnum.completed),
                          )
                          .isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_run,
                                size: 48,
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              const Text('No active rentals'),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: _rentalRequests
                              .where(
                                (r) =>
                                    r.rentalStatus == RentalStatus.running ||
                                    (r.rentalStatus == RentalStatus.accepted &&
                                        r.paymentStatus ==
                                            PaymentStatusEnum.completed),
                              )
                              .map((r) => _buildClickableRentalCard(r, false))
                              .toList(),
                        ),
                ],
              ),
            ),
    );
  }
}
