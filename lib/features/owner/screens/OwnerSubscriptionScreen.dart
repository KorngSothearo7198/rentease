// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:khqr_sdk/khqr_sdk.dart';
//
// import '../../../models/subscription_model.dart';
// import '../../../models/subscription_plan_model.dart';
// import '../../../services/session_service.dart';
// import '../../../services/subscription_plans_services.dart';
// import '../../../services/subscription_service.dart';
//
// class OwnerSubscriptionScreen extends StatefulWidget {
//   const OwnerSubscriptionScreen({super.key});
//
//   @override
//   State<OwnerSubscriptionScreen> createState() =>
//       _OwnerSubscriptionScreenState();
// }
//
// class _OwnerSubscriptionScreenState extends State<OwnerSubscriptionScreen> {
//   final SubscriptionService _subscriptionService = SubscriptionService();
//
//   final SubscriptionPlansService _plansService = SubscriptionPlansService();
//
//   String? _ownerId;
//
//   bool _isLoadingUser = true;
//
//   int _selectedPlanIndex = 0;
//
//   static const Color primaryColor = Color(0xFF4F46E5);
//
//   static const Color backgroundColor = Color(0xFFF8FAFC);
//
//   static const Color cardColor = Colors.white;
//
//   static const Color textColor = Color(0xFF0F172A);
//
//   static const Color secondaryTextColor = Color(0xFF64748B);
//
//   static const Color borderColor = Color(0xFFE2E8F0);
//
//   // ==========================================================
//   // REAL BAKONG CONFIGURATION
//   // ==========================================================
//
//   static const String bakongReceiver = 'thearith_panha@bkrt';
//
//   // Test payment amount.
//   // The subscription price remains USD.
//   static const double testPaymentAmount = 100.0;
//
//   static const String testPaymentCurrency = 'KHR';
//
//   // Display name in KHQR.
//   static const String merchantName = 'RentEase';
//
//   // This is used by the KHQR SDK.
//   // Keep it short and valid for KHQR.
//   static const String merchantCity = 'Phnom Penh';
//
//   // ==========================================================
//   // KHQR STATE
//   // ==========================================================
//
//   String? _khqrCode;
//
//   String? _khqrMd5;
//
//   bool _isGeneratingQr = false;
//
//   String? _qrError;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _loadUserSession();
//   }
//
//   // ==========================================================
//   // LOAD USER
//   // ==========================================================
//
//   Future<void> _loadUserSession() async {
//     try {
//       final user = await SessionService.getUser();
//
//       if (!mounted) return;
//
//       if (user != null) {
//         setState(() {
//           _ownerId = user['uid']?.toString();
//
//           _isLoadingUser = false;
//         });
//       } else {
//         setState(() {
//           _isLoadingUser = false;
//         });
//       }
//     } catch (e) {
//       if (!mounted) return;
//
//       setState(() {
//         _isLoadingUser = false;
//       });
//     }
//   }
//
//   // ==========================================================
//   // GENERATE REAL KHQR
//   // ==========================================================
//
//   Future<void> _generateKhqr() async {
//     if (_isGeneratingQr) return;
//
//     if (!mounted) return;
//
//     setState(() {
//       _isGeneratingQr = true;
//       _qrError = null;
//       _khqrCode = null;
//       _khqrMd5 = null;
//     });
//
//     try {
//       // Dynamic KHQR should have an expiration time.
//       final expirationTimestamp = DateTime.now()
//           .add(const Duration(minutes: 10))
//           .millisecondsSinceEpoch;
//
//       final info = IndividualInfo(
//         bakongAccountId: bakongReceiver,
//         merchantName: merchantName,
//
//         // Keep this as a real account-information value.
//         // If your Bakong account does not use a separate
//         // account information value, use the account ID.
//         accountInformation: bakongReceiver,
//
//         currency: KhqrCurrency.khr,
//         amount: testPaymentAmount,
//
//         // Dynamic QR expiration.
//         expirationTimestamp: expirationTimestamp,
//       );
//
//       final result = KhqrSdk.generateIndividual(info);
//
//       if (!result.isSuccess || result.data == null) {
//         throw Exception(result.status.message ?? 'Unable to generate KHQR.');
//       }
//
//       final qr = result.data!.qr.trim();
//
//       if (qr.isEmpty) {
//         throw Exception('KHQR content is empty.');
//       }
//
//       final md5 = result.data!.md5Hash.trim();
//
//       if (md5.isEmpty) {
//         throw Exception('KHQR MD5 is empty.');
//       }
//
//       debugPrint('======================================');
//       debugPrint('KHQR GENERATED');
//       debugPrint('Receiver: $bakongReceiver');
//       debugPrint('Amount: $testPaymentAmount $testPaymentCurrency');
//       debugPrint('MD5: $md5');
//       debugPrint('QR: $qr');
//       debugPrint('======================================');
//
//       if (!mounted) return;
//
//       setState(() {
//         _khqrCode = qr;
//         _khqrMd5 = md5;
//         _isGeneratingQr = false;
//       });
//     } catch (e, stackTrace) {
//       debugPrint('KHQR GENERATION ERROR: $e');
//       debugPrintStack(stackTrace: stackTrace);
//
//       if (!mounted) return;
//
//       setState(() {
//         _isGeneratingQr = false;
//         _qrError = e.toString();
//       });
//     }
//   }
//
//   // ==========================================================
//   // BUILD
//   // ==========================================================
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: backgroundColor,
//         foregroundColor: textColor,
//         title: const Text(
//           'Subscription Plan',
//           style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
//         ),
//       ),
//       body: _buildBody(),
//     );
//   }
//
//   // ==========================================================
//   // BODY
//   // ==========================================================
//
//   Widget _buildBody() {
//     if (_isLoadingUser) {
//       return const Center(
//         child: CircularProgressIndicator(color: primaryColor),
//       );
//     }
//
//     if (_ownerId == null) {
//       return const Center(
//         child: Text(
//           'Please log in to view subscriptions.',
//           style: TextStyle(color: secondaryTextColor, fontSize: 15),
//         ),
//       );
//     }
//
//     return StreamBuilder<List<SubscriptionModel>>(
//       stream: _subscriptionService.ownerSubscriptions(_ownerId!),
//       builder: (context, subscriptionSnapshot) {
//         if (subscriptionSnapshot.connectionState == ConnectionState.waiting) {
//           return const Center(
//             child: CircularProgressIndicator(color: primaryColor),
//           );
//         }
//
//         if (subscriptionSnapshot.hasError) {
//           return Center(
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Text(
//                 'Unable to load subscriptions.\n'
//                 '${subscriptionSnapshot.error}',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(color: secondaryTextColor),
//               ),
//             ),
//           );
//         }
//
//         final subscriptions = subscriptionSnapshot.data ?? [];
//
//         SubscriptionModel? activeSub;
//         SubscriptionModel? pendingSub;
//
//         for (final sub in subscriptions) {
//           final status = sub.status.toLowerCase().trim();
//
//           if (status == 'active' || status == 'approved') {
//             activeSub = sub;
//             break;
//           }
//
//           if (status == 'pending') {
//             pendingSub = sub;
//           }
//         }
//
//         return StreamBuilder<List<SubscriptionPlanModel>>(
//           stream: _plansService.subscriptionPlans(),
//           builder: (context, planSnapshot) {
//             if (planSnapshot.connectionState == ConnectionState.waiting) {
//               return const Center(
//                 child: CircularProgressIndicator(color: primaryColor),
//               );
//             }
//
//             if (planSnapshot.hasError) {
//               return Center(
//                 child: Padding(
//                   padding: const EdgeInsets.all(24),
//                   child: Text(
//                     'Unable to load plans.\n'
//                     '${planSnapshot.error}',
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(color: secondaryTextColor),
//                   ),
//                 ),
//               );
//             }
//
//             final plans = planSnapshot.data ?? [];
//
//             if (plans.isEmpty) {
//               return const Center(
//                 child: Text(
//                   'No subscription plans available.',
//                   style: TextStyle(color: secondaryTextColor),
//                 ),
//               );
//             }
//
//             if (_selectedPlanIndex >= plans.length) {
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 if (!mounted) return;
//
//                 setState(() {
//                   _selectedPlanIndex = 0;
//                 });
//               });
//             }
//
//             final selectedIndex = _selectedPlanIndex < plans.length
//                 ? _selectedPlanIndex
//                 : 0;
//
//             return _buildSubscriptionContent(
//               activeSub: activeSub,
//               pendingSub: pendingSub,
//               plans: plans,
//               selectedIndex: selectedIndex,
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Future<bool> _checkSubscriptionPayment({
//     required SubscriptionPlanModel plan,
//     required String khqrMd5,
//   }) async {
//     if (_ownerId == null) {
//       return false;
//     }
//
//     try {
//       debugPrint('Checking subscription payment...');
//
//       debugPrint('MD5: $khqrMd5');
//
//       final hasPending = await _subscriptionService.hasPendingSubscription(
//         _ownerId!,
//       );
//
//       if (hasPending) {
//         debugPrint('Subscription already pending.');
//
//         return false;
//       }
//
//       final paymentReference = 'SUB-${DateTime.now().millisecondsSinceEpoch}';
//
//       final result = await _subscriptionService.completeSubscriptionPayment(
//         ownerId: _ownerId!,
//         planId: plan.id,
//         planName: plan.name,
//         amount: plan.price,
//         bakongMd5: khqrMd5,
//         paymentReference: paymentReference,
//       );
//
//       if (result['success'] != true) {
//         debugPrint('Payment not detected yet.');
//
//         return false;
//       }
//
//       debugPrint('========================================');
//
//       debugPrint('SUBSCRIPTION PAYMENT SUCCESS');
//
//       debugPrint(
//         'Subscription ID: '
//         '${result['subscriptionId'] ?? ''}',
//       );
//
//       debugPrint('Payment Status: paid');
//
//       debugPrint('Subscription Status: pending');
//
//       debugPrint('========================================');
//
//       if (!mounted) {
//         return true;
//       }
//
//       /*
//      * Show success dialog after the bottom sheet
//      * is closed.
//      */
//       WidgetsBinding.instance.addPostFrameCallback((_) async {
//         if (!mounted) return;
//
//         await showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder: (context) {
//             return const _SubscriptionSubmittedDialog();
//           },
//         );
//       });
//
//       return true;
//     } catch (e) {
//       debugPrint('Payment check error: $e');
//
//       /*
//      * Important:
//      *
//      * A failed check does NOT mean payment failed.
//      *
//      * It usually means the transaction has not
//      * appeared in Bakong yet.
//      *
//      * Therefore we return false and let the
//      * timer check again.
//      */
//       return false;
//     }
//   }
//
//   // ==========================================================
//   // SUBSCRIPTION CONTENT
//   // ==========================================================
//
//   Widget _buildSubscriptionContent({
//     SubscriptionModel? activeSub,
//     SubscriptionModel? pendingSub,
//     required List<SubscriptionPlanModel> plans,
//     required int selectedIndex,
//   }) {
//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (activeSub != null) ...[
//             _buildActiveStatusCard(activeSub),
//             const SizedBox(height: 24),
//           ] else if (pendingSub != null) ...[
//             _buildPendingStatusCard(pendingSub),
//             const SizedBox(height: 24),
//           ],
//           const Text(
//             'Choose Your Plan',
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.w800,
//               color: textColor,
//             ),
//           ),
//           const SizedBox(height: 6),
//           const Text(
//             'Unlock full property management tools for your account.',
//             style: TextStyle(fontSize: 14, color: secondaryTextColor),
//           ),
//           const SizedBox(height: 20),
//           _buildPlansList(plans),
//           const SizedBox(height: 28),
//           _buildSubscribeButton(
//             pendingSub: pendingSub,
//             plans: plans,
//             selectedIndex: selectedIndex,
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==========================================================
//   // PLANS LIST
//   // ==========================================================
//
//   Widget _buildPlansList(List<SubscriptionPlanModel> plans) {
//     return ListView.separated(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: plans.length,
//       separatorBuilder: (_, __) => const SizedBox(height: 14),
//       itemBuilder: (context, index) {
//         final plan = plans[index];
//
//         return _buildPlanCard(
//           plan: plan,
//           isSelected: _selectedPlanIndex == index,
//           onSelect: () {
//             setState(() {
//               _selectedPlanIndex = index;
//             });
//           },
//         );
//       },
//     );
//   }
//
//   // ==========================================================
//   // SUBSCRIBE BUTTON
//   // ==========================================================
//
//   Widget _buildSubscribeButton({
//     required SubscriptionModel? pendingSub,
//     required List<SubscriptionPlanModel> plans,
//     required int selectedIndex,
//   }) {
//     final selectedPlan = plans[selectedIndex];
//
//     return SizedBox(
//       width: double.infinity,
//       height: 56,
//       child: ElevatedButton(
//         onPressed: pendingSub != null
//             ? null
//             : () => _openCheckoutModal(selectedPlan),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: primaryColor,
//           disabledBackgroundColor: primaryColor.withOpacity(0.4),
//           elevation: 0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//         ),
//         child: Text(
//           pendingSub != null ? 'Approval Pending' : 'Subscribe Now',
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w700,
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ==========================================================
//   // ACTIVE CARD
//   // ==========================================================
//
//   Widget _buildActiveStatusCard(SubscriptionModel sub) {
//     final expiryFormatted = sub.endDate != null
//         ? DateFormat('MMM dd, yyyy').format(sub.endDate!)
//         : 'N/A';
//
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF10B981), Color(0xFF059669)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF10B981).withOpacity(0.3),
//             blurRadius: 16,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 5,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: const Row(
//                   children: [
//                     Icon(Icons.check_circle, color: Colors.white, size: 14),
//                     SizedBox(width: 5),
//                     Text(
//                       'ACTIVE',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 11,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Text(
//                 '\$${sub.amount.toStringAsFixed(0)}',
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w800,
//                   fontSize: 20,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 14),
//           Text(
//             sub.planName,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 22,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Valid through $expiryFormatted',
//             style: const TextStyle(color: Colors.white70, fontSize: 13),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==========================================================
//   // PENDING CARD
//   // ==========================================================
//
//   Widget _buildPendingStatusCard(SubscriptionModel sub) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: const Color(0xFFFFFBEB),
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: const Color(0xFFFCD34D)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color: const Color(0xFFF59E0B).withOpacity(0.15),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.hourglass_top_rounded,
//               color: Color(0xFFD97706),
//               size: 22,
//             ),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Approval Pending',
//                   style: TextStyle(
//                     color: Color(0xFF92400E),
//                     fontWeight: FontWeight.w700,
//                     fontSize: 15,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   'Your request for ${sub.planName} is under review.',
//                   style: const TextStyle(
//                     color: Color(0xFFB45309),
//                     fontSize: 13,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==========================================================
//   // PLAN CARD
//   // ==========================================================
//
//   Widget _buildPlanCard({
//     required SubscriptionPlanModel plan,
//     required bool isSelected,
//     required VoidCallback onSelect,
//   }) {
//     final bool isPopular = plan.popular;
//
//     final bool isRecommended = plan.recommended;
//
//     return GestureDetector(
//       onTap: onSelect,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 220),
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: cardColor,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: isSelected ? primaryColor : borderColor,
//             width: isSelected ? 2.2 : 1,
//           ),
//           boxShadow: [
//             if (isSelected)
//               BoxShadow(
//                 color: primaryColor.withOpacity(0.15),
//                 blurRadius: 16,
//                 offset: const Offset(0, 6),
//               )
//             else
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.03),
//                 blurRadius: 10,
//                 offset: const Offset(0, 3),
//               ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     plan.name,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       fontSize: 17,
//                       fontWeight: FontWeight.w800,
//                       color: textColor,
//                     ),
//                   ),
//                 ),
//                 AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   width: 24,
//                   height: 24,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: isSelected ? primaryColor : Colors.transparent,
//                     border: Border.all(
//                       color: isSelected ? primaryColor : borderColor,
//                       width: 2,
//                     ),
//                   ),
//                   child: isSelected
//                       ? const Icon(Icons.check, size: 14, color: Colors.white)
//                       : null,
//                 ),
//               ],
//             ),
//             if (isPopular || isRecommended) ...[
//               const SizedBox(height: 10),
//               Wrap(
//                 spacing: 6,
//                 runSpacing: 6,
//                 children: [
//                   if (isPopular)
//                     _buildPlanBadge(text: 'POPULAR', color: primaryColor),
//                   if (isRecommended)
//                     _buildPlanBadge(text: 'RECOMMENDED', color: Colors.green),
//                 ],
//               ),
//             ],
//             const SizedBox(height: 12),
//             Text(
//               plan.description,
//               style: const TextStyle(fontSize: 13, color: secondaryTextColor),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text(
//                   '${plan.currency == 'USD' ? '\$' : plan.currency}${plan.price.toStringAsFixed(0)}',
//                   style: const TextStyle(
//                     fontSize: 30,
//                     fontWeight: FontWeight.w800,
//                     color: textColor,
//                   ),
//                 ),
//                 const SizedBox(width: 4),
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 5),
//                   child: Text(
//                     '/ ${plan.billing}',
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: secondaryTextColor,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const Padding(
//               padding: EdgeInsets.symmetric(vertical: 14),
//               child: Divider(color: borderColor, height: 1),
//             ),
//             Row(
//               children: [
//                 const Icon(
//                   Icons.home_work_rounded,
//                   color: primaryColor,
//                   size: 17,
//                 ),
//                 const SizedBox(width: 10),
//                 Text(
//                   plan.propertyLimit >= 999999
//                       ? 'Unlimited Properties'
//                       : 'Up to ${plan.propertyLimit} Properties',
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: secondaryTextColor,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//             if (plan.features.isNotEmpty) ...[
//               const SizedBox(height: 10),
//               ...plan.features.map((feature) {
//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 8),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Icon(
//                         Icons.check_circle_rounded,
//                         color: primaryColor,
//                         size: 17,
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: Text(
//                           feature,
//                           style: const TextStyle(
//                             fontSize: 14,
//                             color: secondaryTextColor,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ==========================================================
//   // BADGE
//   // ==========================================================
//
//   Widget _buildPlanBadge({required String text, required Color color}) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.12),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           color: color,
//           fontSize: 9,
//           fontWeight: FontWeight.w800,
//         ),
//       ),
//     );
//   }
//
//   // ==========================================================
//   // CHECKOUT MODAL
//   // ==========================================================
//
//   Future<void> _openCheckoutModal(SubscriptionPlanModel plan) async {
//     final hasPending = _ownerId == null
//         ? false
//         : await _subscriptionService.hasPendingSubscription(_ownerId!);
//
//     if (!mounted) return;
//
//     if (hasPending) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('You already have a pending subscription.'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//
//       return;
//     }
//
//     _khqrCode = null;
//     _khqrMd5 = null;
//     _qrError = null;
//
//     await _generateKhqr();
//
//     if (!mounted) return;
//
//     if (_khqrCode == null || _khqrMd5 == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(_qrError ?? 'Unable to generate KHQR.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//
//       return;
//     }
//
//     bool isCheckingPayment = false;
//     bool paymentCompleted = false;
//
//     Timer? paymentTimer;
//
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       isDismissible: true,
//       enableDrag: true,
//       builder: (modalContext) {
//         return StatefulBuilder(
//           builder: (context, setModalState) {
//             Future<void> startAutoPaymentCheck() async {
//               if (isCheckingPayment || paymentCompleted) {
//                 return;
//               }
//
//               final md5 = _khqrMd5;
//
//               if (md5 == null || md5.isEmpty) {
//                 setModalState(() {
//                   isCheckingPayment = false;
//                 });
//
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('KHQR payment information is missing.'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//
//                 return;
//               }
//
//               setModalState(() {
//                 isCheckingPayment = true;
//               });
//
//               /*
//              * Check immediately first.
//              */
//               final firstResult = await _checkSubscriptionPayment(
//                 plan: plan,
//                 khqrMd5: md5,
//               );
//
//               if (firstResult) {
//                 paymentCompleted = true;
//
//                 if (!context.mounted) return;
//
//                 paymentTimer?.cancel();
//
//                 Navigator.of(context).pop();
//
//                 return;
//               }
//
//               /*
//              * Then automatically check every 2 seconds.
//              */
//               int attempts = 0;
//
//               paymentTimer = Timer.periodic(const Duration(seconds: 1), (
//                 timer,
//               ) async {
//                 if (!context.mounted) {
//                   timer.cancel();
//                   return;
//                 }
//
//                 if (paymentCompleted) {
//                   timer.cancel();
//                   return;
//                 }
//
//                 attempts++;
//
//                 final success = await _checkSubscriptionPayment(
//                   plan: plan,
//                   khqrMd5: md5,
//                 );
//
//                 if (success) {
//                   paymentCompleted = true;
//
//                   timer.cancel();
//
//                   if (!context.mounted) return;
//
//                   Navigator.of(context).pop();
//                   return;
//                 }
//
//                 /*
//                  * Stop after 2 minutes.
//                  */
//                 if (attempts >= 60) {
//                   timer.cancel();
//
//                   if (!context.mounted) return;
//
//                   setModalState(() {
//                     isCheckingPayment = false;
//                   });
//
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text(
//                         'Payment was not detected. Please try again.',
//                       ),
//                       backgroundColor: Colors.orange,
//                     ),
//                   );
//                 }
//               });
//             }
//
//             /*
//            * Automatically start checking as soon as
//            * the payment screen opens.
//            */
//             if (!isCheckingPayment && !paymentCompleted) {
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 if (!context.mounted) return;
//
//                 if (!isCheckingPayment && !paymentCompleted) {
//                   startAutoPaymentCheck();
//                 }
//               });
//             }
//
//             return PopScope(
//               canPop: !isCheckingPayment,
//               onPopInvokedWithResult: (didPop, result) {
//                 if (didPop) {
//                   paymentTimer?.cancel();
//                 }
//               },
//               child: Container(
//                 constraints: BoxConstraints(
//                   maxHeight: MediaQuery.of(context).size.height * 0.94,
//                 ),
//                 padding: EdgeInsets.only(
//                   top: 16,
//                   left: 20,
//                   right: 20,
//                   bottom: MediaQuery.of(context).viewInsets.bottom + 24,
//                 ),
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//                 ),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Center(
//                         child: Container(
//                           width: 40,
//                           height: 4,
//                           decoration: BoxDecoration(
//                             color: borderColor,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 18),
//
//                       const Text(
//                         'Bakong Payment',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.w800,
//                           color: textColor,
//                         ),
//                       ),
//
//                       const SizedBox(height: 6),
//
//                       Text(
//                         'Complete payment for ${plan.name}',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           color: secondaryTextColor,
//                         ),
//                       ),
//
//                       const SizedBox(height: 20),
//
//                       _buildPlanSummary(plan),
//
//                       const SizedBox(height: 20),
//
//                       _buildRealKhqrSection(plan: plan),
//
//                       const SizedBox(height: 24),
//
//                       /*
//                      * AUTO PAYMENT STATUS
//                      */
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFF8FAFC),
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(color: borderColor),
//                         ),
//                         child: Row(
//                           children: [
//                             if (isCheckingPayment)
//                               const SizedBox(
//                                 width: 22,
//                                 height: 22,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2.5,
//                                   color: primaryColor,
//                                 ),
//                               )
//                             else
//                               const Icon(
//                                 Icons.check_circle_outline_rounded,
//                                 color: Colors.green,
//                                 size: 24,
//                               ),
//
//                             const SizedBox(width: 12),
//
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     isCheckingPayment
//                                         ? 'Waiting for payment...'
//                                         : 'Payment verification ready',
//                                     style: const TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w700,
//                                       color: textColor,
//                                     ),
//                                   ),
//
//                                   const SizedBox(height: 4),
//
//                                   Text(
//                                     isCheckingPayment
//                                         ? 'Payment will be detected automatically.'
//                                         : 'Please scan the QR code to continue.',
//                                     style: const TextStyle(
//                                       fontSize: 12,
//                                       color: secondaryTextColor,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//
//                       const SizedBox(height: 16),
//
//                       const Center(
//                         child: Text(
//                           'Payment verification is automatic.',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: secondaryTextColor,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//
//     paymentTimer?.cancel();
//
//     _khqrCode = null;
//     _khqrMd5 = null;
//     _qrError = null;
//   }
//
//   // ==========================================================
//   // PLAN SUMMARY
//   // ==========================================================
//
//   Widget _buildPlanSummary(SubscriptionPlanModel plan) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   plan.name,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w700,
//                     fontSize: 15,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   '/ ${plan.billing}',
//                   style: const TextStyle(
//                     color: secondaryTextColor,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Text(
//             '${plan.currency == 'USD' ? '\$' : plan.currency}${plan.price.toStringAsFixed(2)}',
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.w800,
//               color: primaryColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==========================================================
//   // REAL KHQR SECTION
//   // ==========================================================
//
//   Widget _buildRealKhqrSection({required SubscriptionPlanModel plan}) {
//     final qr = _khqrCode;
//
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: borderColor),
//       ),
//       child: Column(
//         children: [
//           const Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.account_balance_wallet_rounded,
//                 color: Color(0xFF4F46E5),
//                 size: 20,
//               ),
//               SizedBox(width: 8),
//               Text(
//                 'Scan KHQR to Pay',
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w800,
//                   color: textColor,
//                 ),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 6),
//
//           const Text(
//             'Bakong',
//             style: TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//               color: secondaryTextColor,
//             ),
//           ),
//
//           const SizedBox(height: 16),
//
//           if (_qrError != null)
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFEF2F2),
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(color: const Color(0xFFFECACA)),
//               ),
//               child: Column(
//                 children: [
//                   const Icon(
//                     Icons.error_outline_rounded,
//                     color: Colors.red,
//                     size: 36,
//                   ),
//
//                   const SizedBox(height: 10),
//
//                   const Text(
//                     'Unable to generate KHQR',
//                     style: TextStyle(
//                       fontWeight: FontWeight.w700,
//                       color: Color(0xFF991B1B),
//                     ),
//                   ),
//
//                   const SizedBox(height: 6),
//
//                   Text(
//                     _qrError!,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       fontSize: 12,
//                       color: Color(0xFFB91C1C),
//                     ),
//                   ),
//
//                   const SizedBox(height: 12),
//
//                   OutlinedButton.icon(
//                     onPressed: _generateKhqr,
//                     icon: const Icon(Icons.refresh),
//                     label: const Text('Generate Again'),
//                   ),
//                 ],
//               ),
//             )
//           else if (qr == null || qr.isEmpty)
//             Container(
//               width: 260,
//               height: 260,
//               alignment: Alignment.center,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: borderColor),
//               ),
//               child: const CircularProgressIndicator(color: primaryColor),
//             )
//           else
//             Container(
//               width: 280,
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(18),
//                 border: Border.all(color: borderColor),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 14,
//                     offset: const Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: KhqrCardWidget(
//                 width: 250,
//                 receiverName: merchantName,
//                 amount: testPaymentAmount,
//                 keepIntegerDecimal: true,
//                 currency: KhqrCurrency.khr,
//                 qr: qr,
//               ),
//             ),
//
//           const SizedBox(height: 18),
//
//           _buildPaymentInfoRow(label: 'Receiver', value: bakongReceiver),
//
//           const SizedBox(height: 8),
//
//           _buildPaymentInfoRow(label: 'Plan', value: plan.name),
//
//           const SizedBox(height: 8),
//
//           _buildPaymentInfoRow(
//             label: 'Subscription',
//             value:
//                 '${plan.currency == 'USD' ? '\$' : plan.currency}${plan.price.toStringAsFixed(2)}',
//             valueColor: primaryColor,
//           ),
//
//           const SizedBox(height: 16),
//
//           const Text(
//             'Scan the QR code with your banking app to complete payment.',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 12,
//               height: 1.4,
//               color: secondaryTextColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==========================================================
//   // PAYMENT INFO ROW
//   // ==========================================================
//
//   Widget _buildPaymentInfoRow({
//     required String label,
//     required String value,
//     Color? valueColor,
//   }) {
//     return Row(
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 12, color: secondaryTextColor),
//         ),
//         const Spacer(),
//         Flexible(
//           child: Text(
//             value,
//             textAlign: TextAlign.end,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w700,
//               color: valueColor ?? textColor,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // ==========================================================
//   // SUBMIT / VERIFY PAYMENT
//   // ==========================================================
//
//   // Future<void> _submitPayment({
//   //   required SubscriptionPlanModel plan,
//   //   required String khqrMd5,
//   // }) async {
//   //   if (_ownerId == null) {
//   //     return;
//   //   }
//   //
//   //   try {
//   //     final hasPending = await _subscriptionService.hasPendingSubscription(
//   //       _ownerId!,
//   //     );
//   //
//   //     if (hasPending) {
//   //       throw Exception(
//   //         'You already have a pending subscription. '
//   //         'Please wait for admin approval.',
//   //       );
//   //     }
//   //
//   //     final paymentReference = 'SUB-${DateTime.now().millisecondsSinceEpoch}';
//   //
//   //     /*
//   //      * IMPORTANT:
//   //      *
//   //      * amount = REAL subscription price.
//   //      *
//   //      * Bakong verification inside
//   //      * SubscriptionService checks:
//   //      *
//   //      * 100 KHR
//   //      *
//   //      * against the real Bakong transaction.
//   //      */
//   //
//   //     final result = await _subscriptionService.completeSubscriptionPayment(
//   //       ownerId: _ownerId!,
//   //       planId: plan.id,
//   //       planName: plan.name,
//   //       amount: plan.price,
//   //       bakongMd5: khqrMd5,
//   //       paymentReference: paymentReference,
//   //     );
//   //
//   //     if (result['success'] != true) {
//   //       throw Exception('Bakong payment verification failed.');
//   //     }
//   //
//   //     if (!mounted) {
//   //       return;
//   //     }
//   //
//   //     /*
//   //      * Close the payment modal first.
//   //      */
//   //     Navigator.of(context).pop();
//   //
//   //     /*
//   //      * Show success / pending approval dialog.
//   //      */
//   //     await showDialog(
//   //       context: context,
//   //       barrierDismissible: false,
//   //       builder: (context) {
//   //         return const _SubscriptionSubmittedDialog();
//   //       },
//   //     );
//   //   } catch (e) {
//   //     if (!mounted) {
//   //       rethrow;
//   //     }
//   //
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(
//   //         content: Text('Payment verification failed:\n$e'),
//   //         backgroundColor: Colors.red,
//   //         behavior: SnackBarBehavior.floating,
//   //       ),
//   //     );
//   //
//   //     rethrow;
//   //   }
//   // }
// }
//
// class _SubscriptionSubmittedDialog extends StatefulWidget {
//   const _SubscriptionSubmittedDialog();
//
//   @override
//   State<_SubscriptionSubmittedDialog> createState() =>
//       _SubscriptionSubmittedDialogState();
// }
//
// class _SubscriptionSubmittedDialogState
//     extends State<_SubscriptionSubmittedDialog>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//
//   late Animation<double> _scaleAnimation;
//
//   late Animation<double> _fadeAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//
//     _scaleAnimation = CurvedAnimation(
//       parent: _controller,
//       curve: Curves.elasticOut,
//     );
//
//     _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
//
//     _controller.forward();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: ScaleTransition(
//         scale: _scaleAnimation,
//         child: Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(28),
//           ),
//           elevation: 0,
//           backgroundColor: Colors.white,
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 90,
//                   height: 90,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFF59E0B).withOpacity(0.12),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.hourglass_top_rounded,
//                     size: 56,
//                     color: Color(0xFFF59E0B),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 const Text(
//                   'Payment Verified',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.w800,
//                     color: Color(0xFF0F172A),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 const Text(
//                   'Your Bakong payment has been verified successfully. Your subscription is now pending admin approval.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 15,
//                     height: 1.5,
//                     color: Color(0xFF64748B),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(14),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFFFFBEB),
//                     borderRadius: BorderRadius.circular(14),
//                     border: Border.all(color: const Color(0xFFFCD34D)),
//                   ),
//                   child: const Text(
//                     'Subscription Status: Pending',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 13,
//                       height: 1.5,
//                       fontWeight: FontWeight.w700,
//                       color: Color(0xFF92400E),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 28),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 52,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF4F46E5),
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                     ),
//                     child: const Text(
//                       'Done',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w700,
//                         fontSize: 16,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khqr_sdk/khqr_sdk.dart';

import '../../../models/subscription_model.dart';
import '../../../models/subscription_plan_model.dart';
import '../../../services/session_service.dart';
import '../../../services/subscription_plans_services.dart';
import '../../../services/subscription_service.dart';

class OwnerSubscriptionScreen extends StatefulWidget {
  const OwnerSubscriptionScreen({super.key});

  @override
  State<OwnerSubscriptionScreen> createState() =>
      _OwnerSubscriptionScreenState();
}

class _OwnerSubscriptionScreenState extends State<OwnerSubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  final SubscriptionPlansService _plansService = SubscriptionPlansService();

  String? _ownerId;

  bool _isLoadingUser = true;

  int _selectedPlanIndex = 0;

  static const Color primaryColor = Color(0xFF4F46E5);

  static const Color backgroundColor = Color(0xFFF8FAFC);

  static const Color cardColor = Colors.white;

  static const Color textColor = Color(0xFF0F172A);

  static const Color secondaryTextColor = Color(0xFF64748B);

  static const Color borderColor = Color(0xFFE2E8F0);

  // ==========================================================
  // BAKONG CONFIGURATION
  // ==========================================================

  /*
   * Bakong receiver account.
   */
  static const String bakongReceiver = 'thearith_panha@bkrt';

  /*
   * IMPORTANT
   *
   * The subscription price is still shown as the real
   * subscription price in USD.
   *
   * But the actual Bakong test transaction uses:
   *
   * 100 KHR
   *
   * This is only for testing the payment flow.
   */
  static const double testPaymentAmount = 100.0;

  static const String testPaymentCurrency = 'KHR';

  /*
   * Merchant name shown in KHQR.
   */
  static const String merchantName = 'RentEase';

  static const String merchantCity = 'Phnom Penh';

  // ==========================================================
  // KHQR STATE
  // ==========================================================

  String? _khqrCode;

  String? _khqrMd5;

  bool _isGeneratingQr = false;

  String? _qrError;

  @override
  void initState() {
    super.initState();

    _loadUserSession();
  }

  // ==========================================================
  // LOAD USER
  // ==========================================================

  Future<void> _loadUserSession() async {
    try {
      final user = await SessionService.getUser();

      if (!mounted) return;

      if (user != null) {
        setState(() {
          _ownerId = user['uid']?.toString();

          _isLoadingUser = false;
        });
      } else {
        setState(() {
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      debugPrint('LOAD USER ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingUser = false;
      });

      await _showErrorDialog(
        title: 'Unable to Load Account',
        message:
            'We could not load your account information.\n\n'
            'Please try again.',
      );
    }
  }

  // ==========================================================
  // GENERATE KHQR
  // ==========================================================

  Future<void> _generateKhqr() async {
    if (_isGeneratingQr) return;

    if (!mounted) return;

    setState(() {
      _isGeneratingQr = true;

      _qrError = null;

      _khqrCode = null;

      _khqrMd5 = null;
    });

    try {
      /*
       * KHQR expiration.
       *
       * This is only QR expiration.
       * It does NOT call Bakong API.
       */
      final expirationTimestamp = DateTime.now()
          .add(const Duration(minutes: 10))
          .millisecondsSinceEpoch;

      /*
       * The actual test payment amount is 100 KHR.
       *
       * The subscription plan price remains USD
       * and is displayed separately in the UI.
       */
      final info = IndividualInfo(
        bakongAccountId: bakongReceiver,

        merchantName: merchantName,

        accountInformation: bakongReceiver,

        currency: KhqrCurrency.khr,

        amount: testPaymentAmount,

        expirationTimestamp: expirationTimestamp,
      );

      final result = KhqrSdk.generateIndividual(info);

      if (!result.isSuccess || result.data == null) {
        throw Exception(result.status.message ?? 'Unable to generate KHQR.');
      }

      final qr = result.data!.qr.trim();

      if (qr.isEmpty) {
        throw Exception('KHQR content is empty.');
      }

      final md5 = result.data!.md5Hash.trim();

      if (md5.isEmpty) {
        throw Exception('KHQR MD5 is empty.');
      }

      debugPrint('');
      debugPrint('======================================');
      debugPrint('KHQR GENERATED');
      debugPrint('======================================');
      debugPrint('Receiver: $bakongReceiver');
      debugPrint(
        'Test Payment: '
        '$testPaymentAmount $testPaymentCurrency',
      );
      debugPrint('MD5: $md5');
      debugPrint('QR: $qr');
      debugPrint('======================================');
      debugPrint('');

      if (!mounted) return;

      setState(() {
        _khqrCode = qr;

        _khqrMd5 = md5;

        _isGeneratingQr = false;
      });
    } catch (e, stackTrace) {
      debugPrint('KHQR GENERATION ERROR: $e');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isGeneratingQr = false;

        _qrError = e.toString();
      });
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        title: const Text(
          'Subscription Plan',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: _buildBody(),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {
    if (_isLoadingUser) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (_ownerId == null) {
      return const Center(
        child: Text(
          'Please log in to view subscriptions.',
          style: TextStyle(color: secondaryTextColor, fontSize: 15),
        ),
      );
    }

    return StreamBuilder<List<SubscriptionModel>>(
      stream: _subscriptionService.ownerSubscriptions(_ownerId!),
      builder: (context, subscriptionSnapshot) {
        if (subscriptionSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        if (subscriptionSnapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to load subscriptions.\n'
                '${subscriptionSnapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: secondaryTextColor),
              ),
            ),
          );
        }

        final subscriptions = subscriptionSnapshot.data ?? [];

        SubscriptionModel? activeSub;

        SubscriptionModel? pendingSub;

        for (final sub in subscriptions) {
          final status = sub.status.toLowerCase().trim();

          if (status == 'active' || status == 'approved') {
            activeSub = sub;
            break;
          }

          if (status == 'pending') {
            pendingSub = sub;
          }
        }

        return StreamBuilder<List<SubscriptionPlanModel>>(
          stream: _plansService.subscriptionPlans(),
          builder: (context, planSnapshot) {
            if (planSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            if (planSnapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load plans.\n'
                    '${planSnapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: secondaryTextColor),
                  ),
                ),
              );
            }

            final plans = planSnapshot.data ?? [];

            if (plans.isEmpty) {
              return const Center(
                child: Text(
                  'No subscription plans available.',
                  style: TextStyle(color: secondaryTextColor),
                ),
              );
            }

            if (_selectedPlanIndex >= plans.length) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                setState(() {
                  _selectedPlanIndex = 0;
                });
              });
            }

            final selectedIndex = _selectedPlanIndex < plans.length
                ? _selectedPlanIndex
                : 0;

            return _buildSubscriptionContent(
              activeSub: activeSub,
              pendingSub: pendingSub,
              plans: plans,
              selectedIndex: selectedIndex,
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // SUBSCRIPTION CONTENT
  // ==========================================================

  Widget _buildSubscriptionContent({
    SubscriptionModel? activeSub,
    SubscriptionModel? pendingSub,
    required List<SubscriptionPlanModel> plans,
    required int selectedIndex,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeSub != null) ...[
            _buildActiveStatusCard(activeSub),
            const SizedBox(height: 24),
          ] else if (pendingSub != null) ...[
            _buildPendingStatusCard(pendingSub),
            const SizedBox(height: 24),
          ],

          const Text(
            'Choose Your Plan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Unlock full property management tools for your account.',
            style: TextStyle(fontSize: 14, color: secondaryTextColor),
          ),

          const SizedBox(height: 20),

          _buildPlansList(plans),

          const SizedBox(height: 28),

          _buildSubscribeButton(
            pendingSub: pendingSub,
            plans: plans,
            selectedIndex: selectedIndex,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PLANS LIST
  // ==========================================================

  Widget _buildPlansList(List<SubscriptionPlanModel> plans) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final plan = plans[index];

        return _buildPlanCard(
          plan: plan,
          isSelected: _selectedPlanIndex == index,
          onSelect: () {
            setState(() {
              _selectedPlanIndex = index;
            });
          },
        );
      },
    );
  }

  // ==========================================================
  // SUBSCRIBE BUTTON
  // ==========================================================

  Widget _buildSubscribeButton({
    required SubscriptionModel? pendingSub,
    required List<SubscriptionPlanModel> plans,
    required int selectedIndex,
  }) {
    final selectedPlan = plans[selectedIndex];

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: pendingSub != null
            ? null
            : () => _openCheckoutModal(selectedPlan),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          disabledBackgroundColor: primaryColor.withOpacity(0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          pendingSub != null ? 'Approval Pending' : 'Subscribe Now',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ACTIVE CARD
  // ==========================================================

  Widget _buildActiveStatusCard(SubscriptionModel sub) {
    final expiryFormatted = sub.endDate != null
        ? DateFormat('MMM dd, yyyy').format(sub.endDate!)
        : 'N/A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${sub.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            sub.planName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Valid through $expiryFormatted',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PENDING CARD
  // ==========================================================

  Widget _buildPendingStatusCard(SubscriptionModel sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: Color(0xFFD97706),
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Approval Pending',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Your request for ${sub.planName} '
                  'is under review.',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PLAN CARD
  // ==========================================================

  Widget _buildPlanCard({
    required SubscriptionPlanModel plan,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    final bool isPopular = plan.popular;

    final bool isRecommended = plan.recommended;

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : borderColor,
            width: isSelected ? 2.2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: primaryColor.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? primaryColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? primaryColor : borderColor,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),

            if (isPopular || isRecommended) ...[
              const SizedBox(height: 10),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (isPopular)
                    _buildPlanBadge(text: 'POPULAR', color: primaryColor),
                  if (isRecommended)
                    _buildPlanBadge(text: 'RECOMMENDED', color: Colors.green),
                ],
              ),
            ],

            const SizedBox(height: 12),

            Text(
              plan.description,
              style: const TextStyle(fontSize: 13, color: secondaryTextColor),
            ),

            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${plan.currency == 'USD' ? '\$' : plan.currency}'
                  '${plan.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),

                const SizedBox(width: 4),

                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    '/ ${plan.billing}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(color: borderColor, height: 1),
            ),

            Row(
              children: [
                const Icon(
                  Icons.home_work_rounded,
                  color: primaryColor,
                  size: 17,
                ),

                const SizedBox(width: 10),

                Text(
                  plan.propertyLimit >= 999999
                      ? 'Unlimited Properties'
                      : 'Up to ${plan.propertyLimit} Properties',
                  style: const TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            if (plan.features.isNotEmpty) ...[
              const SizedBox(height: 10),

              ...plan.features.map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: primaryColor,
                        size: 17,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BADGE
  // ==========================================================

  Widget _buildPlanBadge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ==========================================================
  // CHECKOUT MODAL
  // ==========================================================

  Future<void> _openCheckoutModal(SubscriptionPlanModel plan) async {
    if (_ownerId == null) {
      await _showErrorDialog(
        title: 'Account Error',
        message:
            'Your account information is missing.\n\n'
            'Please log in again and try again.',
      );

      return;
    }

    try {
      /*
       * Check Firestore pending subscription.
       *
       * This is NOT a Bakong API request.
       */
      final hasPending = await _subscriptionService.hasPendingSubscription(
        _ownerId!,
      );

      if (!mounted) return;

      if (hasPending) {
        await _showErrorDialog(
          title: 'Subscription Pending',
          message:
              'You already have a pending subscription.\n\n'
              'Please wait for admin approval before '
              'creating another subscription.',
        );

        return;
      }

      /*
       * Reset KHQR state.
       */
      setState(() {
        _khqrCode = null;

        _khqrMd5 = null;

        _qrError = null;
      });

      /*
       * Generate QR.
       *
       * No Bakong verification happens here.
       */
      await _generateKhqr();

      if (!mounted) return;

      if (_khqrCode == null || _khqrMd5 == null) {
        await _showErrorDialog(
          title: 'Unable to Generate QR',
          message:
              _qrError ??
              'The Bakong QR code could not be generated.\n\n'
                  'Please try again.',
        );

        return;
      }

      /*
       * Local modal state.
       */
      bool isCheckingPayment = false;

      bool paymentCompleted = false;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        builder: (modalContext) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return PopScope(
                canPop: !isCheckingPayment,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.94,
                  ),
                  padding: EdgeInsets.only(
                    top: 16,
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==================================================
                        // HANDLE
                        // ==================================================
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: borderColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // TITLE
                        // ==================================================
                        const Text(
                          'Complete Subscription',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Complete payment for ${plan.name}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // PLAN SUMMARY
                        // ==================================================
                        _buildPlanSummary(plan),

                        const SizedBox(height: 20),

                        // ==================================================
                        // QR
                        // ==================================================
                        _buildRealKhqrSection(plan: plan),

                        const SizedBox(height: 24),

                        // ==================================================
                        // PAYMENT STATUS
                        // ==================================================
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              if (isCheckingPayment)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: primaryColor,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: primaryColor,
                                  size: 26,
                                ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isCheckingPayment
                                          ? 'Checking Payment...'
                                          : 'Payment Ready',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      isCheckingPayment
                                          ? 'Please wait while we verify your Bakong transaction.'
                                          : 'Scan the QR, complete payment, then press Check Payment.',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // CHECK PAYMENT BUTTON
                        // ==================================================
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: isCheckingPayment || paymentCompleted
                                ? null
                                : () async {
                                    /*
                                         * Prevent double click.
                                         */
                                    if (isCheckingPayment) {
                                      return;
                                    }

                                    final md5 = _khqrMd5;

                                    if (md5 == null || md5.trim().isEmpty) {
                                      await _showErrorDialog(
                                        title: 'Payment Information Missing',
                                        message:
                                            'The KHQR payment information is missing.\n\n'
                                            'Please generate a new QR code and try again.',
                                      );

                                      return;
                                    }

                                    /*
                                         * Lock button.
                                         */
                                    setModalState(() {
                                      isCheckingPayment = true;
                                    });

                                    try {
                                      debugPrint('');

                                      debugPrint(
                                        '========================================',
                                      );

                                      debugPrint(
                                        'MANUAL SUBSCRIPTION PAYMENT CHECK',
                                      );

                                      debugPrint(
                                        '========================================',
                                      );

                                      debugPrint('Owner ID: $_ownerId');

                                      debugPrint('Plan ID: ${plan.id}');

                                      debugPrint('Plan Name: ${plan.name}');

                                      debugPrint(
                                        'Real Plan Price: ${plan.price} ${plan.currency}',
                                      );

                                      debugPrint(
                                        'Test Payment: '
                                        '$testPaymentAmount '
                                        '$testPaymentCurrency',
                                      );

                                      debugPrint('MD5: $md5');

                                      debugPrint(
                                        '========================================',
                                      );

                                      /*
                                           * IMPORTANT:
                                           *
                                           * This is the ONLY place where
                                           * payment verification is started.
                                           *
                                           * ONE button click
                                           * =
                                           * ONE completeSubscriptionPayment()
                                           *
                                           * There is NO Timer.
                                           *
                                           * There is NO polling.
                                           */
                                      final paymentReference =
                                          'SUB-${DateTime.now().millisecondsSinceEpoch}';

                                      final result = await _subscriptionService
                                          .completeSubscriptionPayment(
                                            ownerId: _ownerId!,
                                            planId: plan.id,
                                            planName: plan.name,
                                            amount: plan.price,
                                            bakongMd5: md5,
                                            paymentReference: paymentReference,
                                          );

                                      debugPrint(
                                        '========================================',
                                      );

                                      debugPrint('SUBSCRIPTION PAYMENT RESULT');

                                      debugPrint('$result');

                                      debugPrint(
                                        '========================================',
                                      );

                                      if (!context.mounted) {
                                        return;
                                      }

                                      /*
                                           * Service should return
                                           * success == true only after
                                           * Bakong verification succeeds
                                           * and Firestore is updated.
                                           */
                                      if (result['success'] != true) {
                                        throw Exception(
                                          result['message']?.toString() ??
                                              'Bakong payment could not be verified.',
                                        );
                                      }

                                      paymentCompleted = true;

                                      setModalState(() {
                                        isCheckingPayment = false;
                                      });

                                      /*
                                           * Close payment sheet.
                                           */
                                      Navigator.of(context).pop();

                                      /*
                                           * Show success dialog
                                           * after the payment sheet closes.
                                           */
                                      await Future.delayed(
                                        const Duration(milliseconds: 150),
                                      );

                                      if (!mounted) {
                                        return;
                                      }

                                      await _showSuccessDialog(
                                        plan: plan,
                                        result: result,
                                      );
                                    } catch (e, stackTrace) {
                                      debugPrint(
                                        '========================================',
                                      );

                                      debugPrint('SUBSCRIPTION PAYMENT ERROR');

                                      debugPrint('$e');

                                      debugPrintStack(stackTrace: stackTrace);

                                      debugPrint(
                                        '========================================',
                                      );

                                      if (!context.mounted) {
                                        return;
                                      }

                                      /*
                                           * Unlock button.
                                           */
                                      setModalState(() {
                                        isCheckingPayment = false;
                                      });

                                      /*
                                           * IMPORTANT:
                                           *
                                           * We DO NOT close the payment
                                           * sheet on error.
                                           *
                                           * User can read the error
                                           * and try again manually.
                                           */
                                      await _showPaymentErrorDialog(error: e);
                                    }
                                  },
                            icon: Icon(
                              isCheckingPayment
                                  ? Icons.hourglass_top_rounded
                                  : Icons.verified_rounded,
                            ),
                            label: Text(
                              isCheckingPayment
                                  ? 'Checking Payment...'
                                  : 'Check Payment',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              disabledBackgroundColor: primaryColor.withOpacity(
                                0.45,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Center(
                          child: Text(
                            'After completing your payment, press "Check Payment" once to verify your transaction.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: secondaryTextColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      /*
       * Clear QR state after modal closes.
       */
      _khqrCode = null;

      _khqrMd5 = null;

      _qrError = null;
    } catch (e) {
      debugPrint('CHECKOUT ERROR: $e');

      if (!mounted) return;

      await _showErrorDialog(
        title: 'Payment Setup Error',
        message: e.toString(),
      );
    }
  }

  // ==========================================================
  // PLAN SUMMARY
  // ==========================================================

  Widget _buildPlanSummary(SubscriptionPlanModel plan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  '/ ${plan.billing}',
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '${plan.currency == 'USD' ? '\$' : plan.currency}'
            '${plan.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // KHQR SECTION
  // ==========================================================

  Widget _buildRealKhqrSection({required SubscriptionPlanModel plan}) {
    final qr = _khqrCode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFF4F46E5),
                size: 20,
              ),

              SizedBox(width: 8),

              Text(
                'Scan KHQR to Pay',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Text(
            'Bakong',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: secondaryTextColor,
            ),
          ),

          const SizedBox(height: 16),

          if (_qrError != null)
            _buildQrError()
          else if (qr == null || qr.isEmpty)
            Container(
              width: 260,
              height: 260,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: const CircularProgressIndicator(color: primaryColor),
            )
          else
            Container(
              width: 280,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: KhqrCardWidget(
                width: 250,
                receiverName: merchantName,
                amount: testPaymentAmount,
                keepIntegerDecimal: true,
                currency: KhqrCurrency.khr,
                qr: qr,
              ),
            ),

          const SizedBox(height: 18),

          _buildPaymentInfoRow(label: 'Receiver', value: bakongReceiver),

          const SizedBox(height: 8),

          _buildPaymentInfoRow(label: 'Plan', value: plan.name),

          const SizedBox(height: 8),

          /*
           * This keeps the UI looking like a real
           * subscription purchase.
           *
           * The real subscription price is displayed.
           */
          _buildPaymentInfoRow(
            label: 'Subscription',
            value:
                '${plan.currency == 'USD' ? '\$' : plan.currency}'
                '${plan.price.toStringAsFixed(2)}',
            valueColor: primaryColor,
          ),

          const SizedBox(height: 16),

          const Text(
            'Scan the QR code with your banking app to complete payment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // QR ERROR
  // ==========================================================

  Widget _buildQrError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 36),

          const SizedBox(height: 10),

          const Text(
            'Unable to generate KHQR',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF991B1B),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _qrError!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _generateKhqr,
            icon: const Icon(Icons.refresh),
            label: const Text('Generate Again'),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PAYMENT INFO ROW
  // ==========================================================

  Widget _buildPaymentInfoRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: secondaryTextColor),
        ),

        const Spacer(),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? textColor,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ERROR DIALOG
  // ==========================================================

  Future<void> _showErrorDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            _cleanErrorMessage(message),
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: secondaryTextColor,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // PAYMENT ERROR DIALOG
  // ==========================================================

  Future<void> _showPaymentErrorDialog({required Object error}) async {
    if (!mounted) return;

    final rawMessage = error.toString();

    final lowerMessage = rawMessage.toLowerCase();

    /*
     * Special message for Bakong
     * daily request limit.
     */
    if (lowerMessage.contains('daily request limit') ||
        lowerMessage.contains('rate limit')) {
      await _showSpecialErrorDialog(
        title: 'Verification Temporarily Unavailable',
        icon: Icons.cloud_off_rounded,
        iconColor: const Color(0xFFF59E0B),
        backgroundColor: const Color(0xFFFFFBEB),
        message:
            'Bakong verification cannot be completed right now because the Bakong API daily request limit has been reached.\n\n'
            'This does not necessarily mean your payment failed.\n\n'
            'Please try again later.',
      );

      return;
    }

    /*
     * Unauthorized / authentication
     * problem.
     */
    if (lowerMessage.contains('unauthorized') || lowerMessage.contains('401')) {
      await _showSpecialErrorDialog(
        title: 'Bakong Verification Error',
        icon: Icons.lock_outline_rounded,
        iconColor: const Color(0xFFEF4444),
        backgroundColor: const Color(0xFFFEF2F2),
        message:
            'Bakong could not authorize the payment verification request.\n\n'
            'Please try again later.',
      );

      return;
    }

    /*
     * Normal payment verification
     * error.
     */
    await _showSpecialErrorDialog(
      title: 'Payment Not Confirmed',
      icon: Icons.payment_rounded,
      iconColor: const Color(0xFFEF4444),
      backgroundColor: const Color(0xFFFEF2F2),
      message:
          'We could not confirm this Bakong payment.\n\n'
          'Please make sure the payment was completed successfully and then press "Check Payment" again.\n\n'
          '${_cleanErrorMessage(rawMessage)}',
    );
  }

  // ==========================================================
  // SPECIAL ERROR DIALOG
  // ==========================================================

  Future<void> _showSpecialErrorDialog({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: iconColor),
              ),

              const SizedBox(height: 20),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: secondaryTextColor,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // SUCCESS DIALOG
  // ==========================================================

  Future<void> _showSuccessDialog({
    required SubscriptionPlanModel plan,
    required Map<String, dynamic> result,
  }) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _SubscriptionSubmittedDialog(planName: plan.name);
      },
    );
  }

  // ==========================================================
  // CLEAN ERROR MESSAGE
  // ==========================================================

  String _cleanErrorMessage(String message) {
    var value = message.trim();

    if (value.startsWith('Exception: ')) {
      value = value.substring('Exception: '.length);
    }

    return value;
  }
}

// ============================================================
// SUCCESS DIALOG
// ============================================================

class _SubscriptionSubmittedDialog extends StatefulWidget {
  final String planName;

  const _SubscriptionSubmittedDialog({required this.planName});

  @override
  State<_SubscriptionSubmittedDialog> createState() =>
      _SubscriptionSubmittedDialogState();
}

class _SubscriptionSubmittedDialogState
    extends State<_SubscriptionSubmittedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _scaleAnimation;

  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ========================================================
                // SUCCESS ICON
                // ========================================================
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 56,
                    color: Color(0xFF10B981),
                  ),
                ),

                const SizedBox(height: 24),

                // ========================================================
                // TITLE
                // ========================================================
                const Text(
                  'Payment Verified',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Your Bakong payment for ${widget.planName} has been verified successfully.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 20),

                // ========================================================
                // PENDING STATUS
                // ========================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Subscription Status',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB45309),
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        'Pending Admin Approval',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Your payment has been saved successfully. An administrator will review and approve your subscription.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 28),

                // ========================================================
                // DONE BUTTON
                // ========================================================
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
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
