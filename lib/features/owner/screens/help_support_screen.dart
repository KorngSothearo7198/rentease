// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// import '../../../models/support_ticket_model.dart';
// import '../../../models/user_model.dart';
// import '../../../services/session_service.dart';
// import '../../../services/support_service.dart';
// import '../../../services/user_service.dart';
//
// class HelpSupportScreen extends StatefulWidget {
//   const HelpSupportScreen({super.key});
//
//   @override
//   State<HelpSupportScreen> createState() => _HelpSupportScreenState();
// }
//
// class _HelpSupportScreenState extends State<HelpSupportScreen> {
//   // ==========================================================
//   // SERVICES
//   // ==========================================================
//
//   final UserService _adminService = UserService();
//   final SupportService _supportService = SupportService();
//
//   // ==========================================================
//   // FORM
//   // ==========================================================
//
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//
//   final TextEditingController _subjectController =
//   TextEditingController();
//
//   final TextEditingController _messageController =
//   TextEditingController();
//
//   // ==========================================================
//   // USER STATE
//   // ==========================================================
//
//   String? _userId;
//   String _userName = '';
//   String _userEmail = '';
//   String _userRole = '';
//
//   // ==========================================================
//   // ADMIN STATE
//   // ==========================================================
//
//   UserModel? _admin;
//
//   bool _loadingAdmin = true;
//   bool _loadingUser = true;
//   bool _submitting = false;
//
//   // ==========================================================
//   // COLORS
//   // ==========================================================
//
//   static const Color primaryColor = Color(0xFF6C63FF);
//   static const Color primaryDark = Color(0xFF5548D9);
//
//   static const Color backgroundColor = Color(0xFFF8F9FC);
//   static const Color textColor = Color(0xFF111827);
//   static const Color secondaryTextColor = Color(0xFF6B7280);
//   static const Color borderColor = Color(0xFFE5E7EB);
//
//   // ==========================================================
//   // INIT
//   // ==========================================================
//
//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }
//
//   // ==========================================================
//   // LOAD USER + ADMIN
//   // ==========================================================
//
//   Future<void> _loadData() async {
//     setState(() {
//       _loadingUser = true;
//       _loadingAdmin = true;
//     });
//
//     try {
//       // ========================================================
//       // LOAD CURRENT USER
//       // ========================================================
//
//       final savedUser = await SessionService.getUser();
//
//       if (savedUser != null) {
//         _userId = savedUser['uid']?.toString() ?? '';
//         _userName = savedUser['fullName']?.toString() ?? '';
//         _userEmail = savedUser['email']?.toString() ?? '';
//         _userRole = savedUser['role']?.toString().toLowerCase() ?? '';
//       }
//
//       // ========================================================
//       // LOAD ADMIN
//       // ========================================================
//
//       final admin = await _adminService.getAdmin();
//
//       if (!mounted) return;
//
//       setState(() {
//         _admin = admin;
//         _loadingUser = false;
//         _loadingAdmin = false;
//       });
//     } catch (e) {
//       debugPrint('HelpSupportScreen load error: $e');
//
//       if (!mounted) return;
//
//       setState(() {
//         _loadingUser = false;
//         _loadingAdmin = false;
//       });
//
//       _showSnackBar(
//         'Unable to load support information.',
//         isError: true,
//       );
//     }
//   }
//
//   // ==========================================================
//   // SUBMIT SUPPORT TICKET
//   // ==========================================================
//
//   Future<void> _submitSupportMessage() async {
//     // ========================================================
//     // VALIDATE FORM
//     // ========================================================
//
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//
//     // ========================================================
//     // CHECK USER
//     // ========================================================
//
//     if (_userId == null || _userId!.isEmpty) {
//       _showSnackBar(
//         'User account information is missing.',
//         isError: true,
//       );
//       return;
//     }
//
//     // ========================================================
//     // ADMIN SHOULD NOT SEND TICKET TO ADMIN
//     // ========================================================
//
//     if (_userRole == 'admin') {
//       _showSnackBar(
//         'Admin accounts cannot submit support tickets here.',
//         isError: true,
//       );
//       return;
//     }
//
//     // ========================================================
//     // CHECK ADMIN
//     // ========================================================
//
//     if (_admin == null) {
//       _showSnackBar(
//         'Admin account is currently unavailable.',
//         isError: true,
//       );
//       return;
//     }
//
//     setState(() {
//       _submitting = true;
//     });
//
//     try {
//       // ========================================================
//       // CREATE TICKET
//       // ========================================================
//
//       await _supportService.createTicket(
//         userId: _userId!,
//         userName: _userName,
//         userEmail: _userEmail,
//         userRole: _userRole,
//         adminId: _admin!.uid,
//         subject: _subjectController.text.trim(),
//         message: _messageController.text.trim(),
//       );
//
//       if (!mounted) return;
//
//       // ========================================================
//       // CLEAR FORM
//       // ========================================================
//
//       _subjectController.clear();
//       _messageController.clear();
//
//       FocusScope.of(context).unfocus();
//
//       _showSnackBar(
//         'Your support ticket has been sent to Admin.',
//       );
//     } catch (e) {
//       debugPrint('Create support ticket error: $e');
//
//       if (!mounted) return;
//
//       _showSnackBar(
//         'Failed to send support ticket.',
//         isError: true,
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _submitting = false;
//         });
//       }
//     }
//   }
//
//   // ==========================================================
//   // PHONE
//   // ==========================================================
//
//   Future<void> _makePhoneCall(String phoneNumber) async {
//     final String cleanPhone =
//     phoneNumber.replaceAll(RegExp(r'\s+'), '');
//
//     if (cleanPhone.isEmpty) {
//       _showSnackBar(
//         'Admin phone number is unavailable.',
//         isError: true,
//       );
//       return;
//     }
//
//     final Uri uri = Uri(
//       scheme: 'tel',
//       path: cleanPhone,
//     );
//
//     try {
//       final bool launched = await launchUrl(uri);
//
//       if (!launched && mounted) {
//         _showSnackBar(
//           'Could not initiate phone call.',
//           isError: true,
//         );
//       }
//     } catch (e) {
//       debugPrint('Phone call error: $e');
//
//       if (mounted) {
//         _showSnackBar(
//           'Could not initiate phone call.',
//           isError: true,
//         );
//       }
//     }
//   }
//
//   // ==========================================================
//   // EMAIL
//   // ==========================================================
//
//   Future<void> _sendEmail(String email) async {
//     if (email.trim().isEmpty) {
//       _showSnackBar(
//         'Admin email is unavailable.',
//         isError: true,
//       );
//       return;
//     }
//
//     final Uri uri = Uri(
//       scheme: 'mailto',
//       path: email.trim(),
//       queryParameters: {
//         'subject': 'Rentify Support Request',
//       },
//     );
//
//     try {
//       final bool launched = await launchUrl(uri);
//
//       if (!launched && mounted) {
//         _showSnackBar(
//           'Could not open email client.',
//           isError: true,
//         );
//       }
//     } catch (e) {
//       debugPrint('Email error: $e');
//
//       if (mounted) {
//         _showSnackBar(
//           'Could not open email client.',
//           isError: true,
//         );
//       }
//     }
//   }
//
//   // ==========================================================
//   // SNACKBAR
//   // ==========================================================
//
//   void _showSnackBar(
//       String message, {
//         bool isError = false,
//       }) {
//     if (!mounted) return;
//
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         SnackBar(
//           content: Text(message),
//           behavior: SnackBarBehavior.floating,
//           margin: const EdgeInsets.all(16),
//           backgroundColor:
//           isError
//               ? const Color(0xFFEF4444)
//               : const Color(0xFF22C55E),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       );
//   }
//
//   // ==========================================================
//   // DISPOSE
//   // ==========================================================
//
//   @override
//   void dispose() {
//     _subjectController.dispose();
//     _messageController.dispose();
//
//     super.dispose();
//   }
//
//   // ==========================================================
//   // BUILD
//   // ==========================================================
//
//   @override
//   Widget build(BuildContext context) {
//     final String? userId = _userId;
//
//     return Scaffold(
//       backgroundColor: backgroundColor,
//
//       // ========================================================
//       // APP BAR
//       // ========================================================
//
//       appBar: AppBar(
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         backgroundColor: backgroundColor,
//         foregroundColor: textColor,
//
//         title: const Text(
//           'Help & Support',
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//
//       // ========================================================
//       // BODY
//       // ========================================================
//
//       body: RefreshIndicator(
//         color: primaryColor,
//         onRefresh: _loadData,
//
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(
//             parent: BouncingScrollPhysics(),
//           ),
//
//           padding: const EdgeInsets.fromLTRB(
//             20,
//             8,
//             20,
//             40,
//           ),
//
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ==================================================
//               // HEADER
//               // ==================================================
//
//               _buildHeader(),
//
//               const SizedBox(height: 24),
//
//               // ==================================================
//               // ADMIN
//               // ==================================================
//
//               _loadingAdmin
//                   ? _buildAdminLoading()
//                   : _buildAdminCard(),
//
//               const SizedBox(height: 28),
//
//               // ==================================================
//               // QUICK CONTACT
//               // ==================================================
//
//               _buildSectionTitle(
//                 title: 'Quick Contact',
//                 subtitle:
//                 'Contact Rentify administration directly.',
//               ),
//
//               const SizedBox(height: 12),
//
//               _buildQuickContact(),
//
//               const SizedBox(height: 28),
//
//               // ==================================================
//               // SUPPORT FORM
//               // ==================================================
//
//               if (_userRole != 'admin') ...[
//                 _buildSupportForm(),
//
//                 const SizedBox(height: 28),
//               ],
//
//               // ==================================================
//               // SUPPORT TICKETS
//               // ==================================================
//
//               if (userId != null && userId.isNotEmpty)
//                 _buildTickets(userId),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ==========================================================
//   // HEADER
//   // ==========================================================
//
//   Widget _buildHeader() {
//     final String roleLabel = _getRoleLabel(_userRole);
//
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(22),
//
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [
//             primaryColor,
//             Color(0xFF8B83FF),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//
//         borderRadius: BorderRadius.circular(24),
//
//         boxShadow: [
//           BoxShadow(
//             color: primaryColor.withOpacity(0.20),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Icon
//           Container(
//             width: 48,
//             height: 48,
//
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.16),
//               borderRadius: BorderRadius.circular(14),
//             ),
//
//             child: const Icon(
//               Icons.support_agent_rounded,
//               color: Colors.white,
//               size: 27,
//             ),
//           ),
//
//           const SizedBox(height: 18),
//
//           // Title
//           const Text(
//             'How can we help?',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 25,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//
//           const SizedBox(height: 7),
//
//           // Description
//           const Text(
//             'Contact Rentify Admin for account, property, payment, or subscription support.',
//             style: TextStyle(
//               color: Colors.white70,
//               fontSize: 14,
//               height: 1.5,
//             ),
//           ),
//
//           // User role
//           if (roleLabel.isNotEmpty) ...[
//             const SizedBox(height: 16),
//
//             Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 11,
//                 vertical: 6,
//               ),
//
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.14),
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.18),
//                 ),
//               ),
//
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(
//                     Icons.person_outline_rounded,
//                     color: Colors.white,
//                     size: 15,
//                   ),
//
//                   const SizedBox(width: 6),
//
//                   Text(
//                     'Account: $roleLabel',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   // ==========================================================
//   // SECTION TITLE
//   // ==========================================================
//
//   Widget _buildSectionTitle({
//     required String title,
//     required String subtitle,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: const TextStyle(
//             color: textColor,
//             fontSize: 18,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//
//         const SizedBox(height: 4),
//
//         Text(
//           subtitle,
//           style: const TextStyle(
//             color: secondaryTextColor,
//             fontSize: 13,
//             height: 1.4,
//           ),
//         ),
//       ],
//     );
//   }
//
//   // ==========================================================
//   // ADMIN LOADING
//   // ==========================================================
//
//   Widget _buildAdminLoading() {
//     return Container(
//       height: 130,
//       width: double.infinity,
//       decoration: _cardDecoration(),
//
//       child: const Center(
//         child: CircularProgressIndicator(
//           strokeWidth: 2.5,
//           color: primaryColor,
//         ),
//       ),
//     );
//   }
//
//   // ==========================================================
//   // ADMIN CARD
//   // ==========================================================
//
//   Widget _buildAdminCard() {
//     if (_admin == null) {
//       return Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         decoration: _cardDecoration(),
//
//         child: Row(
//           children: [
//             Container(
//               width: 46,
//               height: 46,
//
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFFF7ED),
//                 borderRadius: BorderRadius.circular(14),
//               ),
//
//               child: const Icon(
//                 Icons.info_outline_rounded,
//                 color: Color(0xFFF59E0B),
//               ),
//             ),
//
//             const SizedBox(width: 14),
//
//             const Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Admin unavailable',
//                     style: TextStyle(
//                       color: textColor,
//                       fontSize: 15,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//
//                   SizedBox(height: 4),
//
//                   Text(
//                     'No active Rentify Admin account was found.',
//                     style: TextStyle(
//                       color: secondaryTextColor,
//                       fontSize: 12,
//                       height: 1.4,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: _cardDecoration(),
//
//       child: Row(
//         children: [
//           // ====================================================
//           // ADMIN AVATAR
//           // ====================================================
//
//           _buildAdminAvatar(),
//
//           const SizedBox(width: 14),
//
//           // ====================================================
//           // ADMIN INFORMATION
//           // ====================================================
//
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         _admin!.fullName.isNotEmpty
//                             ? _admin!.fullName
//                             : 'Rentify Admin',
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//
//                         style: const TextStyle(
//                           color: textColor,
//                           fontSize: 17,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(width: 8),
//
//                     _buildOnlineBadge(),
//                   ],
//                 ),
//
//                 const SizedBox(height: 5),
//
//                 const Text(
//                   'Rentify Administration',
//                   style: TextStyle(
//                     color: secondaryTextColor,
//                     fontSize: 13,
//                   ),
//                 ),
//
//                 const SizedBox(height: 5),
//
//                 if (_admin!.email.isNotEmpty)
//                   Text(
//                     _admin!.email,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//
//                     style: const TextStyle(
//                       color: Color(0xFF9CA3AF),
//                       fontSize: 12,
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==========================================================
//   // ADMIN AVATAR
//   // ==========================================================
//
//   Widget _buildAdminAvatar() {
//     final String? image = _admin!.profileImage;
//
//     return Container(
//       width: 60,
//       height: 60,
//
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//
//         gradient: const LinearGradient(
//           colors: [
//             primaryColor,
//             Color(0xFF8B83FF),
//           ],
//         ),
//       ),
//
//       child: ClipOval(
//         child: image!.isNotEmpty
//             ? Image.network(
//           image,
//           fit: BoxFit.cover,
//
//           errorBuilder: (_, __, ___) {
//             return _defaultAdminIcon();
//           },
//         )
//             : _defaultAdminIcon(),
//       ),
//     );
//   }
//
//   // ==========================================================
//   // DEFAULT ADMIN ICON
//   // ==========================================================
//
//   Widget _defaultAdminIcon() {
//     return const Icon(
//       Icons.admin_panel_settings_rounded,
//       color: Colors.white,
//       size: 32,
//     );
//   }
//
//   // ==========================================================
//   // ACTIVE BADGE
//   // ==========================================================
//
//   Widget _buildOnlineBadge() {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 8,
//         vertical: 4,
//       ),
//
//       decoration: BoxDecoration(
//         color: const Color(0xFFDCFCE7),
//         borderRadius: BorderRadius.circular(20),
//       ),
//
//       child: const Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.circle,
//             size: 7,
//             color: Color(0xFF22C55E),
//           ),
//
//           SizedBox(width: 4),
//
//           Text(
//             'Active',
//             style: TextStyle(
//               color: Color(0xFF15803D),
//               fontSize: 10,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==========================================================
//   // QUICK CONTACT
//   // ==========================================================
//
//   Widget _buildQuickContact() {
//     final UserModel? admin = _admin;
//
//     return Row(
//       children: [
//         // ======================================================
//         // CALL
//         // ======================================================
//
//         Expanded(
//           child: _buildContactCard(
//             icon: Icons.phone_rounded,
//             title: 'Call Admin',
//
//             subtitle:
//             admin?.phone.isNotEmpty == true
//                 ? admin!.phone
//                 : 'Phone unavailable',
//
//             color: const Color(0xFF22C55E),
//
//             enabled:
//             admin != null &&
//                 admin.phone.isNotEmpty,
//
//             onTap:
//             admin != null &&
//                 admin.phone.isNotEmpty
//                 ? () => _makePhoneCall(
//               admin.phone,
//             )
//                 : null,
//           ),
//         ),
//
//         const SizedBox(width: 12),
//
//         // ======================================================
//         // EMAIL
//         // ======================================================
//
//         Expanded(
//           child: _buildContactCard(
//             icon: Icons.email_rounded,
//             title: 'Email Admin',
//
//             subtitle:
//             admin?.email.isNotEmpty == true
//                 ? admin!.email
//                 : 'Email unavailable',
//
//             color: const Color(0xFF0EA5E9),
//
//             enabled:
//             admin != null &&
//                 admin.email.isNotEmpty,
//
//             onTap:
//             admin != null &&
//                 admin.email.isNotEmpty
//                 ? () => _sendEmail(
//               admin.email,
//             )
//                 : null,
//           ),
//         ),
//       ],
//     );
//   }
//
//   // ==========================================================
//   // CONTACT CARD
//   // ==========================================================
//
//   Widget _buildContactCard({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required Color color,
//     required bool enabled,
//     required VoidCallback? onTap,
//   }) {
//     return Material(
//       color: Colors.transparent,
//
//       child: InkWell(
//         onTap: enabled ? onTap : null,
//         borderRadius: BorderRadius.circular(18),
//
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: _cardDecoration(),
//
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Icon
//               Container(
//                 width: 42,
//                 height: 42,
//
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.10),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//
//                 child: Icon(
//                   icon,
//                   color:
//                   enabled
//                       ? color
//                       : const Color(0xFF9CA3AF),
//                   size: 21,
//                 ),
//               ),
//
//               const SizedBox(height: 12),
//
//               Text(
//                 title,
//                 style: const TextStyle(
//                   color: textColor,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//
//               const SizedBox(height: 4),
//
//               Text(
//                 subtitle,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//
//                 style: const TextStyle(
//                   color: Color(0xFF9CA3AF),
//                   fontSize: 11,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ==========================================================
//   // SUPPORT FORM
//   // ==========================================================
//
//   Widget _buildSupportForm() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: _cardDecoration(),
//       child: Form(
//         key: _formKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSectionTitle(
//               title: 'Contact Support',
//               subtitle: 'Send a message directly to Rentify Admin.',
//             ),
//             const SizedBox(height: 20),
//
//             // SUBJECT
//             _buildTextField(
//               controller: _subjectController,
//               label: 'Subject',
//               hint: 'Payment issue',
//               icon: Icons.title_rounded,
//               validator: (value) {
//                 if (value == null || value.trim().isEmpty) {
//                   return 'Please enter a subject';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),
//
//             // MESSAGE
//             _buildTextField(
//               controller: _messageController,
//               label: 'Message',
//               hint: 'Describe your question or issue...',
//               icon: Icons.chat_bubble_outline_rounded,
//               maxLines: 5,
//               validator: (value) {
//                 if (value == null || value.trim().isEmpty) {
//                   return 'Please enter your message';
//                 }
//                 if (value.trim().length < 5) {
//                   return 'Message is too short';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 20),
//
//             // SEND BUTTON
//             SizedBox(
//               width: double.infinity,
//               height: 52,
//               child: ElevatedButton(
//                 onPressed: _submitting ? null : _submitSupportMessage,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: primaryColor,
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                 ),
//                 child: _submitting
//                     ? const SizedBox(
//                   height: 22,
//                   width: 22,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2.5,
//                     color: Colors.white,
//                   ),
//                 )
//                     : const Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.send_rounded, size: 18),
//                     SizedBox(width: 8),
//                     Text(
//                       'Send Ticket',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ==========================================================
//   // TEXT FIELD
//   // ==========================================================
//
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required IconData icon,
//     int maxLines = 1,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       maxLines: maxLines,
//       validator: validator,
//       style: const TextStyle(color: textColor, fontSize: 14),
//       decoration: InputDecoration(
//         labelText: label,
//         hintText: hint,
//         prefixIcon: Padding(
//           padding: EdgeInsets.only(bottom: maxLines > 1 ? 80 : 0),
//           child: Icon(icon, color: secondaryTextColor, size: 20),
//         ),
//         filled: true,
//         fillColor: backgroundColor,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: borderColor),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: borderColor),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: primaryColor, width: 1.5),
//         ),
//       ),
//     );
//   }
//
//   BoxDecoration _cardDecoration() {
//     return BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(20),
//       border: Border.all(color: borderColor),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withOpacity(0.02),
//           blurRadius: 10,
//           offset: const Offset(0, 4),
//         ),
//       ],
//     );
//   }
//
//   String _getRoleLabel(String role) {
//     switch (role.toLowerCase()) {
//       case 'renter':
//         return 'Renter';
//       case 'owner':
//         return 'Property Owner';
//       case 'admin':
//         return 'Admin';
//       default:
//         return role.isNotEmpty ? role : 'User';
//     }
//   }
//
//   // ==========================================================
//   // TICKETS
//   // ==========================================================
//
//   Widget _buildTickets(String userId) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//
//       children: [
//         _buildSectionTitle(
//           title: 'My Support Tickets',
//           subtitle:
//           'Track your requests sent to Admin.',
//         ),
//
//         const SizedBox(height: 12),
//
//         StreamBuilder<List<SupportTicketModel>>(
//           stream: _supportService.userTickets(
//             userId,
//           ),
//
//           builder: (
//               context,
//               snapshot,
//               ) {
//             // ==================================================
//             // LOADING
//             // ==================================================
//
//             if (snapshot.connectionState ==
//                 ConnectionState.waiting) {
//               return Container(
//                 height: 110,
//                 decoration: _cardDecoration(),
//
//                 child: const Center(
//                   child:
//                   CircularProgressIndicator(
//                     strokeWidth: 2.5,
//                     color: primaryColor,
//                   ),
//                 ),
//               );
//             }
//
//             // ==================================================
//             // ERROR
//             // ==================================================
//
//             if (snapshot.hasError) {
//               debugPrint(
//                 'Support tickets error: ${snapshot.error}',
//               );
//
//               return _buildEmptyTicketState(
//                 icon:
//                 Icons.error_outline_rounded,
//                 title:
//                 'Unable to load tickets',
//                 subtitle:
//                 'Please try again later.',
//               );
//             }
//
//             // ==================================================
//             // DATA
//             // ==================================================
//
//             final List<SupportTicketModel> tickets =
//                 snapshot.data ?? [];
//
//             // ==================================================
//             // EMPTY
//             // ==================================================
//
//             if (tickets.isEmpty) {
//               return _buildEmptyTicketState(
//                 icon:
//                 Icons.support_agent_rounded,
//                 title:
//                 'No support tickets yet',
//                 subtitle:
//                 'Your support requests will appear here.',
//               );
//             }
//
//             // ==================================================
//             // TICKETS
//             // ==================================================
//
//             return Column(
//               children:
//               tickets.map(
//                     (ticket) {
//                   return Padding(
//                     padding:
//                     const EdgeInsets.only(
//                       bottom: 10,
//                     ),
//
//                     child:
//                     _buildTicketCard(
//                       ticket,
//                     ),
//                   );
//                 },
//               ).toList(),
//             );
//           },
//         ),
//       ],
//     );
//   }
//
//   // ==========================================================
//   // TICKET CARD
//   // ==========================================================
//
//   Widget _buildTicketCard(
//       SupportTicketModel ticket,
//       ) {
//     final Color statusColor =
//     _statusColor(ticket.status);
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: _cardDecoration(),
//
//       child: Row(
//         crossAxisAlignment:
//         CrossAxisAlignment.start,
//
//         children: [
//           // ====================================================
//           // ICON
//           // ====================================================
//
//           Container(
//             width: 42,
//             height: 42,
//
//             decoration: BoxDecoration(
//               color:
//               primaryColor.withOpacity(0.10),
//               borderRadius:
//               BorderRadius.circular(12),
//             ),
//
//             child: const Icon(
//               Icons.chat_outlined,
//               color: primaryColor,
//               size: 21,
//             ),
//           ),
//
//           const SizedBox(width: 12),
//
//           // ====================================================
//           // CONTENT
//           // ====================================================
//
//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//               CrossAxisAlignment.start,
//
//               children: [
//                 // Subject
//                 Text(
//                   ticket.subject.isNotEmpty
//                       ? ticket.subject
//                       : 'Support Request',
//
//                   maxLines: 1,
//                   overflow:
//                   TextOverflow.ellipsis,
//
//                   style: const TextStyle(
//                     color: textColor,
//                     fontSize: 14,
//                     fontWeight:
//                     FontWeight.w700,
//                   ),
//                 ),
//
//                 const SizedBox(height: 5),
//
//                 // Message
//                 Text(
//                   ticket.message,
//
//                   maxLines: 2,
//                   overflow:
//                   TextOverflow.ellipsis,
//
//                   style: const TextStyle(
//                     color: secondaryTextColor,
//                     fontSize: 12,
//                     height: 1.4,
//                   ),
//                 ),
//
//                 const SizedBox(height: 8),
//
//                 // Status + Date
//                 Row(
//                   children: [
//                     _buildStatusBadge(
//                       ticket.status,
//                       statusColor,
//                     ),
//
//                     const Spacer(),
//
//                     Text(
//                       _formatDate(
//                         ticket.createdAt,
//                       ),
//
//                       style:
//                       const TextStyle(
//                         color:
//                         Color(0xFF9CA3AF),
//                         fontSize: 10,
//                       ),
//                     ),
//                   ],
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
//   // STATUS BADGE
//   // ==========================================================
//
//   Widget _buildStatusBadge(
//       String status,
//       Color color,
//       ) {
//     return Container(
//       padding:
//       const EdgeInsets.symmetric(
//         horizontal: 8,
//         vertical: 4,
//       ),
//
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.10),
//         borderRadius:
//         BorderRadius.circular(20),
//       ),
//
//       child: Text(
//         _statusLabel(status),
//
//         style: TextStyle(
//           color: color,
//           fontSize: 10,
//           fontWeight: FontWeight.w700,
//         ),
//       ),
//     );
//   }
//
//   // ==========================================================
//   // EMPTY TICKET STATE
//   // ==========================================================
//
//   Widget _buildEmptyTicketState({
//     required IconData icon,
//     required String title,
//     String? subtitle,
//   }) {
//     return Container(
//       width: double.infinity,
//
//       padding:
//       const EdgeInsets.symmetric(
//         vertical: 28,
//         horizontal: 20,
//       ),
//
//       decoration: _cardDecoration(),
//
//       child: Column(
//         children: [
//           Container(
//             width: 52,
//             height: 52,
//
//             decoration: BoxDecoration(
//               color:
//               const Color(0xFFF3F4F6),
//               shape: BoxShape.circle,
//             ),
//
//             child: Icon(
//               icon,
//               color:
//               const Color(0xFF9CA3AF),
//               size: 27,
//             ),
//           ),
//
//           const SizedBox(height: 10),
//
//           Text(
//             title,
//
//             textAlign: TextAlign.center,
//
//             style: const TextStyle(
//               color: secondaryTextColor,
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//
//           if (subtitle != null) ...[
//             const SizedBox(height: 4),
//
//             Text(
//               subtitle,
//
//               textAlign: TextAlign.center,
//
//               style: const TextStyle(
//                 color: Color(0xFF9CA3AF),
//                 fontSize: 11,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   // ==========================================================
//   // CARD DECORATION
//   // ==========================================================
//
//   // BoxDecoration _cardDecoration() {
//   //   return BoxDecoration(
//   //     color: Colors.white,
//   //
//   //     borderRadius:
//   //     BorderRadius.circular(20),
//   //
//   //     border: Border.all(
//   //       color: borderColor,
//   //     ),
//   //
//   //     boxShadow: [
//   //       BoxShadow(
//   //         color:
//   //         Colors.black.withOpacity(0.035),
//   //         blurRadius: 18,
//   //         offset: const Offset(0, 6),
//   //       ),
//   //     ],
//   //   );
//   // }
//
//   // ==========================================================
//   // STATUS COLOR
//   // ==========================================================
//
//   Color _statusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'open':
//         return const Color(0xFF2563EB);
//
//       case 'pending':
//         return const Color(0xFFF59E0B);
//
//       case 'resolved':
//         return const Color(0xFF22C55E);
//
//       case 'closed':
//         return const Color(0xFF6B7280);
//
//       default:
//         return primaryColor;
//     }
//   }
//
//   // ==========================================================
//   // STATUS LABEL
//   // ==========================================================
//
//   String _statusLabel(String status) {
//     switch (status.toLowerCase()) {
//       case 'open':
//         return 'Open';
//
//       case 'pending':
//         return 'Pending';
//
//       case 'resolved':
//         return 'Resolved';
//
//       case 'closed':
//         return 'Closed';
//
//       default:
//         return status.isEmpty ? 'Open' : status;
//     }
//   }
//
//   // ==========================================================
//   // ROLE LABEL
//   // ==========================================================
//
//   // String _getRoleLabel(String role) {
//   //   switch (role.toLowerCase()) {
//   //     case 'owner':
//   //       return 'Property Owner';
//   //
//   //     case 'renter':
//   //       return 'Renter';
//   //
//   //     case 'admin':
//   //       return 'Administrator';
//   //
//   //     default:
//   //       return role.isEmpty
//   //           ? ''
//   //           : role[0].toUpperCase() +
//   //           role.substring(1);
//   //   }
//   // }
//
//   // ==========================================================
//   // DATE
//   // ==========================================================
//
//   String _formatDate(DateTime date) {
//     return '${date.day.toString().padLeft(2, '0')}/'
//         '${date.month.toString().padLeft(2, '0')}/'
//         '${date.year}';
//   }
// }

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/support_ticket_model.dart';
import '../../../models/user_model.dart';
import '../../../services/session_service.dart';
import '../../../services/support_service.dart';
import '../../../services/user_service.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  // ==========================================================
  // SERVICES
  // ==========================================================

  final UserService _adminService = UserService();
  final SupportService _supportService = SupportService();

  // ==========================================================
  // FORM
  // ==========================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // ==========================================================
  // OWNER STATE
  // ==========================================================

  String? _ownerId;
  String _ownerName = '';
  String _ownerEmail = '';
  String _ownerRole = 'owner';

  // ==========================================================
  // ADMIN STATE
  // ==========================================================

  UserModel? _admin;

  bool _loadingAdmin = true;
  bool _loadingOwner = true;
  bool _submitting = false;

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color backgroundColor = Color(0xFFF8F9FC);
  static const Color textColor = Color(0xFF111827);
  static const Color secondaryTextColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ==========================================================
  // LOAD OWNER + ADMIN
  // ==========================================================

  Future<void> _loadData() async {
    setState(() {
      _loadingOwner = true;
      _loadingAdmin = true;
    });

    try {
      // Load current Owner Session
      final savedUser = await SessionService.getUser();

      if (savedUser != null) {
        _ownerId = savedUser['uid']?.toString() ?? '';
        _ownerName = savedUser['fullName']?.toString() ?? '';
        _ownerEmail = savedUser['email']?.toString() ?? '';
        _ownerRole = savedUser['role']?.toString().toLowerCase() ?? 'owner';
      }

      // Load Admin Info
      final admin = await _adminService.getAdmin();

      if (!mounted) return;

      setState(() {
        _admin = admin;
        _loadingOwner = false;
        _loadingAdmin = false;
      });
    } catch (e) {
      debugPrint('HelpSupportScreen load error: $e');

      if (!mounted) return;

      setState(() {
        _loadingOwner = false;
        _loadingAdmin = false;
      });

      _showSnackBar(
        'Unable to load support information.',
        isError: true,
      );
    }
  }

  // ==========================================================
  // SUBMIT SUPPORT TICKET (OWNER -> ADMIN)
  // ==========================================================

  Future<void> _submitSupportMessage() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ownerId == null || _ownerId!.isEmpty) {
      _showSnackBar(
        'Owner account information is missing.',
        isError: true,
      );
      return;
    }

    if (_ownerRole == 'admin') {
      _showSnackBar(
        'Admin accounts cannot submit support tickets here.',
        isError: true,
      );
      return;
    }

    if (_admin == null) {
      _showSnackBar(
        'Admin account is currently unavailable.',
        isError: true,
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await _supportService.createTicket(
        userId: _ownerId!,
        userName: _ownerName,
        userEmail: _ownerEmail,
        userRole: 'owner',
        adminId: _admin!.uid,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (!mounted) return;

      _subjectController.clear();
      _messageController.clear();
      FocusScope.of(context).unfocus();

      _showSnackBar('Your support ticket has been sent to Admin.');
    } catch (e) {
      debugPrint('Create support ticket error: $e');
      if (mounted) {
        _showSnackBar('Failed to send support ticket.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  // ==========================================================
  // EXTERNAL LAUNCHERS
  // ==========================================================

  Future<void> _makePhoneCall(String phoneNumber) async {
    final String cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    if (cleanPhone.isEmpty) return;

    final Uri uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (!await launchUrl(uri) && mounted) {
        _showSnackBar('Could not initiate phone call.', isError: true);
      }
    } catch (_) {
      if (mounted) _showSnackBar('Could not initiate phone call.', isError: true);
    }
  }

  Future<void> _sendEmail(String email) async {
    if (email.trim().isEmpty) return;

    final Uri uri = Uri(
      scheme: 'mailto',
      path: email.trim(),
      queryParameters: {'subject': 'Rentify Owner Support Request'},
    );

    try {
      if (!await launchUrl(uri) && mounted) {
        _showSnackBar('Could not open email client.', isError: true);
      }
    } catch (_) {
      if (mounted) _showSnackBar('Could not open email client.', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final String? ownerId = _ownerId;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        title: const Text(
          'Owner Support',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _loadingAdmin ? _buildAdminLoading() : _buildAdminCard(),
              const SizedBox(height: 28),
              _buildSectionTitle(
                title: 'Quick Contact',
                subtitle: 'Contact Rentify administration directly.',
              ),
              const SizedBox(height: 12),
              _buildQuickContact(),
              const SizedBox(height: 28),
              if (_ownerRole != 'admin') ...[
                _buildSupportForm(),
                const SizedBox(height: 28),
              ],
              if (ownerId != null && ownerId.isNotEmpty) _buildTickets(ownerId),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER & SECTIONS
  // ==========================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, Color(0xFF8B83FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 27),
          ),
          const SizedBox(height: 18),
          const Text(
            'How can we help?',
            style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          const Text(
            'Contact Rentify Admin for property management, payment, or subscription support.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.real_estate_agent_rounded, color: Colors.white, size: 15),
                SizedBox(width: 6),
                Text(
                  'Account: Property Owner',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: secondaryTextColor, fontSize: 13, height: 1.4)),
      ],
    );
  }

  Widget _buildAdminLoading() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: _cardDecoration(),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor)),
    );
  }

  Widget _buildAdminCard() {
    if (_admin == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'No active Admin account currently available.',
                style: TextStyle(color: secondaryTextColor, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primaryColor,
            backgroundImage: (_admin?.profileImage ?? '').isNotEmpty
                ? NetworkImage(_admin!.profileImage!)
                : null,
            child: (_admin?.profileImage ?? '').isEmpty
                ? const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 30)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _admin!.fullName.isNotEmpty ? _admin!.fullName : 'Rentify Admin',
                  style: const TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(_admin!.email, style: const TextStyle(color: secondaryTextColor, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickContact() {
    final admin = _admin;
    return Row(
      children: [
        Expanded(
          child: _buildContactCard(
            icon: Icons.phone_rounded,
            title: 'Call Admin',
            subtitle: admin?.phone.isNotEmpty == true ? admin!.phone : 'Unavailable',
            color: const Color(0xFF22C55E),
            enabled: admin?.phone.isNotEmpty == true,
            onTap: () => _makePhoneCall(admin!.phone),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildContactCard(
            icon: Icons.email_rounded,
            title: 'Email Admin',
            subtitle: admin?.email.isNotEmpty == true ? admin!.email : 'Unavailable',
            color: const Color(0xFF0EA5E9),
            enabled: admin?.email.isNotEmpty == true,
            onTap: () => _sendEmail(admin!.email),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: enabled ? color : secondaryTextColor, size: 21),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: secondaryTextColor, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // FORM & INPUTS
  // ==========================================================

  Widget _buildSupportForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              title: 'Contact Support',
              subtitle: 'Send a support ticket directly to Rentify Admin.',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _subjectController,
              label: 'Subject',
              hint: 'Subscription / Listing issue',
              icon: Icons.title_rounded,
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a subject' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _messageController,
              label: 'Message',
              hint: 'Describe your issue in detail...',
              icon: Icons.chat_bubble_outline_rounded,
              maxLines: 4,
              validator: (val) => val == null || val.trim().length < 5 ? 'Message must be at least 5 characters' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitSupportMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Send Support Ticket', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: textColor, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 60 : 0),
          child: Icon(icon, color: secondaryTextColor, size: 20),
        ),
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
      ),
    );
  }

  // ==========================================================
  // TICKETS STREAM LIST (OWNER)
  // ==========================================================

  Widget _buildTickets(String ownerId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'My Support Tickets',
          subtitle: 'Track status of tickets submitted to Admin.',
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<SupportTicketModel>>(
          stream: _supportService.userTickets(ownerId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 100,
                decoration: _cardDecoration(),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)),
              );
            }

            final tickets = snapshot.data ?? [];

            if (tickets.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(),
                child: const Center(
                  child: Text(
                    'No support tickets found.',
                    style: TextStyle(color: secondaryTextColor, fontSize: 13),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return _buildTicketCard(ticket);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTicketCard(SupportTicketModel ticket) {
    final bool isOpen = ticket.status.toLowerCase() == 'open';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ticket.subject,
                  style: const TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ticket.status.toUpperCase(),
                  style: TextStyle(
                    color: isOpen ? const Color(0xFFD97706) : const Color(0xFF15803D),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ticket.message,
            style: const TextStyle(color: secondaryTextColor, fontSize: 13, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}