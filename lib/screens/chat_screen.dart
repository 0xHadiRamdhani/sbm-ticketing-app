import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ticket_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_notifications.dart';
import 'technician/ticket_detail_screen.dart';
import 'requester/requester_ticket_detail_screen.dart';
import 'admin/admin_ticket_detail_screen.dart';


class ChatScreen extends StatefulWidget {
  final TicketModel ticket;

  const ChatScreen({Key? key, required this.ticket}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  late String currentUserId;
  final Map<String, String> _userNames = {};
  final Map<String, String> _userRoles = {};
  final Map<String, String> _userPhotos = {};

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    currentUserId = authProvider.user?.uid ?? '';
    _fetchUsersInfo();
  }

  Future<void> _fetchUsersInfo() async {
    final ids = [widget.ticket.requesterId];
    if (widget.ticket.technicianId != null) {
      ids.add(widget.ticket.technicianId!);
    }

    for (var id in ids) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(id)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _userNames[id] = data['name'] ?? 'Pengguna';
            _userRoles[id] = data['role'] ?? '';
            _userPhotos[id] =
                data['photoUrl'] ?? data['profileUrl'] ?? data['avatar'] ?? '';
          });
        }
      } catch (e) {
        debugPrint('Error fetching user $id: $e');
      }
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _messageController.clear();
      await _chatService.sendMessage(
        widget.ticket.ticketId,
        currentUserId,
        text,
      );
    }
  }

  Future<String> _getOtherUserName() async {
    final otherUserId = widget.ticket.requesterId == currentUserId
        ? widget.ticket.technicianId
        : widget.ticket.requesterId;

    if (otherUserId == null || otherUserId.isEmpty) return 'Pengguna';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();
      if (doc.exists) {
        return doc.data()?['name'] as String? ?? 'Pengguna';
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
    }
    return 'Pengguna';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    String? targetUserId;
    String defaultName = 'SBM IT Support';

    if (currentUser?.role == 'student' ||
        currentUser?.role == 'staff' ||
        currentUser?.uid == widget.ticket.requesterId) {
      targetUserId = widget.ticket.technicianId;
    } else {
      targetUserId = widget.ticket.requesterId;
    }

    String contactName = defaultName;
    if (targetUserId != null && _userNames.containsKey(targetUserId)) {
      contactName = _userNames[targetUserId]!;
    }

    String contactRoleLabel = 'Online';
    if (targetUserId != null && _userRoles.containsKey(targetUserId)) {
      final role = _userRoles[targetUserId]!;
      if (role == 'technician')
        contactRoleLabel = 'Teknisi';
      else if (role == 'admin')
        contactRoleLabel = 'Admin';
      else if (role == 'student')
        contactRoleLabel = 'Mahasiswa';
      else if (role == 'staff')
        contactRoleLabel = 'Dosen / Staff';
    }

    String contactPhoto = '';
    if (targetUserId != null && _userPhotos.containsKey(targetUserId)) {
      contactPhoto = _userPhotos[targetUserId]!;
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.appBarBg,
        elevation: 1,
        shadowColor: c.appBarShadow,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: c.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: c.primaryLight,
              backgroundImage: contactPhoto.isNotEmpty
                  ? NetworkImage(contactPhoto)
                  : null,
              child: contactPhoto.isEmpty
                  ? (contactName == 'SBM IT Support'
                        ? Icon(
                            Icons.support_agent_rounded,
                            color: c.primary,
                            size: 22,
                          )
                        : Text(
                            contactName.isNotEmpty
                                ? contactName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 16,
                              color: c.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    contactName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: c.appBarFg,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    contactRoleLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.appBarFg.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.videocam, color: c.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(
                        Icons.videocam_off_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text('Video Call — Coming Soon! '),
                    ],
                  ),
                  backgroundColor: c.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.call, color: c.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(
                        Icons.phone_disabled_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text('Voice Call — Coming Soon! '),
                    ],
                  ),
                  backgroundColor: c.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: c.primary),
            tooltip: 'Detail Tiket',
            onPressed: () {
              if (currentUser?.role == 'student' ||
                  currentUser?.role == 'staff' ||
                  (currentUser?.role == 'technician' &&
                      currentUser?.uid == widget.ticket.requesterId)) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RequesterTicketDetailScreen(ticket: widget.ticket),
                  ),
                );
              } else if (currentUser?.role == 'admin') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AdminTicketDetailScreen(ticket: widget.ticket),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TicketDetailScreen(ticket: widget.ticket),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(widget.ticket.ticketId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: c.textPrimary),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Belum ada pesan.',
                      style: TextStyle(color: c.textMuted),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true, // Karena descending
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];

                    if (message.senderId == 'system') {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: c.isDark
                              ? const Color(0xFF2E2315)
                              : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: c.isDark
                                ? const Color(0xFF4D3715)
                                : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: c.isDark
                                  ? const Color(0xFFFBBF24)
                                  : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                message.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: c.isDark
                                      ? const Color(0xFFFDE68A)
                                      : const Color(0xFF92400E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }



                    final isMe = message.senderId == currentUserId;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    final c = AppColors.of(context);
    final senderName = _userNames[message.senderId] ?? '...';
    final senderRole = _userRoles[message.senderId] ?? '';
    final senderPhoto = _userPhotos[message.senderId] ?? '';
    final roleLabel = senderRole == 'technician'
        ? 'Teknisi'
        : (senderRole == 'admin' ? 'Admin' : '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: c.primaryLight,
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 12,
                  color: c.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      roleLabel.isNotEmpty
                          ? '$senderName ($roleLabel)'
                          : senderName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? c.primary : c.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe
                          ? const Radius.circular(16)
                          : Radius.zero,
                      bottomRight: isMe
                          ? Radius.zero
                          : const Radius.circular(16),
                    ),
                    border: isMe ? null : Border.all(color: c.border),
                    boxShadow: [
                      BoxShadow(
                        color: c.isDark
                            ? Colors.transparent
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isMe ? Colors.white : c.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : c.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: c.primaryLight,
              backgroundImage: senderPhoto.isNotEmpty
                  ? NetworkImage(senderPhoto)
                  : null,
              child: senderPhoto.isEmpty
                  ? Text(
                      senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  hintStyle: TextStyle(color: c.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: c.searchBar,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
