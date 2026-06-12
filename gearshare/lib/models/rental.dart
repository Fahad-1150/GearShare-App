import 'package:flutter/material.dart';

enum RentalStatus {
  requested,
  approved,
  pending,
  accepted,
  rejected,
  canceledByRequester,
  running,
  completed,
  disputed,
}

enum PaymentStatusEnum {
  pending,
  processing,
  completed,
  processingForRefund,
  refunded,
  canceled,
}

class Rental {
  final String id;
  final String equipmentId;
  final String ownerId;
  final String requesterId;

  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;

  final double perDayPrice;
  final int discountPercentage;
  final double subtotal;
  final double discountAmount;
  final double totalAmount;

  final RentalStatus rentalStatus;
  final PaymentStatusEnum paymentStatus;

  final DateTime? paymentTime;
  final String? paymentMethod;
  final String? transactionId;

  final DateTime? ownerGaveConfirmationAt;
  final DateTime? requesterReceivedConfirmationAt;

  final String? notes;
  final String? cancellationReason;
  final double? refundAmount;
  final DateTime? refundProcessedAt;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  // Equipment information
  final String? equipmentName;
  final String? equipmentStatus;
  final String? equipmentCategory;
  final String? equipmentDescription;
  final String? equipmentLocationName;

  Rental({
    required this.id,
    required this.equipmentId,
    required this.ownerId,
    required this.requesterId,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.perDayPrice,
    this.discountPercentage = 0,
    required this.subtotal,
    this.discountAmount = 0,
    required this.totalAmount,
    this.rentalStatus = RentalStatus.requested,
    this.paymentStatus = PaymentStatusEnum.pending,
    this.paymentTime,
    this.paymentMethod,
    this.transactionId,
    this.ownerGaveConfirmationAt,
    this.requesterReceivedConfirmationAt,
    this.notes,
    this.cancellationReason,
    this.refundAmount,
    this.refundProcessedAt,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.equipmentName,
    this.equipmentStatus,
    this.equipmentCategory,
    this.equipmentDescription,
    this.equipmentLocationName,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      id: json['id'] ?? '',
      equipmentId: json['equipment_id'] ?? '',
      ownerId: json['owner_id'] ?? '',
      requesterId: json['requester_id'] ?? '',
      startDate: DateTime.parse(
        json['start_date'] ?? DateTime.now().toString(),
      ),
      endDate: DateTime.parse(json['end_date'] ?? DateTime.now().toString()),
      totalDays: json['total_days'] ?? 1,
      perDayPrice: (json['per_day_price'] ?? 0).toDouble(),
      discountPercentage: json['discount_percentage'] ?? 0,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      rentalStatus: _parseRentalStatus(json['rental_status']),
      paymentStatus: _parsePaymentStatus(json['payment_status']),
      paymentTime: json['payment_time'] != null
          ? DateTime.parse(json['payment_time'])
          : null,
      paymentMethod: json['payment_method'],
      transactionId: json['transaction_id'],
      ownerGaveConfirmationAt: json['owner_gave_confirmation_at'] != null
          ? DateTime.parse(json['owner_gave_confirmation_at'])
          : null,
      requesterReceivedConfirmationAt:
          json['requester_received_confirmation_at'] != null
          ? DateTime.parse(json['requester_received_confirmation_at'])
          : null,
      notes: json['notes'],
      cancellationReason: json['cancellation_reason'],
      refundAmount: json['refund_amount'] != null
          ? (json['refund_amount'] as num).toDouble()
          : null,
      refundProcessedAt: json['refund_processed_at'] != null
          ? DateTime.parse(json['refund_processed_at'])
          : null,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toString(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toString(),
      ),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      equipmentName: json['equipment']?['name'] as String?,
      equipmentStatus: json['equipment']?['status'] as String?,
      equipmentCategory: json['equipment']?['category'] as String?,
      equipmentDescription: json['equipment']?['description'] as String?,
      equipmentLocationName: json['equipment']?['location_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipment_id': equipmentId,
      'owner_id': ownerId,
      'requester_id': requesterId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_days': totalDays,
      'per_day_price': perDayPrice,
      'discount_percentage': discountPercentage,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'rental_status': _rentalStatusToString(rentalStatus),
      'payment_status': _paymentStatusToString(paymentStatus),
      'payment_time': paymentTime?.toIso8601String(),
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'owner_gave_confirmation_at': ownerGaveConfirmationAt?.toIso8601String(),
      'requester_received_confirmation_at': requesterReceivedConfirmationAt
          ?.toIso8601String(),
      'notes': notes,
      'cancellation_reason': cancellationReason,
      'refund_amount': refundAmount,
      'refund_processed_at': refundProcessedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'equipment_name': equipmentName,
      'equipment_status': equipmentStatus,
      'equipment_category': equipmentCategory,
      'equipment_description': equipmentDescription,
      'equipment_location_name': equipmentLocationName,
    };
  }

  static RentalStatus _parseRentalStatus(String? status) {
    if (status == null) return RentalStatus.requested;
    switch (status.toLowerCase()) {
      case 'approved':
        return RentalStatus.approved;
      case 'pending':
        return RentalStatus.pending;
      case 'accepted':
        return RentalStatus.accepted;
      case 'rejected':
        return RentalStatus.rejected;
      case 'canceled_by_requester':
        return RentalStatus.canceledByRequester;
      case 'running':
        return RentalStatus.running;
      case 'completed':
        return RentalStatus.completed;
      case 'disputed':
        return RentalStatus.disputed;
      default:
        return RentalStatus.requested;
    }
  }

  static String _rentalStatusToString(RentalStatus status) {
    switch (status) {
      case RentalStatus.approved:
        return 'approved';
      case RentalStatus.pending:
        return 'pending';
      case RentalStatus.accepted:
        return 'accepted';
      case RentalStatus.rejected:
        return 'rejected';
      case RentalStatus.canceledByRequester:
        return 'canceled_by_requester';
      case RentalStatus.running:
        return 'running';
      case RentalStatus.completed:
        return 'completed';
      case RentalStatus.disputed:
        return 'disputed';
      default:
        return 'requested';
    }
  }

  static PaymentStatusEnum _parsePaymentStatus(String? status) {
    if (status == null) return PaymentStatusEnum.pending;
    switch (status.toLowerCase()) {
      case 'processing':
        return PaymentStatusEnum.processing;
      case 'completed':
        return PaymentStatusEnum.completed;
      case 'processing_for_refund':
        return PaymentStatusEnum.processingForRefund;
      case 'refunded':
        return PaymentStatusEnum.refunded;
      case 'canceled':
        return PaymentStatusEnum.canceled;
      default:
        return PaymentStatusEnum.pending;
    }
  }

  static String _paymentStatusToString(PaymentStatusEnum status) {
    switch (status) {
      case PaymentStatusEnum.processing:
        return 'processing';
      case PaymentStatusEnum.completed:
        return 'completed';
      case PaymentStatusEnum.processingForRefund:
        return 'processing_for_refund';
      case PaymentStatusEnum.refunded:
        return 'refunded';
      case PaymentStatusEnum.canceled:
        return 'canceled';
      default:
        return 'pending';
    }
  }

  String getStatusDisplay() {
    switch (rentalStatus) {
      case RentalStatus.requested:
        return 'Requested';
      case RentalStatus.approved:
        return 'Approved';
      case RentalStatus.pending:
        return 'Pending';
      case RentalStatus.accepted:
        return 'Accepted';
      case RentalStatus.rejected:
        return 'Rejected';
      case RentalStatus.canceledByRequester:
        return 'Canceled';
      case RentalStatus.running:
        return 'Running';
      case RentalStatus.completed:
        return 'Completed';
      case RentalStatus.disputed:
        return 'Disputed';
    }
  }

  Color getStatusColor() {
    switch (rentalStatus) {
      case RentalStatus.requested:
        return Colors.orange;
      case RentalStatus.approved:
        return Colors.blue;
      case RentalStatus.pending:
        return Colors.yellow;
      case RentalStatus.accepted:
        return Colors.green;
      case RentalStatus.rejected:
        return Colors.red;
      case RentalStatus.canceledByRequester:
        return Colors.red;
      case RentalStatus.running:
        return Colors.purple;
      case RentalStatus.completed:
        return Colors.green;
      case RentalStatus.disputed:
        return Colors.red;
    }
  }

  String getPaymentStatusDisplay() {
    switch (paymentStatus) {
      case PaymentStatusEnum.pending:
        return 'Pending';
      case PaymentStatusEnum.processing:
        return 'Processing';
      case PaymentStatusEnum.completed:
        return 'Completed';
      case PaymentStatusEnum.processingForRefund:
        return 'Processing Refund';
      case PaymentStatusEnum.refunded:
        return 'Refunded';
      case PaymentStatusEnum.canceled:
        return 'Canceled';
    }
  }

  Color getPaymentStatusColor() {
    switch (paymentStatus) {
      case PaymentStatusEnum.pending:
        return Colors.orange;
      case PaymentStatusEnum.processing:
        return Colors.blue;
      case PaymentStatusEnum.completed:
        return Colors.green;
      case PaymentStatusEnum.processingForRefund:
        return Colors.yellow;
      case PaymentStatusEnum.refunded:
        return Colors.red;
      case PaymentStatusEnum.canceled:
        return Colors.red;
    }
  }
}
