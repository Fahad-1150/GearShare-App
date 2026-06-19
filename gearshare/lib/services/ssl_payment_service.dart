// ignore_for_file: deprecated_member_use
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sslcommerz/model/SSLCTransactionInfoModel.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../models/rental.dart';

enum SdkType { live, testbox }

class SSLPaymentService {
  static const MethodChannel _sslCommerzChannel = MethodChannel(
    'flutter_sslcommerz',
  );

  // ===== CONFIGURATION =====
  // Replace with your actual SSL store credentials.
  static const String storeId = 'testbox';
  static const String storePassword = 'qwerty';

  // Use TESTBOX for demo, LIVE for production.
  static SdkType sdkType = SdkType.testbox;

  // Payment gateway language.
  static String paymentLanguage = 'en'; // 'en' or 'bn' (Bangla)

  // ===== PAYMENT METHODS =====

  /// Initiate SSL Commerz payment for rental.
  static Future<SSLCTransactionInfoModel?> initiatePayment({
    required Rental rental,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String? ipnUrl,
  }) async {
    try {
      final safeCustomerName = _requiredText(customerName, 'Customer');
      final safeCustomerEmail = _requiredText(
        customerEmail,
        'customer@example.com',
      );
      final safeCustomerPhone = _requiredText(customerPhone, '01700000000');
      final safeEquipmentName = _requiredText(
        rental.equipmentName,
        'Equipment',
      );
      final safeCategory = _requiredText(
        rental.equipmentCategory,
        'Equipment',
      );
      final transactionId = _generateTransactionId(rental.id);

      print('Initiating SSL Commerz payment...');
      print('Rental ID: ${rental.id}');
      print('Amount: BDT ${rental.totalAmount.toStringAsFixed(2)}');
      print('Customer: $safeCustomerName ($safeCustomerEmail)');
      print('SDK Type: ${sdkType == SdkType.testbox ? "TESTBOX" : "LIVE"}');

      final paymentPayload = <String, dynamic>{
        'initializer': {
          'ipn_url': ipnUrl ?? 'https://gearshare.app/payment/ipn',
          'multi_card_name': '',
          'currency': 'BDT',
          'product_category': safeCategory,
          'sdkType': sdkType == SdkType.testbox ? 'TESTBOX' : 'LIVE',
          'store_id': storeId,
          'store_passwd': storePassword,
          'total_amount': rental.totalAmount,
          'tran_id': transactionId,
          'language': paymentLanguage,
        },
        'customerInfoInitializer': {
          'customerState': 'Dhaka',
          'customerName': safeCustomerName,
          'customerEmail': safeCustomerEmail,
          'customerAddress1': 'Dhaka, Bangladesh',
          'customerAddress2': null,
          'customerCity': 'Dhaka',
          'customerPostCode': '1000',
          'customerCountry': 'Bangladesh',
          'customerPhone': safeCustomerPhone,
          'customerFax': null,
        },
        'sslcemiTransactionInitializer': {
          'emi_options': 1,
          'emi_max_list_options': 9,
          'emi_selected_inst': 0,
        },
        'sslcShipmentInfoInitializer': {
          'shipmentMethod': 'yes',
          'shipAddress2': '',
          'shipState': 'Dhaka',
          'numOfItems': 1,
          'shipmentDetails': {
            'shipName': safeCustomerName,
            'shipAddress1': 'Equipment: $safeEquipmentName',
            'shipCity': 'Dhaka',
            'shipPostCode': '1000',
            'shipCountry': 'Bangladesh',
          },
        },
        'sslcProductInitializer': null,
        'sslcAdditionalInitializer': {
          'valueA': rental.id,
          'valueB': safeEquipmentName,
          'valueC': _formatDateRange(rental.startDate, rental.endDate),
          'valueD': rental.rentalStatus.toString(),
          'extras': {
            'rental_id': rental.id,
            'equipment_name': safeEquipmentName,
            'start_date': rental.startDate.toIso8601String(),
            'end_date': rental.endDate.toIso8601String(),
          },
        },
      };

      print('Sending payment request to SSL...');
      print('Opening SSL Commerz payment gateway...');

      SSLCTransactionInfoModel result;
      try {
        final response = await _sslCommerzChannel.invokeMethod<String>(
          'initiateSSLCommerz',
          jsonEncode(paymentPayload),
        );
        result = SSLCTransactionInfoModel.fromJson(
          jsonDecode(response ?? '{}') as Map<String, dynamic>,
        );
      } catch (platformError) {
        print('Platform Error: $platformError');
        if (platformError.toString().contains('MissingPlugin')) {
          print('SSL Commerz plugin not available on this platform');
          print(
            'Make sure you are running on a real device or Android emulator with Google Play Services',
          );
          _showErrorMessage(
            'Payment plugin not available.\n\n'
            'Please use an Android device or emulator with Google Play Services.',
          );
          return null;
        }
        rethrow;
      }

      print('Payment Result: Status=${result.status}');
      return result;
    } catch (e) {
      print('Payment Error: $e');
      print('Error Type: ${e.runtimeType}');
      _showErrorMessage('Payment Error: ${e.toString()}');
      return null;
    }
  }

  /// Handle payment result and show appropriate message.
  static void handlePaymentResult(SSLCTransactionInfoModel? result) {
    if (result == null) {
      _showErrorMessage('Payment failed or cancelled');
      return;
    }

    final status = result.status?.toLowerCase() ?? 'unknown';
    print('Payment Status: $status');
    print('Transaction ID: ${result.tranId}');
    print('Amount: ${result.amount}');

    switch (status) {
      case 'success':
      case 'valid':
        _showSuccessMessage(
          'Payment Successful!\n'
          'Transaction ID: ${result.tranId}\n'
          'Amount: BDT ${result.amount}',
        );
        break;

      case 'failed':
        _showErrorMessage('Payment Failed. Please try again.');
        break;

      case 'closed':
        _showWarningMessage('Payment Cancelled by User');
        break;

      default:
        _showInfoMessage('Payment Status: $status');
    }
  }

  // ===== HELPER METHODS =====

  /// Generate unique transaction ID.
  static String _generateTransactionId(String rentalId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueId = rentalId.length > 8 ? rentalId.substring(0, 8) : rentalId;
    return 'TXN_${uniqueId}_$timestamp';
  }

  static String _requiredText(String? value, String fallback) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return fallback;
    }
    return trimmed;
  }

  /// Format date range for display.
  static String _formatDateRange(DateTime startDate, DateTime endDate) {
    final start = startDate.toString().split(' ')[0];
    final end = endDate.toString().split(' ')[0];
    return '$start to $end';
  }

  /// Show success message.
  static void _showSuccessMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFF4CAF50),
      textColor: const Color(0xFFFFFFFF),
      fontSize: 14.0,
    );
  }

  /// Show error message.
  static void _showErrorMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFFF44336),
      textColor: const Color(0xFFFFFFFF),
      fontSize: 14.0,
    );
  }

  /// Show warning message.
  static void _showWarningMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFFFF9800),
      textColor: const Color(0xFFFFFFFF),
      fontSize: 14.0,
    );
  }

  /// Show info message.
  static void _showInfoMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFF2196F3),
      textColor: const Color(0xFFFFFFFF),
      fontSize: 14.0,
    );
  }

  // ===== CONFIGURATION METHODS =====

  /// Set SDK type (TESTBOX or LIVE).
  static void setSdkType(SdkType type) {
    sdkType = type;
    print(
      'SDK Type changed to: ${type == SdkType.testbox ? "TESTBOX" : "LIVE"}',
    );
  }

  /// Set payment language.
  static void setPaymentLanguage(String language) {
    if (language == 'en' || language == 'bn') {
      paymentLanguage = language;
      print('Payment language changed to: $language');
    } else {
      print('Invalid language. Use "en" or "bn"');
    }
  }

  /// Update store credentials.
  static void updateCredentials(String newStoreId, String newPassword) {
    // Note: These are constants, so this is just for demonstration.
    // In a real app, load these from environment variables or config.
    print('Store credentials should be updated in the code constants');
    print('Current Store ID: $storeId');
  }
}
