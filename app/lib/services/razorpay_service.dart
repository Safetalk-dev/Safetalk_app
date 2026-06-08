import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  static final RazorpayService _instance = RazorpayService._internal();
  factory RazorpayService() => _instance;
  RazorpayService._internal();

  late Razorpay _razorpay;
  bool _isInitialized = false;

  Function(String paymentId)? _successCallback;
  Function(String code, String message)? _errorCallback;

  /// Setup payment event listeners. Safely bypasses native initialization on non-mobile platforms.
  void initialize({
    required Function(String paymentId) onSuccess,
    required Function(String code, String message) onFailure,
  }) {
    _successCallback = onSuccess;
    _errorCallback = onFailure;

    // Razorpay only supports Android & iOS natively in Flutter.
    // If run on Web or Desktop (Windows/macOS/Linux), bypass the SDK initialization to avoid crashes.
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      debugPrint('RazorpayService: Native SDK is not supported on this platform. Seamless desktop fallback enabled.');
      return;
    }

    if (!_isInitialized) {
      try {
        _razorpay = Razorpay();
        _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
        _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
        _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
        _isInitialized = true;
        debugPrint('RazorpayService: Native SDK initialized successfully.');
      } catch (e) {
        debugPrint('RazorpayService: Failed to initialize native Razorpay: $e');
      }
    }
  }

  /// Whether the current running platform supports the native Razorpay checkout sheet
  bool get isNativeSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Trigger payment checkout interface
  void openCheckout({
    required int amountInRupees,
    required String description,
    required String userEmail,
    required String userPhone,
  }) {
    if (!isNativeSupported) {
      debugPrint('RazorpayService: Platform is not native mobile. Bypassing native SDK and triggering simulated overlay.');
      return;
    }

    final options = {
      'key': 'rzp_test_demoKeySafeTalk', // Standard sandbox API key for development/demo
      'amount': amountInRupees * 100, // Razorpay takes amount in sub-units (paisa: ₹150 = 15000)
      'name': 'SafeTalk Care Sessions',
      'description': description,
      'timeout': 300, // Timeout in seconds (5 minutes)
      'prefill': {
        'contact': userPhone,
        'email': userEmail,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay Checkout failed to open: $e');
      _errorCallback?.call('-1', 'Failed to launch payment sheet: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Successful: ${response.paymentId}');
    _successCallback?.call(response.paymentId ?? 'pay_success_id_native');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Failure: ${response.code} - ${response.message}');
    _errorCallback?.call(response.code.toString(), response.message ?? 'Unknown checkout error');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet Selected: ${response.walletName}');
    _successCallback?.call('wallet_${response.walletName}');
  }

  /// Clean up resources and event handlers
  void dispose() {
    if (_isInitialized && isNativeSupported) {
      _razorpay.clear();
      _isInitialized = false;
      debugPrint('RazorpayService: Native event listeners cleared.');
    }
  }
}
