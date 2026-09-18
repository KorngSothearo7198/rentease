// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
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
//   final SubscriptionPlansService _subscriptionService = SubscriptionPlansService();
//
//   String? _ownerId;
//   bool _isLoadingUser = true;
//   int _selectedPlanIndex = 0;
//
//   // ==================== THEME ====================
//
//   static const Color primaryColor = Color(0xFF4F46E5);
//   static const Color backgroundColor = Color(0xFFF8FAFC);
//   static const Color cardColor = Colors.white;
//   static const Color textColor = Color(0xFF0F172A);
//   static const Color secondaryTextColor = Color(0xFF64748B);
//   static const Color borderColor = Color(0xFFE2E8F0);
//
//   // ==================== BANKS ====================
//
//
//
//   // ==================== INIT ====================
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUserSession();
//   }
//
//   // ==================== LOAD USER ====================
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
//   // ==================== BUILD ====================
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
//           style: TextStyle(
//             fontWeight: FontWeight.w800,
//             fontSize: 20,
//           ),
//         ),
//       ),
//       body: _buildBody(),
//     );
//   }
//
//   // ==================== BODY ====================
//
//   Widget _buildBody() {
//     if (_isLoadingUser) {
//       return const Center(
//         child: CircularProgressIndicator(
//           color: primaryColor,
//         ),
//       );
//     }
//
//     if (_ownerId == null) {
//       return const Center(
//         child: Text(
//           'Please log in to view subscriptions.',
//           style: TextStyle(
//             color: secondaryTextColor,
//             fontSize: 15,
//           ),
//         ),
//       );
//     }
//
//     return StreamBuilder<List<SubscriptionModel>>(
//       stream: _subscriptionService.ownerSubscriptions(_ownerId!),
//       builder: (context, subscriptionSnapshot) {
//         if (subscriptionSnapshot.connectionState ==
//             ConnectionState.waiting) {
//           return const Center(
//             child: CircularProgressIndicator(
//               color: primaryColor,
//             ),
//           );
//         }
//
//         if (subscriptionSnapshot.hasError) {
//           return _buildError(
//             'Unable to load subscriptions.\n'
//             '${subscriptionSnapshot.error}',
//           );
//         }
//
//         final subscriptions = subscriptionSnapshot.data ?? [];
//
//         SubscriptionModel? activeSub;
//         SubscriptionModel? pendingSub;
//
//         for (final sub in subscriptions) {
//           final status = sub.status.toLowerCase();
//
//           if (status == 'approved' || status == 'active') {
//             activeSub = sub;
//             break;
//           }
//
//           if (status == 'pending') {
//             pendingSub ??= sub;
//           }
//         }
//
//         return StreamBuilder<List<SubscriptionPlanModel>>(
//           stream: _subscriptionService.subscriptionPlans(),
//           builder: (context, planSnapshot) {
//             if (planSnapshot.connectionState ==
//                 ConnectionState.waiting) {
//               return const Center(
//                 child: CircularProgressIndicator(
//                   color: primaryColor,
//                 ),
//               );
//             }
//
//             if (planSnapshot.hasError) {
//               return _buildError(
//                 'Unable to load subscription plans.\n'
//                 '${planSnapshot.error}',
//               );
//             }
//
//             final plans = planSnapshot.data ?? [];
//
//             if (plans.isEmpty) {
//               return const Center(
//                 child: Text(
//                   'No subscription plans available.',
//                   style: TextStyle(
//                     color: secondaryTextColor,
//                     fontSize: 15,
//                   ),
//                 ),
//               );
//             }
//
//             // Prevent selected index from becoming invalid
//             // when Firestore plans change.
//             if (_selectedPlanIndex >= plans.length) {
//               _selectedPlanIndex = 0;
//             }
//
//             return _buildSubscriptionContent(
//               activeSub: activeSub,
//               pendingSub: pendingSub,
//               plans: plans,
//             );
//           },
//         );
//       },
//     );
//   }
//
//   // ==================== ERROR ====================
//
//   Widget _buildError(String message) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(
//               Icons.error_outline_rounded,
//               size: 48,
//               color: Colors.redAccent,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 color: secondaryTextColor,
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ==================== SUBSCRIPTION CONTENT ====================
//
//   Widget _buildSubscriptionContent({
//     required SubscriptionModel? activeSub,
//     required SubscriptionModel? pendingSub,
//     required List<SubscriptionPlanModel> plans,
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
//
//           const Text(
//             'Choose Your Plan',
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.w800,
//               color: textColor,
//             ),
//           ),
//
//           const SizedBox(height: 6),
//
//           const Text(
//             'Unlock full property management tools for your account.',
//             style: TextStyle(
//               fontSize: 14,
//               color: secondaryTextColor,
//             ),
//           ),
//
//           const SizedBox(height: 20),
//
//           _buildPlansList(plans),
//
//           const SizedBox(height: 28),
//
//           _buildSubscribeButton(
//             pendingSub: pendingSub,
//             plans: plans,
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==================== PLANS LIST ====================
//
//   Widget _buildPlansList(
//     List<SubscriptionPlanModel> plans,
//   ) {
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
//   // ==================== SUBSCRIBE BUTTON ====================
//
//   Widget _buildSubscribeButton({
//     required SubscriptionModel? pendingSub,
//     required List<SubscriptionPlanModel> plans,
//   }) {
//     if (plans.isEmpty) {
//       return const SizedBox.shrink();
//     }
//
//     final selectedPlan = plans[_selectedPlanIndex];
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
//           pendingSub != null
//               ? 'Approval Pending'
//               : 'Subscribe Now',
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
//   // ==================== ACTIVE STATUS ====================
//
//   Widget _buildActiveStatusCard(
//     SubscriptionModel sub,
//   ) {
//     final expiryFormatted = sub.endDate != null
//         ? DateFormat('MMM dd, yyyy').format(sub.endDate!)
//         : 'N/A';
//
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [
//             Color(0xFF10B981),
//             Color(0xFF059669),
//           ],
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
//             mainAxisAlignment:
//                 MainAxisAlignment.spaceBetween,
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
//                     Icon(
//                       Icons.check_circle,
//                       color: Colors.white,
//                       size: 14,
//                     ),
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
//
//           const SizedBox(height: 14),
//
//           Text(
//             sub.planName,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 22,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//
//           const SizedBox(height: 4),
//
//           Text(
//             'Valid through $expiryFormatted',
//             style: const TextStyle(
//               color: Colors.white70,
//               fontSize: 13,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==================== PENDING STATUS ====================
//
//   Widget _buildPendingStatusCard(
//     SubscriptionModel sub,
//   ) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: const Color(0xFFFFFBEB),
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(
//           color: const Color(0xFFFCD34D),
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color: const Color(0xFFF59E0B)
//                   .withOpacity(0.15),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.hourglass_top_rounded,
//               color: Color(0xFFD97706),
//               size: 22,
//             ),
//           ),
//
//           const SizedBox(width: 14),
//
//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Approval Pending',
//                   style: TextStyle(
//                     color: Color(0xFF92400E),
//                     fontWeight: FontWeight.w700,
//                     fontSize: 15,
//                   ),
//                 ),
//
//                 const SizedBox(height: 3),
//
//                 Text(
//                   'Your request for ${sub.planName} '
//                   'is under review.',
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
//   // ==================== PLAN CARD ====================
//
//   Widget _buildPlanCard({
//     required SubscriptionPlanModel plan,
//     required bool isSelected,
//     required VoidCallback onSelect,
//   }) {
//     return GestureDetector(
//       onTap: onSelect,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 220),
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: cardColor,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: isSelected
//                 ? primaryColor
//                 : borderColor,
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
//           crossAxisAlignment:
//               CrossAxisAlignment.start,
//           children: [
//             // ==================== NAME ====================
//
//             Row(
//               children: [
//                 Expanded(
//                   child: Row(
//                     children: [
//                       Flexible(
//                         child: Text(
//                           plan.name,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(
//                             fontSize: 17,
//                             fontWeight: FontWeight.w800,
//                             color: textColor,
//                           ),
//                         ),
//                       ),
//
//                       if (plan.popular) ...[
//                         const SizedBox(width: 8),
//
//                         Container(
//                           padding:
//                               const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 3,
//                           ),
//                           decoration: BoxDecoration(
//                             color: primaryColor
//                                 .withOpacity(0.12),
//                             borderRadius:
//                                 BorderRadius.circular(20),
//                           ),
//                           child: const Text(
//                             'POPULAR',
//                             style: TextStyle(
//                               color: primaryColor,
//                               fontSize: 10,
//                               fontWeight:
//                                   FontWeight.w800,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//
//                 AnimatedContainer(
//                   duration:
//                       const Duration(milliseconds: 200),
//                   width: 24,
//                   height: 24,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: isSelected
//                         ? primaryColor
//                         : Colors.transparent,
//                     border: Border.all(
//                       color: isSelected
//                           ? primaryColor
//                           : borderColor,
//                       width: 2,
//                     ),
//                   ),
//                   child: isSelected
//                       ? const Icon(
//                           Icons.check,
//                           size: 14,
//                           color: Colors.white,
//                         )
//                       : null,
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 12),
//
//             // ==================== PRICE ====================
//
//             Row(
//               crossAxisAlignment:
//                   CrossAxisAlignment.end,
//               children: [
//                 Text(
//                   '\$${plan.price.toStringAsFixed(0)}',
//                   style: const TextStyle(
//                     fontSize: 30,
//                     fontWeight: FontWeight.w800,
//                     color: textColor,
//                   ),
//                 ),
//
//                 const SizedBox(width: 4),
//
//                 Padding(
//                   padding:
//                       const EdgeInsets.only(bottom: 5),
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
//
//             const Padding(
//               padding:
//                   EdgeInsets.symmetric(vertical: 14),
//               child: Divider(
//                 color: borderColor,
//                 height: 1,
//               ),
//             ),
//
//             // ==================== FEATURES ====================
//
//             ...plan.features.map(
//               (feature) {
//                 return Padding(
//                   padding:
//                       const EdgeInsets.only(bottom: 8),
//                   child: Row(
//                     children: [
//                       const Icon(
//                         Icons.check_circle_rounded,
//                         color: primaryColor,
//                         size: 17,
//                       ),
//
//                       const SizedBox(width: 10),
//
//                       Expanded(
//                         child: Text(
//                           feature,
//                           style: const TextStyle(
//                             fontSize: 14,
//                             color:
//                                 secondaryTextColor,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ==================== CHECKOUT MODAL ====================
//
//   void _openCheckoutModal(
//     SubscriptionPlanModel plan,
//   ) {
//     int selectedBankIndex = 0;
//     bool isProcessing = false;
//     int countdown = 5;
//
//     Timer? timer;
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       isDismissible: true,
//       enableDrag: true,
//       builder: (modalContext) {
//         return StatefulBuilder(
//           builder: (
//             context,
//             setModalState,
//           ) {
//             void startAutoPayment() {
//               if (isProcessing) return;
//
//               setModalState(() {
//                 isProcessing = true;
//                 countdown = 5;
//               });
//
//               timer?.cancel();
//
//               timer = Timer.periodic(
//                 const Duration(seconds: 1),
//                 (timerInstance) {
//                   if (!context.mounted) {
//                     timerInstance.cancel();
//                     return;
//                   }
//
//                   if (countdown <= 1) {
//                     timerInstance.cancel();
//
//                     _submitPayment(
//                       plan: plan,
//                       bankName: _banks[
//                         selectedBankIndex
//                       ]['name'].toString(),
//                     );
//                   } else {
//                     setModalState(() {
//                       countdown--;
//                     });
//                   }
//                 },
//               );
//             }
//
//             return PopScope(
//               canPop: !isProcessing,
//               onPopInvokedWithResult:
//                   (didPop, result) {
//                 if (didPop) {
//                   timer?.cancel();
//                 }
//               },
//               child: Container(
//                 constraints: BoxConstraints(
//                   maxHeight:
//                       MediaQuery.of(context)
//                               .size
//                               .height *
//                           0.92,
//                 ),
//                 padding: EdgeInsets.only(
//                   top: 16,
//                   left: 20,
//                   right: 20,
//                   bottom:
//                       MediaQuery.of(context)
//                               .viewInsets
//                               .bottom +
//                           24,
//                 ),
//                 decoration:
//                     const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius:
//                       BorderRadius.vertical(
//                     top: Radius.circular(28),
//                   ),
//                 ),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     mainAxisSize:
//                         MainAxisSize.min,
//                     crossAxisAlignment:
//                         CrossAxisAlignment.start,
//                     children: [
//                       // ==================== HANDLE ====================
//
//                       Center(
//                         child: Container(
//                           width: 40,
//                           height: 4,
//                           decoration:
//                               BoxDecoration(
//                             color: borderColor,
//                             borderRadius:
//                                 BorderRadius.circular(
//                               10,
//                             ),
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 18),
//
//                       // ==================== TITLE ====================
//
//                       const Text(
//                         'Confirm Payment',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight:
//                               FontWeight.w800,
//                           color: textColor,
//                         ),
//                       ),
//
//                       const SizedBox(height: 6),
//
//                       Text(
//                         'Complete payment for '
//                         '${plan.name}',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           color:
//                               secondaryTextColor,
//                         ),
//                       ),
//
//                       const SizedBox(height: 20),
//
//                       // ==================== PLAN SUMMARY ====================
//
//                       _buildPlanSummary(plan),
//
//                       const SizedBox(height: 24),
//
//                       // ==================== SELECT BANK ====================
//
//                       const Text(
//                         'Select Bank',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight:
//                               FontWeight.w700,
//                           color: textColor,
//                         ),
//                       ),
//
//                       const SizedBox(height: 12),
//
//                       Row(
//                         children: List.generate(
//                           _banks.length,
//                           (index) {
//                             final bank =
//                                 _banks[index];
//
//                             final isSelected =
//                                 selectedBankIndex ==
//                                     index;
//
//                             final Color bankColor =
//                                 bank['color']
//                                     as Color;
//
//                             return Expanded(
//                               child:
//                                   GestureDetector(
//                                 onTap:
//                                     isProcessing
//                                         ? null
//                                         : () {
//                                             setModalState(
//                                               () {
//                                                 selectedBankIndex =
//                                                     index;
//                                               },
//                                             );
//                                           },
//                                 child:
//                                     AnimatedContainer(
//                                   duration:
//                                       const Duration(
//                                     milliseconds:
//                                         200,
//                                   ),
//                                   margin:
//                                       EdgeInsets.only(
//                                     right: index <
//                                             2
//                                         ? 10
//                                         : 0,
//                                   ),
//                                   padding:
//                                       const EdgeInsets
//                                           .symmetric(
//                                     vertical: 14,
//                                   ),
//                                   decoration:
//                                       BoxDecoration(
//                                     color: isSelected
//                                         ? bankColor
//                                             .withOpacity(
//                                             0.1,
//                                           )
//                                         : backgroundColor,
//                                     borderRadius:
//                                         BorderRadius
//                                             .circular(
//                                       14,
//                                     ),
//                                     border:
//                                         Border.all(
//                                       color: isSelected
//                                           ? bankColor
//                                           : borderColor,
//                                       width: isSelected
//                                           ? 2
//                                           : 1,
//                                     ),
//                                   ),
//                                   child: Column(
//                                     children: [
//                                       Container(
//                                         width: 36,
//                                         height: 36,
//                                         decoration:
//                                             BoxDecoration(
//                                           color:
//                                               bankColor,
//                                           shape:
//                                               BoxShape
//                                                   .circle,
//                                         ),
//                                         child: Center(
//                                           child: Text(
//                                             bank['name']
//                                                 .toString()
//                                                 .substring(
//                                                   0,
//                                                   1,
//                                                 ),
//                                             style:
//                                                 const TextStyle(
//                                               color: Colors
//                                                   .white,
//                                               fontWeight:
//                                                   FontWeight
//                                                       .w800,
//                                               fontSize:
//                                                   16,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//
//                                       const SizedBox(
//                                         height: 8,
//                                       ),
//
//                                       Text(
//                                         bank['name']
//                                             .toString()
//                                             .split(
//                                               ' ',
//                                             )[0],
//                                         style:
//                                             TextStyle(
//                                           fontSize:
//                                               12,
//                                           fontWeight:
//                                               FontWeight
//                                                   .w700,
//                                           color: isSelected
//                                               ? bankColor
//                                               : secondaryTextColor,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//
//                       const SizedBox(height: 24),
//
//                       // ==================== QR CODE ====================
//
//                       _buildQrPaymentSection(
//                         bank: _banks[
//                             selectedBankIndex],
//                         plan: plan,
//                       ),
//
//                       const SizedBox(height: 28),
//
//                       // ==================== PAY BUTTON ====================
//
//                       SizedBox(
//                         width: double.infinity,
//                         height: 56,
//                         child: ElevatedButton(
//                           onPressed:
//                               isProcessing
//                                   ? null
//                                   : startAutoPayment,
//                           style:
//                               ElevatedButton.styleFrom(
//                             backgroundColor:
//                                 primaryColor,
//                             disabledBackgroundColor:
//                                 primaryColor
//                                     .withOpacity(
//                               0.7,
//                             ),
//                             elevation: 0,
//                             shape:
//                                 RoundedRectangleBorder(
//                               borderRadius:
//                                   BorderRadius
//                                       .circular(
//                                 16,
//                               ),
//                             ),
//                           ),
//                           child: isProcessing
//                               ? Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment
//                                           .center,
//                                   children: [
//                                     const SizedBox(
//                                       width: 20,
//                                       height: 20,
//                                       child:
//                                           CircularProgressIndicator(
//                                         strokeWidth:
//                                             2.5,
//                                         color: Colors
//                                             .white,
//                                       ),
//                                     ),
//
//                                     const SizedBox(
//                                       width: 14,
//                                     ),
//
//                                     Text(
//                                       'Processing... '
//                                       '$countdown s',
//                                       style:
//                                           const TextStyle(
//                                         fontWeight:
//                                             FontWeight
//                                                 .w700,
//                                         fontSize: 16,
//                                         color: Colors
//                                             .white,
//                                       ),
//                                     ),
//                                   ],
//                                 )
//                               : const Text(
//                                   'I Have Paid • '
//                                   'Auto Confirm (5s)',
//                                   style:
//                                       TextStyle(
//                                     fontWeight:
//                                         FontWeight
//                                             .w700,
//                                     fontSize: 16,
//                                     color: Colors
//                                         .white,
//                                   ),
//                                 ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 12),
//
//                       if (!isProcessing)
//                         Center(
//                           child: Text(
//                             'Payment request will be '
//                             'submitted after 5 seconds.',
//                             textAlign:
//                                 TextAlign.center,
//                             style: TextStyle(
//                               fontSize: 12,
//                               color:
//                                   secondaryTextColor
//                                       .withOpacity(
//                                 0.8,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     ).whenComplete(() {
//       timer?.cancel();
//     });
//   }
//
//   // ==================== PLAN SUMMARY ====================
//
//   Widget _buildPlanSummary(
//     SubscriptionPlanModel plan,
//   ) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         mainAxisAlignment:
//             MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   plan.name,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w700,
//                     fontSize: 15,
//                   ),
//                 ),
//
//                 const SizedBox(height: 2),
//
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
//
//           Text(
//             '\$${plan.price.toStringAsFixed(2)}',
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
//   // ==================== QR PAYMENT ====================
//
//   Widget _buildQrPaymentSection({
//     required Map<String, dynamic> bank,
//     required SubscriptionPlanModel plan,
//   }) {
//     final Color bankColor =
//         bank['color'] as Color;
//
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: borderColor,
//         ),
//       ),
//       child: Column(
//         children: [
//           const Text(
//             'Scan QR Code to Pay',
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w700,
//               color: textColor,
//             ),
//           ),
//
//           const SizedBox(height: 6),
//
//           Text(
//             bank['name'].toString(),
//             style: TextStyle(
//               fontSize: 13,
//               color: bankColor,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//
//           const SizedBox(height: 16),
//
//           Container(
//             width: 180,
//             height: 180,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius:
//                   BorderRadius.circular(16),
//               border: Border.all(
//                 color: borderColor,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color:
//                       Colors.black.withOpacity(
//                     0.05,
//                   ),
//                   blurRadius: 12,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisAlignment:
//                   MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.qr_code_2_rounded,
//                   size: 90,
//                   color: bankColor,
//                 ),
//
//                 const SizedBox(height: 8),
//
//                 const Text(
//                   'QR Code',
//                   style: TextStyle(
//                     fontSize: 13,
//                     color:
//                         secondaryTextColor,
//                     fontWeight:
//                         FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           const SizedBox(height: 16),
//
//           Text(
//             'Account: ${bank['account']}',
//             style: const TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//               color: textColor,
//             ),
//           ),
//
//           const SizedBox(height: 4),
//
//           Text(
//             'Amount: '
//             '\$${plan.price.toStringAsFixed(2)}',
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w800,
//               color: primaryColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==================== SUBMIT PAYMENT ====================
//
//   Future<void> _submitPayment({
//     required SubscriptionPlanModel plan,
//     required String bankName,
//   }) async {
//     if (_ownerId == null) {
//       return;
//     }
//
//     try {
//       // Check again before creating the subscription.
//       // This prevents duplicate pending requests.
//       final hasPending =
//           await _subscriptionService
//               .hasPendingSubscription(
//         _ownerId!,
//       );
//
//       if (hasPending) {
//         if (!mounted) return;
//
//         ScaffoldMessenger.of(context)
//             .showSnackBar(
//           const SnackBar(
//             content: Text(
//               'You already have a pending subscription.',
//             ),
//             backgroundColor: Colors.orange,
//           ),
//         );
//
//         return;
//       }
//
//       final paymentReference =
//           'AUTO-${DateTime.now().millisecondsSinceEpoch}';
//
//       await _subscriptionService
//           .createSubscription(
//         ownerId: _ownerId!,
//         planId: plan.id,
//         planName: plan.name,
//         amount: plan.price,
//         paymentMethod: bankName,
//         paymentReference:
//             paymentReference,
//       );
//
//       if (!mounted) return;
//
//       // Close checkout modal.
//       Navigator.of(context).pop();
//
//       // Show submitted dialog.
//       await showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) {
//           return const _SubscriptionSubmittedDialog();
//         },
//       );
//     } catch (e) {
//       if (!mounted) return;
//
//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         SnackBar(
//           content: Text(
//             'Payment submission failed: $e',
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
// }
//
// // ============================================================================
// // SUBSCRIPTION SUBMITTED DIALOG
// // ============================================================================
//
// class _SubscriptionSubmittedDialog
//     extends StatefulWidget {
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
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _fadeAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _controller = AnimationController(
//       vsync: this,
//       duration:
//           const Duration(milliseconds: 600),
//     );
//
//     _scaleAnimation =
//         CurvedAnimation(
//       parent: _controller,
//       curve: Curves.elasticOut,
//     );
//
//     _fadeAnimation =
//         CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeIn,
//     );
//
//     _controller.forward();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
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
//           shape:
//               RoundedRectangleBorder(
//             borderRadius:
//                 BorderRadius.circular(28),
//           ),
//           elevation: 0,
//           backgroundColor: Colors.white,
//           child: Padding(
//             padding:
//                 const EdgeInsets.fromLTRB(
//               28,
//               36,
//               28,
//               28,
//             ),
//             child: Column(
//               mainAxisSize:
//                   MainAxisSize.min,
//               children: [
//                 // ==================== ICON ====================
//
//                 Container(
//                   width: 90,
//                   height: 90,
//                   decoration:
//                       BoxDecoration(
//                     color: const Color(
//                       0xFFF59E0B,
//                     ).withOpacity(0.12),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons
//                         .hourglass_top_rounded,
//                     size: 56,
//                     color:
//                         Color(0xFFF59E0B),
//                   ),
//                 ),
//
//                 const SizedBox(height: 24),
//
//                 // ==================== TITLE ====================
//
//                 const Text(
//                   'Request Submitted',
//                   textAlign:
//                       TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight:
//                         FontWeight.w800,
//                     color:
//                         Color(0xFF0F172A),
//                   ),
//                 ),
//
//                 const SizedBox(height: 12),
//
//                 // ==================== MESSAGE ====================
//
//                 const Text(
//                   'Your payment request has '
//                   'been submitted successfully. '
//                   'Your subscription is now '
//                   'pending admin approval.',
//                   textAlign:
//                       TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 15,
//                     height: 1.5,
//                     color:
//                         Color(0xFF64748B),
//                   ),
//                 ),
//
//                 const SizedBox(height: 32),
//
//                 // ==================== DONE ====================
//
//                 SizedBox(
//                   width: double.infinity,
//                   height: 52,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.pop(
//                         context,
//                       );
//                     },
//                     style:
//                         ElevatedButton.styleFrom(
//                       // backgroundColor:
//                       //     primaryColor,
//                       elevation: 0,
//                       shape:
//                           RoundedRectangleBorder(
//                         borderRadius:
//                             BorderRadius.circular(
//                           14,
//                         ),
//                       ),
//                     ),
//                     child: const Text(
//                       'Done',
//                       style: TextStyle(
//                         fontWeight:
//                             FontWeight.w700,
//                         fontSize: 16,
//                         color:
//                             Colors.white,
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
//
