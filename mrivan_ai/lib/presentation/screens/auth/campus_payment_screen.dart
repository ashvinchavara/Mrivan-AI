import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/database_service.dart';
import '../../widgets/animated_background.dart';
import '../../theme/theme_config.dart';

class CampusPaymentScreen extends StatefulWidget {
  final String planTitle;
  final String planPrice;
  final String planSubtitle;

  const CampusPaymentScreen({
    super.key,
    required this.planTitle,
    required this.planPrice,
    required this.planSubtitle,
  });

  @override
  State<CampusPaymentScreen> createState() => _CampusPaymentScreenState();
}

class _CampusPaymentScreenState extends State<CampusPaymentScreen> with SingleTickerProviderStateMixin {
  bool get _isDarkMode => isDarkModeNotifier.value;

  // Selected Payment Method: 'upi', 'card', 'net_banking'
  String _selectedMethod = 'upi';

  // UPI variables
  String _selectedUpiApp = 'Google Pay';
  final TextEditingController _upiIdController = TextEditingController();

  // Card variables
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();

  // Net Banking variables
  String _selectedBank = 'SBI';

  // Transaction simulation states
  bool _isProcessing = false;
  String _processingMessage = '';
  bool _isSuccess = false;

  // Campus Plan specific
  int _studentCount = 100;
  final TextEditingController _schoolNameController = TextEditingController();
  String? _inviteCode;

  // Cost calculations
  double _pricePerStudent = 0.0;
  double _totalAmount = 0.0;

  // Animation controller for price calculation
  late final AnimationController _animationController;
  late Animation<double> _priceAnimation;

  @override
  void initState() {
    super.initState();
    _parsePrice();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _updateTotalAmount(animate: false);
  }

  void _parsePrice() {
    // Extract numbers from price e.g., "₹299" -> 299.0
    // If it's something like "₹149/student", this works fine.
    final numericStr = widget.planPrice.replaceAll(RegExp(r'[^0-9]'), '');
    _pricePerStudent = double.tryParse(numericStr) ?? 149.0;
    if (_pricePerStudent == 0.0) _pricePerStudent = 149.0; // fallback
  }

  void _updateTotalAmount({bool animate = true}) {
    final oldAmount = _totalAmount;
    final newAmount = _studentCount * _pricePerStudent;

    if (animate && oldAmount != newAmount) {
      _priceAnimation = Tween<double>(begin: oldAmount, end: newAmount).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
      );
      _animationController.forward(from: 0.0);
    }
    
    setState(() {
      _totalAmount = newAmount;
    });
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _schoolNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startPaymentSimulation() {
    FocusScope.of(context).unfocus();

    if (_schoolNameController.text.trim().isEmpty) {
      _showSnackbar('Please enter your school name');
      return;
    }

    if (_selectedMethod == 'upi' && _upiIdController.text.trim().isEmpty) {
      _showSnackbar('Please enter a valid UPI ID');
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Initializing secure payment gateway...';
    });

    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _processingMessage = _selectedMethod == 'upi' 
            ? 'Sending payment request to $_selectedUpiApp...' 
            : 'Authorizing card credentials...';
      });
    });

    Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      setState(() {
        _processingMessage = 'Verifying security tokens...';
      });
    });

    Timer(const Duration(milliseconds: 4200), () async {
      if (!mounted) return;
      setState(() {
        _processingMessage = 'Creating your campus workspace...';
      });

      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // Atomic Database Transaction via RPC
          final response = await Supabase.instance.client.rpc(
            'checkout_campus',
            params: {
              'p_school_name': _schoolNameController.text.trim(),
              'p_student_count': _studentCount,
              'p_admin_id': user.id,
            },
          );

          if (response != null && response['success'] == true) {
            _inviteCode = response['invite_code'];
            
            // Sync user profile state
            await DatabaseService.instance.updateUserProfile(
              userId: user.id,
              paymentPlan: 'Campus Plan',
            );

            if (mounted) {
              setState(() {
                _isProcessing = false;
                _isSuccess = true;
              });
            }
          } else {
            throw Exception('Invalid response from server');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error processing campus checkout: $e');
        }
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          _showSnackbar('Payment failed. No charges were made.');
        }
      }
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return Scaffold(
          body: AnimatedBackground(
            isDarkMode: _isDarkMode,
            child: Stack(
              children: [
                Positioned.fill(
                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back_ios_new_rounded, 
                                    color: _isDarkMode ? Colors.white70 : Colors.black87),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Campus Checkout',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: _isDarkMode ? Colors.white : Colors.black87,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          if (!_isSuccess) ...[
                            _buildPlanSummaryCard(),
                            const SizedBox(height: 24),

                            _buildSectionHeader('Campus Details'),
                            const SizedBox(height: 12),
                            _buildGlassContainer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTextField(
                                    controller: _schoolNameController,
                                    label: 'School / Institution Name',
                                    hint: 'e.g. Mrivan Public School',
                                    icon: Icons.school_rounded,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Number of Students',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _isDarkMode ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      _buildCounterButton(Icons.remove, () {
                                        if (_studentCount > 50) {
                                          setState(() => _studentCount -= 50);
                                          _updateTotalAmount();
                                        }
                                      }),
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            activeTrackColor: const Color(0xFF155DFC),
                                            inactiveTrackColor: _isDarkMode ? Colors.white12 : Colors.black12,
                                            thumbColor: const Color(0xFF155DFC),
                                            overlayColor: const Color(0xFF155DFC).withValues(alpha: 0.2),
                                          ),
                                          child: Slider(
                                            value: _studentCount.toDouble(),
                                            min: 50,
                                            max: 2000,
                                            divisions: 39,
                                            onChanged: (val) {
                                              setState(() => _studentCount = val.toInt());
                                              _updateTotalAmount();
                                            },
                                          ),
                                        ),
                                      ),
                                      _buildCounterButton(Icons.add, () {
                                        if (_studentCount < 2000) {
                                          setState(() => _studentCount += 50);
                                          _updateTotalAmount();
                                        }
                                      }),
                                    ],
                                  ),
                                  Center(
                                    child: Text(
                                      '$_studentCount Students',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            _buildSectionHeader('Choose Payment Method'),
                            const SizedBox(height: 12),
                            _buildPaymentMethodsRow(),
                            const SizedBox(height: 24),

                            _buildPaymentDetailsForm(),
                            const SizedBox(height: 32),

                            _buildPayButton(),
                            const SizedBox(height: 24),
                          ] else ...[
                            _buildSuccessView(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isProcessing) _buildProcessingOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _isDarkMode ? Colors.white12 : Colors.black12),
        ),
        child: Icon(icon, color: _isDarkMode ? Colors.white : Colors.black87, size: 20),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: _isDarkMode ? Colors.white70 : Colors.black87,
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isDarkMode
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isDarkMode
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPlanSummaryCard() {
    return _buildGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.planTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_pricePerStudent.toStringAsFixed(0)} / student / month',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF155DFC).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.corporate_fare_rounded, color: Color(0xFF155DFC)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: _isDarkMode ? Colors.white12 : Colors.black12, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payable',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final value = _animationController.isAnimating 
                      ? _priceAnimation.value 
                      : _totalAmount;
                  return Text(
                    '₹${value.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF155DFC),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsRow() {
    return Row(
      children: [
        Expanded(child: _buildMethodTab('upi', Icons.bolt_rounded, 'UPI')),
        const SizedBox(width: 8),
        Expanded(child: _buildMethodTab('card', Icons.credit_card_rounded, 'Card')),
        const SizedBox(width: 8),
        Expanded(child: _buildMethodTab('net_banking', Icons.account_balance_rounded, 'Net Banking')),
      ],
    );
  }

  Widget _buildMethodTab(String method, IconData icon, String label) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF155DFC) 
              : (_isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF155DFC) 
                : (_isDarkMode ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? Colors.white 
                  : (_isDarkMode ? Colors.white70 : Colors.black54),
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? Colors.white 
                    : (_isDarkMode ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsForm() {
    return _buildGlassContainer(
      child: AnimatedCrossFade(
        firstChild: _buildUpiForm(),
        secondChild: _selectedMethod == 'card' ? _buildCardForm() : _buildNetBankingForm(),
        crossFadeState: _selectedMethod == 'upi' 
            ? CrossFadeState.showFirst 
            : CrossFadeState.showSecond,
        duration: const Duration(milliseconds: 250),
      ),
    );
  }

  Widget _buildUpiForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select UPI App',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['Google Pay', 'PhonePe', 'Paytm', 'BHIM'].map((app) {
            final isAppSelected = _selectedUpiApp == app;
            return GestureDetector(
              onTap: () => setState(() => _selectedUpiApp = app),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isAppSelected 
                      ? const Color(0xFF155DFC).withValues(alpha: 0.15) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isAppSelected 
                        ? const Color(0xFF155DFC) 
                        : (_isDarkMode ? Colors.white10 : Colors.black12),
                    width: 1,
                  ),
                ),
                child: Text(
                  app,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isAppSelected ? FontWeight.bold : FontWeight.normal,
                    color: isAppSelected 
                        ? const Color(0xFF155DFC) 
                        : (_isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _upiIdController,
          label: 'Enter UPI ID',
          hint: 'e.g. user@okaxis',
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _cardHolderController,
          label: 'Cardholder Name',
          hint: 'Full name on card',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _cardNumberController,
          label: 'Card Number',
          hint: '0000 0000 0000 0000',
          icon: Icons.credit_card_rounded,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildNetBankingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Bank',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: 2.8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          physics: const NeverScrollableScrollPhysics(),
          children: ['SBI', 'HDFC', 'ICICI', 'Axis', 'Kotak', 'PNB'].map((bank) {
            final isBankSelected = _selectedBank == bank;
            return GestureDetector(
              onTap: () => setState(() => _selectedBank = bank),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isBankSelected 
                      ? const Color(0xFF155DFC).withValues(alpha: 0.15) 
                      : (_isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isBankSelected 
                        ? const Color(0xFF155DFC) 
                        : (_isDarkMode ? Colors.white10 : Colors.black12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_rounded,
                      size: 16,
                      color: isBankSelected 
                          ? const Color(0xFF155DFC) 
                          : (_isDarkMode ? Colors.white54 : Colors.black54),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      bank,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isBankSelected ? FontWeight.bold : FontWeight.normal,
                        color: isBankSelected 
                            ? const Color(0xFF155DFC) 
                            : (_isDarkMode ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _isDarkMode ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _isDarkMode ? Colors.white30 : Colors.black38, fontSize: 13),
            prefixIcon: Icon(icon, color: _isDarkMode ? Colors.white30 : Colors.black38, size: 18),
            filled: true,
            fillColor: _isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _isDarkMode ? Colors.white10 : Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF155DFC), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final value = _animationController.isAnimating 
            ? _priceAnimation.value 
            : _totalAmount;
        return Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF155DFC).withValues(alpha: 0.35),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _startPaymentSimulation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF155DFC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Pay ₹${value.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF155DFC)),
                ),
                const SizedBox(height: 24),
                Text(
                  _processingMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please do not press back or refresh the page',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: _buildGlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.green[500]!.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green[400]!, width: 2),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.green[400],
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Campus Created Successfully!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your invite code with teachers and students.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _isDarkMode ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _isDarkMode ? Colors.white12 : Colors.black12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Campus Invite Code',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _inviteCode ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 32,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF155DFC),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _inviteCode ?? ''));
                      _showSnackbar('Code copied to clipboard');
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDarkMode ? Colors.white10 : Colors.black12,
                      foregroundColor: _isDarkMode ? Colors.white : Colors.black87,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to dashboard
                  Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF155DFC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Go to Campus Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
