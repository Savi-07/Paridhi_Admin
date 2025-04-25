import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_background.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late TextEditingController _otpController;
  Timer? _resendTimer;
  Timer? _expiryTimer;
  int _resendSeconds = 30;
  int _expirySeconds = 600;
  bool _isResendEnabled = false;
  String _currentText = "";
  bool _isLoading = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _startResendTimer();
    _startExpiryTimer();
    debugPrint('OTP Verification Screen initialized with email: ${widget.email}');
  }

  @override
  void dispose() {
    _disposed = true;
    _resendTimer?.cancel();
    _expiryTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) return timer.cancel();
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        setState(() => _isResendEnabled = true);
        timer.cancel();
      }
    });
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) return timer.cancel();
      if (_expirySeconds > 0) {
        setState(() => _expirySeconds--);
      } else {
        timer.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP has expired. Please try again.')),
          );
          Navigator.pop(context);
        }
      }
    });
  }

  Future<void> _sendOtp() async {
    if (_disposed) return;
    setState(() => _isLoading = true);

    final success = await context.read<AuthProvider>().sendOtp(widget.email);
    final error = context.read<AuthProvider>().error;
    setState(() => _isLoading = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to send OTP. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully. Please check your email.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (!_isResendEnabled || _disposed) return;
    setState(() {
      _isLoading = true;
      _isResendEnabled = false;
      _resendSeconds = 30;
      _expirySeconds = 600;
    });

    final success = await context.read<AuthProvider>().resendOtp(widget.email);
    final error = context.read<AuthProvider>().error;

    setState(() => _isLoading = false);

    if (success && mounted) {
      _startResendTimer();
      _startExpiryTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent successfully. Please check your email.'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      setState(() => _isResendEnabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to resend OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_currentText.length != 6 || _disposed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter complete 6-digit OTP')),
        );
      }
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(_currentText)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP must contain 6 digits only')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      final success = await context.read<AuthProvider>().verifyOtp(widget.email, _currentText);
      if (!mounted || _disposed) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP verified successfully'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final error = context.read<AuthProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Invalid OTP. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        _otpController.clear();
        setState(() => _currentText = "");
      }
    } catch (e) {
      if (mounted && !_disposed) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_disposed) return const SizedBox.shrink();
    var colour = Colors.white;

    return Scaffold(
      appBar: AppBar(
        foregroundColor: colour,
        title: const Text('Email Verification'),
        backgroundColor: const Color(0xFF1A1C1E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Container(
        height: double.infinity,
        child: AnimatedGradientBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: WillPopScope(
              onWillPop: () async {
                Navigator.of(context).pop(false);
                return false;
              },
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text('Enter verification code sent to:', style: TextStyle(color: colour)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.email,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 30),
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: _otpController,
                    onChanged: (value) {
                      if (!_disposed) setState(() => _currentText = value.trim());
                    },
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 50,
                      fieldWidth: 45,
                      activeFillColor: Theme.of(context).cardColor,
                      selectedFillColor: Theme.of(context).cardColor,
                      inactiveFillColor: Theme.of(context).cardColor,
                      activeColor: Theme.of(context).primaryColor,
                      selectedColor: Theme.of(context).primaryColor,
                      inactiveColor: Colors.grey,
                    ),
                    cursorColor: Theme.of(context).primaryColor,
                    animationDuration: const Duration(milliseconds: 300),
                    enableActiveFill: true,
                    keyboardType: TextInputType.number,
                    boxShadows: [
                      BoxShadow(
                        offset: const Offset(0, 1),
                        color: Colors.black12,
                        blurRadius: 10,
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'OTP expires in: ${_formatTime(_expirySeconds)}',
                    style: TextStyle(
                      color: _expirySeconds < 60 ? Colors.red : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _isResendEnabled ? _resendOtp : null,
                    child: Text(
                      _isResendEnabled
                          ? "Didn't receive OTP? Resend"
                          : 'Resend OTP in ${_formatTime(_resendSeconds)}',
                      style: TextStyle(color: colour),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // Loading overlay
      floatingActionButton: _isLoading
          ? Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
