import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rental.dart';

class RentalDetailsPage extends StatefulWidget {
  final Rental rental;
  final bool isOwner;

  const RentalDetailsPage({
    super.key,
    required this.rental,
    required this.isOwner,
  });

  @override
  State<RentalDetailsPage> createState() => _RentalDetailsPageState();
}

class _RentalDetailsPageState extends State<RentalDetailsPage> {
  final _supabase = Supabase.instance.client;

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
        Navigator.pop(context, true);
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
        Navigator.pop(context, true);
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
        Navigator.pop(context, true);
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
        Navigator.pop(context, true);
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
        Navigator.pop(context, true);
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
        Navigator.pop(context, true);
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
        Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Rental Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Equipment Section
              if (widget.rental.equipmentName != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Equipment Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBB86FC),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Equipment Name',
                        widget.rental.equipmentName ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Category',
                        widget.rental.equipmentCategory ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Status',
                        widget.rental.equipmentStatus ?? 'N/A',
                        valueColor: _getEquipmentStatusColor(
                          widget.rental.equipmentStatus,
                        ),
                      ),
                      _buildDetailRow(
                        'Location',
                        widget.rental.equipmentLocationName ?? 'N/A',
                      ),
                      if (widget.rental.equipmentDescription != null) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Description',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.rental.equipmentDescription!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Rental Status Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rental Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBB86FC),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Status',
                      widget.rental.getStatusDisplay(),
                      valueColor: widget.rental.getStatusColor(),
                    ),
                    _buildDetailRow(
                      'Payment Status',
                      widget.rental.getPaymentStatusDisplay(),
                      valueColor: widget.rental.getPaymentStatusColor(),
                    ),
                    _buildDetailRow(
                      'Rental ID',
                      widget.rental.id.substring(0, 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Dates Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rental Dates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBB86FC),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Start Date',
                      widget.rental.startDate.toString().split(' ')[0],
                    ),
                    _buildDetailRow(
                      'End Date',
                      widget.rental.endDate.toString().split(' ')[0],
                    ),
                    _buildDetailRow('Total Days', '${widget.rental.totalDays}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pricing Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pricing Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBB86FC),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Per Day Price',
                      'TK ${widget.rental.perDayPrice.toStringAsFixed(2)}',
                    ),
                    _buildDetailRow(
                      'Subtotal',
                      'TK ${widget.rental.subtotal.toStringAsFixed(2)}',
                    ),
                    if (widget.rental.discountPercentage > 0) ...[
                      _buildDetailRow(
                        'Discount (${widget.rental.discountPercentage}%)',
                        '-TK ${widget.rental.discountAmount.toStringAsFixed(2)}',
                        valueColor: Colors.green,
                      ),
                    ],
                    const Divider(color: Colors.white12),
                    _buildDetailRow(
                      'Total Amount',
                      'TK ${widget.rental.totalAmount.toStringAsFixed(2)}',
                      valueColor: const Color(0xFFBB86FC),
                      valueFontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Confirmation Status Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Confirmations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBB86FC),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildConfirmationRow(
                      'Owner Confirmed Given',
                      widget.rental.ownerGaveConfirmationAt,
                    ),
                    const SizedBox(height: 12),
                    _buildConfirmationRow(
                      'Requester Confirmed Received',
                      widget.rental.requesterReceivedConfirmationAt,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment Details Section
              if (widget.rental.paymentStatus == PaymentStatusEnum.completed ||
                  widget.rental.transactionId != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBB86FC),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (widget.rental.transactionId != null)
                        _buildDetailRow(
                          'Transaction ID',
                          widget.rental.transactionId!,
                        ),
                      if (widget.rental.paymentMethod != null)
                        _buildDetailRow(
                          'Payment Method',
                          widget.rental.paymentMethod!,
                        ),
                      if (widget.rental.paymentTime != null)
                        _buildDetailRow(
                          'Payment Time',
                          widget.rental.paymentTime.toString().split('.')[0],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action Buttons
              _buildActionButtons(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    FontWeight valueFontWeight = FontWeight.w500,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: valueFontWeight,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(String label, DateTime? dateTime) {
    final isConfirmed = dateTime != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Row(
          children: [
            Icon(
              isConfirmed ? Icons.check_circle : Icons.pending,
              color: isConfirmed ? Colors.green : Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isConfirmed ? dateTime.toString().split('.')[0] : 'Pending',
              style: TextStyle(
                fontSize: 12,
                color: isConfirmed ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final buttons = <Widget>[];

    if (widget.isOwner) {
      if (widget.rental.rentalStatus == RentalStatus.requested) {
        buttons.addAll([
          ElevatedButton(
            onPressed: () => _approveRequest(widget.rental),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _rejectRequest(widget.rental),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ]);
      } else if (widget.rental.rentalStatus == RentalStatus.accepted &&
          widget.rental.paymentStatus == PaymentStatusEnum.completed) {
        if (widget.rental.ownerGaveConfirmationAt == null) {
          buttons.add(
            ElevatedButton(
              onPressed: () => _confirmGiven(widget.rental),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Confirm Given'),
            ),
          );
        } else if (widget.rental.requesterReceivedConfirmationAt != null &&
            widget.rental.rentalStatus == RentalStatus.running) {
          if (DateTime.now().isAfter(widget.rental.endDate)) {
            buttons.add(
              ElevatedButton(
                onPressed: () => _completeRental(widget.rental),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Complete Rental'),
              ),
            );
          }
        }
      }
    } else {
      if (widget.rental.rentalStatus == RentalStatus.requested ||
          widget.rental.rentalStatus == RentalStatus.pending) {
        buttons.add(
          ElevatedButton(
            onPressed: () => _cancelRequest(widget.rental),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
        );
      } else if (widget.rental.rentalStatus == RentalStatus.approved &&
          widget.rental.paymentStatus == PaymentStatusEnum.pending) {
        buttons.add(
          ElevatedButton(
            onPressed: () => _processPayment(widget.rental),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBB86FC),
            ),
            child: const Text('Complete Payment'),
          ),
        );
      } else if (widget.rental.rentalStatus == RentalStatus.accepted &&
          widget.rental.paymentStatus == PaymentStatusEnum.completed) {
        if (widget.rental.requesterReceivedConfirmationAt == null) {
          buttons.add(
            ElevatedButton(
              onPressed: () => _confirmReceived(widget.rental),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Confirm Received'),
            ),
          );
        } else if (widget.rental.ownerGaveConfirmationAt != null &&
            widget.rental.rentalStatus == RentalStatus.running) {
          if (DateTime.now().isAfter(widget.rental.endDate)) {
            buttons.add(
              ElevatedButton(
                onPressed: () => _completeRental(widget.rental),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Complete Rental'),
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
}
