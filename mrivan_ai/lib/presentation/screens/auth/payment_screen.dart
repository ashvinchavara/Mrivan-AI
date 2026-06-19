import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/database_service.dart';
import '../../widgets/animated_background.dart';
import '../../theme/theme_config.dart';
import '../dashboard/app_router.dart';

class PaymentScreen extends StatefulWidget {
  final String planTitle;
  final String planPrice;
  final String planSubtitle;

  const PaymentScreen({
    super.key,
    required this.planTitle,
    required this.planPrice,
    required this.planSubtitle,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
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

  // Campus variables
  late final TextEditingController _schoolNameController;
  late final TextEditingController _studentsController;
  late final TextEditingController _teachersController;
  String? _inviteCode;

  // Transaction simulation states
  bool _isProcessing = false;
  String _processingMessage = '';
  bool _isSuccess = false;

  // Cost calculations
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _schoolNameController = TextEditingController(text: AppRouter.schoolName ?? '');
    _studentsController = TextEditingController(text: AppRouter.studentCount?.toString() ?? '100');
    _teachersController = TextEditingController(text: AppRouter.teacherCount?.toString() ?? '10');
    _parsePrice();
  }

  void _parsePrice() {
    if (widget.planTitle == 'Campus Plan') {
      final studentCount = int.tryParse(_studentsController.text.trim()) ?? 100;
      setState(() {
        _totalAmount = studentCount * 149.0;
      });
    } else {
      final numericStr = widget.planPrice.replaceAll(RegExp(r'[^0-9]'), '');
      final parsed = double.tryParse(numericStr) ?? 0.0;
      setState(() {
        _totalAmount = parsed;
      });
    }
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _schoolNameController.dispose();
    _studentsController.dispose();
    _teachersController.dispose();
    super.dispose();
  }

  // Simulates the transaction progress
  void _startPaymentSimulation() {
    FocusScope.of(context).unfocus();

    // Basic Validation
    if (widget.planTitle == 'Campus Plan') {
      if (_schoolNameController.text.trim().isEmpty) {
        _showSnackbar('Please enter school name');
        return;
      }
      final studentCount = int.tryParse(_studentsController.text.trim());
      if (studentCount == null || studentCount < 50) {
        _showSnackbar('Number of students must be at least 50');
        return;
      }
      final teacherCount = int.tryParse(_teachersController.text.trim());
      if (teacherCount == null || teacherCount <= 0) {
        _showSnackbar('Number of teachers must be at least 1');
        return;
      }
    }

    if (_selectedMethod == 'upi' && _upiIdController.text.trim().isEmpty) {
      _showSnackbar('Please enter a valid UPI ID');
      return;
    }
    if (_selectedMethod == 'card') {
      if (_cardNumberController.text.length < 19) {
        _showSnackbar('Please enter a valid 16-digit card number');
        return;
      }
      if (_cardExpiryController.text.length < 5) {
        _showSnackbar('Please enter card expiry date (MM/YY)');
        return;
      }
      if (_cardCvvController.text.length < 3) {
        _showSnackbar('Please enter CVV');
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Initializing secure payment gateway...';
    });

    // Cycle messages to simulate bank interaction
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
        _processingMessage = 'Verifying security tokens with issuing bank...';
      });
    });

    Timer(const Duration(milliseconds: 4200), () {
      if (!mounted) return;
      setState(() {
        _processingMessage = 'Finalizing transaction records...';
      });
    });

    Timer(const Duration(milliseconds: 5500), () async {
      if (!mounted) return;
      setState(() {
        _processingMessage = widget.planTitle == 'Campus Plan'
            ? 'Creating your campus workspace...'
            : 'Activating your subscription plan...';
      });

      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          if (widget.planTitle == 'Campus Plan') {
            final response = await Supabase.instance.client.rpc(
              'checkout_campus',
              params: {
                'p_school_name': _schoolNameController.text.trim(),
                'p_student_count': int.tryParse(_studentsController.text.trim()) ?? 100,
                'p_teacher_count': AppRouter.teacherCount ?? 10,
                'p_admin_id': user.id,
              },
            );

            if (response != null && response['success'] == true) {
              _inviteCode = response['invite_code'];
            } else {
              throw Exception(response?['message'] ?? 'Failed to create campus');
            }
          }

          await DatabaseService.instance.updateUserProfile(
            userId: user.id,
            paymentPlan: widget.planTitle,
            email: user.email,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error processing payment: $e');
        }
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          _showSnackbar(e.toString().replaceAll('Exception: ', ''));
          return;
        }
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });
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
            // Main Scrollable Area
            Positioned.fill(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Navigation Row
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios_new_rounded, 
                                color: _isDarkMode ? Colors.white70 : Colors.black87),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Checkout',
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
                        // 1. Plan Details and Pricing Breakdown
                        _buildPlanSummaryCard(),
                        const SizedBox(height: 24),

                        if (widget.planTitle == 'Campus Plan') ...[
                          _buildCampusDetailsCard(),
                          const SizedBox(height: 24),
                        ],

                        // 2. Select Payment Method
                        _buildSectionHeader('Choose Payment Method'),
                        const SizedBox(height: 12),
                        _buildPaymentMethodsRow(),
                        const SizedBox(height: 24),

                        // 3. Conditional Payment Form Details
                        _buildPaymentDetailsForm(),
                        const SizedBox(height: 32),

                        // 4. Pay Button
                        _buildPayButton(),
                        const SizedBox(height: 12),
                        _buildPayLaterButton(),
                        const SizedBox(height: 24),
                      ] else ...[
                        // Success View
                        _buildSuccessView(),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Fullscreen Processing Overlay
            if (_isProcessing) _buildProcessingOverlay(),
            ],
          ),
        ),
      );
      },
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

  Widget _buildGlassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
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
    final isCampus = widget.planTitle == 'Campus Plan';

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
                    isCampus ? '₹149 / student / month' : widget.planSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF155DFC).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCampus ? '₹149/stud' : widget.planPrice,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF155DFC),
                  ),
                ),
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
              Text(
                '₹${_totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF155DFC),
                ),
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
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            CardNumberInputFormatter(),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _cardExpiryController,
                label: 'Expiry Date',
                hint: 'MM/YY',
                icon: Icons.calendar_today_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  CardExpiryInputFormatter(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _cardCvvController,
                label: 'CVV',
                hint: '123',
                icon: Icons.lock_outline_rounded,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
            ),
          ],
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
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
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
          inputFormatters: inputFormatters,
          onChanged: onChanged,
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
          'Pay ₹${_totalAmount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPayLaterButton() {
    return Center(
      child: TextButton(
        onPressed: () {
          // Return to root widget (AppRouter) without payment
          AppRouter.notifyProfileUpdated();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Text(
          'Pay Later',
          style: TextStyle(
            color: _isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
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

  Widget _buildCampusDetailsCard() {
    final hasSchoolName = _schoolNameController.text.trim().isNotEmpty;
    
    if (hasSchoolName) {
      return _buildCampusDetailsSummary();
    } else {
      return _buildCampusDetailsFormFields();
    }
  }

  Widget _buildCampusDetailsSummary() {
    final schoolName = _schoolNameController.text.trim();
    final students = _studentsController.text.trim();
    final teachers = _teachersController.text.trim();

    return _buildGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business_rounded, color: Color(0xFF155DFC), size: 22),
              const SizedBox(width: 8),
              Text(
                'Campus Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildReceiptRow('Institution Name', schoolName.isNotEmpty ? schoolName : 'Not Provided'),
          const SizedBox(height: 10),
          _buildReceiptRow('Students Count', '$students students (₹149/student)'),
          const SizedBox(height: 10),
          _buildReceiptRow('Teachers Count', '$teachers teachers'),
        ],
      ),
    );
  }

  Widget _buildCampusDetailsFormFields() {
    return _buildGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business_rounded, color: Color(0xFF155DFC), size: 22),
              const SizedBox(width: 8),
              Text(
                'Campus Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _schoolNameController,
            label: 'School / Institution Name',
            hint: 'e.g. Mrivan Public School',
            icon: Icons.school_rounded,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _studentsController,
                  label: 'Number of Students',
                  hint: 'Min 50',
                  icon: Icons.people_rounded,
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    _parsePrice();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _teachersController,
                  label: 'Number of Teachers',
                  hint: 'Min 1',
                  icon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final isCampus = widget.planTitle == 'Campus Plan';

    return Center(
      child: _buildGlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          children: [
            // Success Icon Animation
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
              isCampus ? 'Campus Created Successfully!' : 'Payment Successful!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCampus 
                  ? 'Share your invite code with teachers and students.'
                  : 'Your subscription is now active',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _isDarkMode ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 28),

            if (isCampus) ...[
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied to clipboard'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
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
            ] else ...[
              // Receipt Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow('Transaction ID', 'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}'),
                    const SizedBox(height: 10),
                    _buildReceiptRow('Date & Time', DateTime.now().toLocal().toString().substring(0, 19)),
                    const SizedBox(height: 10),
                    _buildReceiptRow('Payment Mode', _selectedMethod == 'upi' 
                        ? 'UPI ($_selectedUpiApp)' 
                        : (_selectedMethod == 'card' ? 'Debit/Credit Card' : 'Net Banking ($_selectedBank)')),
                    const SizedBox(height: 10),
                    _buildReceiptRow('Amount Paid', '₹${_totalAmount.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Continue Button
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF155DFC).withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  // Pop all routes to return to the root widget
                  AppRouter.notifyProfileUpdated();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF155DFC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isCampus ? 'Go to Campus Dashboard' : 'Activate & Get Started',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _isDarkMode ? Colors.white30 : Colors.black38,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }
}

// Formatters for inputs
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}

class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}
