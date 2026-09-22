import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String? message;
  
  const VerifyEmailScreen({super.key, required this.email, this.message});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  bool _isLoading = false;
  bool _isResending = false;
  String _error = '';
  String _success = '';
  
  int _timeLeft = 600; // 10 minutes
  int _resendTimer = 0;
  bool _showResend = false;
  Timer? _countdownTimer;
  Timer? _resendCooldownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.message != null) {
      _error = widget.message!;
    }
    _startTimers();
  }

  void _startTimers() {
    _countdownTimer?.cancel();
    _resendCooldownTimer?.cancel();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft <= 0) {
        timer.cancel();
        setState(() {
          _showResend = true;
        });
      } else {
        setState(() {
          _timeLeft--;
        });
      }
    });

    if (_resendTimer > 0) {
      _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_resendTimer <= 0) {
          timer.cancel();
        } else {
          setState(() {
            _resendTimer--;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _countdownTimer?.cancel();
    _resendCooldownTimer?.cancel();
    super.dispose();
  }

  void _handleOtpChange(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {}); // To trigger rebuild for button enable/disable
  }

  void _handleBackspace(int index, RawKeyEvent event) {
    // Handling backspace to go to previous node can be complex in Flutter with TextField
    // We'll rely on the user tapping the previous field or using the keyboard delete.
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _handleVerifyOTP() async {
    final otpCode = _otpControllers.map((c) => c.text).join('');
    if (otpCode.length != 6) {
      setState(() { _error = 'Please enter a 6-digit OTP'; });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _success = '';
    });

    try {
      final response = await ApiService.post('/auth/verify-otp', body: {
        'email': widget.email,
        'otp': otpCode,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() { _success = data['message'] ?? 'Email verified successfully!'; });
        
        // Store token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(data));
        
        // Update auth provider state
        if (mounted) {
          await context.read<AuthProvider>().checkAuthStatus();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              context.go('/login', extra: {'message': 'Email verified! You can login after admin approval.'});
            }
          });
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() { _error = data['message'] ?? 'OTP verification failed'; });
      }
    } catch (e) {
      setState(() { _error = 'An error occurred during verification'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _handleResendOTP() async {
    setState(() {
      _isResending = true;
      _error = '';
      _success = '';
    });

    try {
      final response = await ApiService.post('/auth/resend-otp', body: {
        'email': widget.email,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _success = data['message'] ?? 'OTP sent successfully';
          for (var c in _otpControllers) {
            c.clear();
          }
          _timeLeft = 600;
          _resendTimer = 60;
          _showResend = false;
        });
        _startTimers();
      } else {
        final data = jsonDecode(response.body);
        setState(() { _error = data['message'] ?? 'Failed to resend OTP'; });
      }
    } catch (e) {
      setState(() { _error = 'An error occurred while resending OTP'; });
    } finally {
      setState(() { _isResending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.email.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/register');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.mail_outline, size: 48, color: Colors.white),
                      const SizedBox(height: 16),
                      const Text(
                        'Verify Email',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'ve sent a 6-digit OTP to\n${widget.email}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 45,
                            child: TextField(
                              controller: _otpControllers[index],
                              focusNode: _focusNodes[index],
                              maxLength: 1,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green[600]!, width: 2)),
                              ),
                              onChanged: (val) => _handleOtpChange(index, val),
                            ),
                          );
                        }),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      if (_error.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                          child: Text(_error, style: TextStyle(color: Colors.red[700], fontSize: 14)),
                        ),
                        
                      if (_success.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                          child: Text(_success, style: TextStyle(color: Colors.green[700], fontSize: 14)),
                        ),
                        
                      Text(
                        'OTP expires in: ${_formatTime(_timeLeft)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _timeLeft < 120 ? Colors.red : Colors.grey[600],
                        ),
                      ),
                      if (_showResend)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text('OTP has expired. Please request a new one.', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                        
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading || _otpControllers.any((c) => c.text.isEmpty) ? null : _handleVerifyOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Verify OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      const Text("Didn't receive the OTP?", style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _resendTimer > 0 || _isResending || !_showResend ? null : _handleResendOTP,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(_resendTimer > 0 ? 'Resend in ${_resendTimer}s' : _isResending ? 'Sending...' : 'Resend OTP'),
                        style: TextButton.styleFrom(foregroundColor: Colors.green[700]),
                      ),
                      
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text('← Back to Registration', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
