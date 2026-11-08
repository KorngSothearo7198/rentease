
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final UserService _adminService = UserService();
  final SupportService _supportService = SupportService();


  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();


  String? _ownerId;
  String _ownerName = '';
  String _ownerEmail = '';
  String _ownerRole = 'owner';

  UserModel? _admin;

  bool _loadingAdmin = true;
  bool _loadingOwner = true;
  bool _submitting = false;

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



  void _openTicketConversation(SupportTicketModel ticket) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _TicketConversationSheet(
          ticket: ticket,
          supportService: _supportService,
          ownerId: _ownerId ?? '',
          ownerName: _ownerName,
          onError: (message) {
            if (mounted) {
              _showSnackBar(message, isError: true);
            }
          },
        );
      },
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
    final status = ticket.status.toLowerCase();

    final Color statusColor;
    final Color statusBackground;

    switch (status) {
      case 'resolved':
      case 'closed':
        statusColor = const Color(0xFF15803D);
        statusBackground = const Color(0xFFDCFCE7);
        break;
      case 'in_progress':
        statusColor = const Color(0xFF1D4ED8);
        statusBackground = const Color(0xFFDBEAFE);
        break;
      case 'waiting_for_owner':
        statusColor = const Color(0xFF7C3AED);
        statusBackground = const Color(0xFFEDE9FE);
        break;
      default:
        statusColor = const Color(0xFFD97706);
        statusBackground = const Color(0xFFFEF3C7);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ticket.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openTicketConversation(ticket),
              icon: const Icon(Icons.forum_outlined, size: 18),
              label: const Text('View Conversation'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
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


class _TicketConversationSheet extends StatefulWidget {
  final SupportTicketModel ticket;
  final SupportService supportService;
  final String ownerId;
  final String ownerName;
  final ValueChanged<String> onError;

  const _TicketConversationSheet({
    required this.ticket,
    required this.supportService,
    required this.ownerId,
    required this.ownerName,
    required this.onError,
  });

  @override
  State<_TicketConversationSheet> createState() =>
      _TicketConversationSheetState();
}

class _TicketConversationSheetState
    extends State<_TicketConversationSheet> {
  final TextEditingController _replyController =
  TextEditingController();

  bool _sending = false;

  bool get _isClosed {
    final status = widget.ticket.status.toLowerCase();
    return status == 'closed' || status == 'resolved';
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final message = _replyController.text.trim();

    if (message.isEmpty || _sending) return;

    if (widget.ownerId.isEmpty) {
      widget.onError('Owner account information is missing.');
      return;
    }

    if (_isClosed) {
      widget.onError('This ticket is closed.');
      return;
    }

    setState(() => _sending = true);

    try {
      await widget.supportService.sendReply(
        ticketId: widget.ticket.ticketId,
        senderId: widget.ownerId,
        senderName: widget.ownerName.isEmpty
            ? 'Owner'
            : widget.ownerName,
        senderRole: 'owner',
        message: message,
      );

      if (!mounted) return;

      _replyController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint('Send support reply error: $e');

      if (mounted) {
        widget.onError('Failed to send reply. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: screenHeight * 0.78,
      child: Material(
        color: const Color(0xFFF8F9FC),
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Ticket header
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    color: Color(0xFF6C63FF),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.ticket.subject,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${widget.ticket.status.replaceAll('_', ' ').toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Conversation messages occupy the available space.
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.supportService.ticketMessages(
                  widget.ticket.ticketId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Unable to load conversation. Check your connection.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6C63FF),
                      ),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text('No messages yet.'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final item = messages[index];

                      final senderRole =
                      (item['senderRole'] ?? '')
                          .toString()
                          .toLowerCase();

                      final isOwner = senderRole == 'owner';

                      final message =
                      (item['message'] ?? '').toString();

                      final senderName =
                      (item['senderName'] ?? 'Support')
                          .toString();

                      final createdAt = item['createdAt'];
                      String timeText = '';

                      if (createdAt is Timestamp) {
                        final date = createdAt.toDate();
                        timeText =
                        '${date.day}/${date.month}/${date.year} '
                            '${date.hour.toString().padLeft(2, '0')}:'
                            '${date.minute.toString().padLeft(2, '0')}';
                      }

                      return Align(
                        alignment: isOwner
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth:
                            MediaQuery.sizeOf(context).width * 0.75,
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isOwner
                                ? const Color(0xFF6C63FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: isOwner
                                ? null
                                : Border.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isOwner ? 'You' : senderName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isOwner
                                      ? Colors.white70
                                      : const Color(0xFF6C63FF),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                message,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: isOwner
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                ),
                              ),
                              if (timeText.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  timeText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isOwner
                                        ? Colors.white70
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Reply field stays within the bottom sheet.
            if (_isClosed)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'This ticket is closed. You cannot send a reply.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              )
            else
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    14,
                    10,
                    14,
                    12 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: 'Write a reply...',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                            const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: ElevatedButton(
                          onPressed: _sending ? null : _sendReply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _sending
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.send_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
