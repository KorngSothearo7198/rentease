import 'package:flutter/material.dart';

class RenterPaymentScreen extends StatefulWidget {
  const RenterPaymentScreen({super.key});

  @override
  State<RenterPaymentScreen> createState() => _RenterPaymentScreenState();
}

class _RenterPaymentScreenState extends State<RenterPaymentScreen> {
  final TextEditingController _promoController = TextEditingController();

  // Selection States
  String _selectedPaymentMethod = 'Cash'; // Default selected matching screenshot
  bool _isTermsAgreed = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _onApplyPromo() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Promo code applied!')),
    );
  }

  void _onPayNow() {
    if (!_isTermsAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the payment terms to proceed.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Process Payment Logic Here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processing payment via $_selectedPaymentMethod...'),
        backgroundColor: const Color(0xFF5338F5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FD), // Light lavender background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF14142B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(
            color: Color(0xFF14142B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF14142B)),
            onPressed: () {
              // Help action
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------------------
            // 1. PROPERTY SUMMARY CARD
            // -----------------------------------------------------------------
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property Image with Approved Badge
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267',
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FADF), // Light green
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Approved',
                              style: TextStyle(
                                color: Color(0xFF027A48),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Property Details
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'APARTMENT',
                        style: TextStyle(
                          color: Color(0xFF5338F5),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'Modern Studio Apartment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14142B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Location Row
                    _buildInfoRow(Icons.location_on_outlined, 'Phnom Penh, Cambodia'),
                    const SizedBox(height: 6),

                    // Date & Duration Row
                    _buildInfoRow(Icons.calendar_today_outlined, '01 Aug 2026 - 31 Aug 2026 (1 Month)'),
                    const SizedBox(height: 6),

                    // Owner Row
                    _buildInfoRow(Icons.person_outline, 'Owner: Sothea Chan'),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // -----------------------------------------------------------------
            // 2. PAYMENT SUMMARY CARD
            // -----------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF14142B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPriceRow('Monthly Rent', '\$250.00'),
                  const SizedBox(height: 12),
                  _buildPriceRow('Service Fee', '\$10.00'),
                  const SizedBox(height: 12),
                  _buildPriceRow('Security Deposit', '\$100.00'),
                  const SizedBox(height: 12),
                  _buildPriceRow('Discount', '-\$10.00', isDiscount: true),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14142B),
                        ),
                      ),
                      Text(
                        '\$350.00',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5338F5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // 3. PROMO CODE INPUT
            // -----------------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: _promoController,
                      decoration: InputDecoration(
                        hintText: 'Enter Promo Code',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 50,
                  width: 100,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5338F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _onApplyPromo,
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // 4. CHOOSE PAYMENT METHOD
            // -----------------------------------------------------------------
            const Text(
              'Choose Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF14142B),
              ),
            ),
            const SizedBox(height: 12),

            _buildPaymentTile(
              id: 'ABA',
              title: 'ABA Bank',
              subtitle: 'Pay using ABA Mobile',
              iconWidget: const Icon(Icons.account_balance, color: Color(0xFF5338F5)),
            ),
            const SizedBox(height: 10),

            _buildPaymentTile(
              id: 'Visa',
              title: 'Visa Card',
              subtitle: '**** **** **** 4821',
              iconWidget: const Icon(Icons.credit_card, color: Color(0xFF1A1F71)),
            ),
            const SizedBox(height: 10),

            _buildPaymentTile(
              id: 'Mastercard',
              title: 'Mastercard',
              subtitle: '**** **** **** 2356',
              iconWidget: const Icon(Icons.payment, color: Colors.orange),
            ),
            const SizedBox(height: 10),

            _buildPaymentTile(
              id: 'Cash',
              title: 'Cash',
              subtitle: 'Pay when meeting the owner',
              iconWidget: const Icon(Icons.payments_outlined, color: Color(0xFF5338F5)),
            ),
            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // 5. STATUS & BOOKING META CARD
            // -----------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F2FE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetaColumn('STATUS', 'Pending', isBold: true),
                      _buildMetaColumn('BOOKING ID', 'BK-2026-000125', isBold: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildMetaColumn('DATE', 'Today', isBold: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // 6. TERMS AGREEMENT CHECKBOX
            // -----------------------------------------------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _isTermsAgreed,
                    activeColor: const Color(0xFF5338F5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _isTermsAgreed = val ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'I agree to the payment terms and rental agreement. I understand that the security deposit is refundable upon move-out inspection.',
                    style: TextStyle(
                      color: Color(0xFF4A4A6A),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // 7. PAY NOW BUTTON
            // -----------------------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5338F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _onPayNow,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String title, String amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDiscount ? const Color(0xFF027A48) : Colors.grey[700],
            fontSize: 14,
            fontWeight: isDiscount ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: isDiscount ? const Color(0xFF027A48) : const Color(0xFF14142B),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTile({
    required String id,
    required String title,
    required String subtitle,
    required Widget iconWidget,
  }) {
    final isSelected = _selectedPaymentMethod == id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = id;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3F2FE) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF5338F5) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F2FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: iconWidget,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF14142B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Custom Radio Circle Indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF5338F5) : Colors.grey[300]!,
                  width: isSelected ? 6 : 2,
                ),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaColumn(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF14142B),
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}