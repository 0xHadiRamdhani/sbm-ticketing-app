// lib/screens/shared/ticket_card.dart
// Shared widgets untuk Ticket List di semua dashboard
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/ticket_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import 'package:provider/provider.dart';
import '../technician/ticket_detail_screen.dart';
import '../requester/requester_ticket_detail_screen.dart';
import '../admin/admin_ticket_detail_screen.dart';

// ─── Category Icons ───────────────────────────────────────────────────────────
IconData categoryIcon(String category) {
  final c = category.toLowerCase();
  if (c.contains('laptop') ||
      c.contains('komputer') ||
      c.contains('it') ||
      c.contains('proyektor'))
    return Icons.laptop_outlined;
  if (c.contains('printer')) return Icons.print_outlined;
  if (c.contains('jaringan') || c.contains('wifi') || c.contains('network'))
    return Icons.wifi_outlined;
  if (c.contains('ac') ||
      c.contains('fasilitas') ||
      c.contains('kran') ||
      c.contains('toilet'))
    return Icons.build_outlined;
  return Icons.confirmation_number_outlined;
}

// ─── Status helpers ───────────────────────────────────────────────────────────
Color statusDotColor(String s) {
  switch (s.toLowerCase()) {
    case 'new':
      return const Color(0xFF6366F1); // Indigo
    case 'assigned':
      return const Color(0xFF8B5CF6); // Purple
    case 'in progress':
      return const Color(0xFF3B82F6); // Blue
    case 'pending':
      return const Color(0xFFF59E0B); // Amber
    case 'resolved':
      return const Color(0xFF10B981); // Emerald
    case 'closed':
      return const Color(0xFF1F2937); // Dark Gray
    case 're-opened':
      return const Color(0xFFEF4444); // Red
    case 'open':
      return const Color(0xFF6366F1); // Legacy
    default:
      return const Color(0xFF9E9E9E);
  }
}

String statusLabel(String s) {
  switch (s.toLowerCase()) {
    case 'new':
      return 'NEW';
    case 'assigned':
      return 'ASSIGNED';
    case 'in progress':
      return 'IN PROGRESS';
    case 'pending':
      return 'PENDING';
    case 'resolved':
      return 'RESOLVED';
    case 'closed':
      return 'CLOSED';
    case 're-opened':
      return 'RE-OPENED';
    case 'open':
      return 'NEW'; // Mapping legacy to New
    default:
      return s.toUpperCase();
  }
}

Color priorityColor(String p) {
  switch (p.toLowerCase()) {
    case 'critical':
      return const Color(0xFFEF4444); // Red
    case 'high':
      return const Color(0xFFF97316); // Orange
    case 'medium':
      return const Color(0xFFF59E0B); // Amber
    case 'low':
      return const Color(0xFF3B82F6); // Blue
    default:
      return const Color(0xFF6B7280); // Gray
  }
}

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'Baru saja';
  if (diff.inMinutes < 60) return 'Update ${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return 'Update ${diff.inHours} jam lalu';
  if (diff.inDays == 1) return 'Update 1 hari lalu';
  return 'Update ${diff.inDays} hari lalu';
}

class TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelect;

  const TicketCard({
    super.key,
    required this.ticket,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
  });

  String _formatChatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0 && now.day == dt.day) {
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } else if (diff.inDays == 1 || (diff.inDays == 0 && now.day != dt.day)) {
      return 'Kemarin';
    } else {
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year.toString().substring(2)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = c.isDark;
    final shortId = '#TKT-${ticket.ticketId.substring(0, 4).toUpperCase()}';

    // Parse title
    String displayTitle = ticket.category;
    if (ticket.description.startsWith('Judul: ')) {
      final parts = ticket.description.split('\n\nDetail:\n');
      if (parts.length == 2) {
        displayTitle = parts[0].replaceFirst('Judul: ', '').trim();
      }
    }

    // WhatsApp tick color
    final tickColor = ticket.status == 'Resolved'
        ? const Color(0xFF53BDEB)
        : c.textMuted;

    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;

    // Determine whose profile to show
    String? targetUserId;
    String defaultName = 'SBM IT Support';

    if (currentUser?.role == 'student' ||
        currentUser?.role == 'staff' ||
        currentUser?.uid == ticket.requesterId) {
      targetUserId = ticket.technicianId; // Show technician to requester
    } else {
      targetUserId = ticket.requesterId; // Show requester to technician/admin
    }

    return FutureBuilder<DocumentSnapshot?>(
      future: targetUserId != null && targetUserId.isNotEmpty
          ? FirebaseFirestore.instance
                .collection('users')
                .doc(targetUserId)
                .get()
          : Future.value(null),
      builder: (context, snapshot) {
        String contactName = defaultName;
        String? photoUrl;
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          contactName = data['name'] ?? 'Pengguna';
          photoUrl = data['photoUrl'] ?? data['profileUrl'] ?? data['avatar'];
        } else if (targetUserId != null && targetUserId.isNotEmpty) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            contactName = 'Memuat...';
          } else {
            contactName = 'Pengguna';
          }
        }

        return InkWell(
          onTap: isSelectionMode
              ? () => onSelect?.call(!isSelected)
              : () {
                  if (currentUser?.role == 'student' ||
                      currentUser?.role == 'staff' ||
                      (currentUser?.role == 'technician' &&
                          currentUser?.uid == ticket.requesterId)) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RequesterTicketDetailScreen(ticket: ticket),
                      ),
                    );
                  } else if (currentUser?.role == 'admin') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminTicketDetailScreen(ticket: ticket),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketDetailScreen(ticket: ticket),
                      ),
                    );
                  }
                },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                            ? Colors.white10
                            : Colors.black.withOpacity(0.05))
                      : Colors.transparent,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isSelectionMode) ...[
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: onSelect,
                          activeColor: const Color(0xFF00A884),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    // Avatar
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: c.primaryLight,
                      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null || photoUrl.isEmpty
                          ? (contactName == 'SBM IT Support'
                                ? Icon(
                                    Icons.support_agent_rounded,
                                    color: c.primary,
                                    size: 28,
                                  )
                                : Text(
                                    contactName.isNotEmpty
                                        ? contactName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: c.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ))
                          : null,
                    ),
                    const SizedBox(width: 14),

                    // Name and Message
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Contact Name + Short ID
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        contactName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: c.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      shortId,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: c.textSecondary.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Time - use last message time if available
                              Text(
                                _formatChatTime(
                                  ticket.lastMessageAt ?? ticket.createdAt,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  // Hijau & bold hanya jika ada pesan dari orang lain (penerima)
                                  color:
                                      (ticket.lastMessageAt != null &&
                                          ticket.lastMessageSender != null &&
                                          ticket.lastMessageSender !=
                                              currentUser?.uid)
                                      ? const Color(0xFF00A884)
                                      : c.textMuted,
                                  fontWeight:
                                      (ticket.lastMessageAt != null &&
                                          ticket.lastMessageSender != null &&
                                          ticket.lastMessageSender !=
                                              currentUser?.uid)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Ticket Title / Judul
                          Text(
                            'Judul: $displayTitle',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Detail tags row: Status Badge, Priority Badge, Category, Location
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                // Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusDotColor(
                                      ticket.status,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: statusDotColor(
                                        ticket.status,
                                      ).withOpacity(0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    statusLabel(ticket.status),
                                    style: TextStyle(
                                      color: statusDotColor(ticket.status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Priority Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: priorityColor(
                                      ticket.priority,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: priorityColor(
                                        ticket.priority,
                                      ).withOpacity(0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    ticket.priority.toUpperCase(),
                                    style: TextStyle(
                                      color: priorityColor(ticket.priority),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Category Tag
                                Icon(
                                  categoryIcon(ticket.category),
                                  size: 13,
                                  color: c.textMuted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  ticket.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: c.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (ticket.location != null &&
                                    ticket.location!.isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: c.textMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    ticket.location!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: c.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Checkmarks
                              Icon(
                                ticket.lastMessageSender != null
                                    ? (ticket.status == 'Resolved'
                                        ? Icons.done_all
                                        : Icons.check)
                                    : Icons.chat_bubble_outline_rounded,
                                size: 15,
                                color: tickColor,
                              ),
                              const SizedBox(width: 4),
                              // Message preview - show last message if available
                              Expanded(
                                child: Text(
                                  ticket.lastMessageSender != null
                                      ? (ticket.lastMessageSender == currentUser?.uid
                                          ? 'Anda: ${ticket.lastMessagePreview ?? ""}'
                                          : '$contactName: ${ticket.lastMessagePreview ?? ""}')
                                      : 'Tidak ada pesan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    // Bold hanya jika ada pesan dari orang lain (penerima)
                                    color:
                                        (ticket.lastMessageAt != null &&
                                            ticket.lastMessageSender != null &&
                                            ticket.lastMessageSender !=
                                                currentUser?.uid)
                                        ? c.textPrimary
                                        : c.textSecondary,
                                    fontWeight:
                                        (ticket.lastMessageAt != null &&
                                            ticket.lastMessageSender != null &&
                                            ticket.lastMessageSender !=
                                                currentUser?.uid)
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              // Titik hijau hanya untuk penerima (bukan pengirim pesan terakhir)
                              if (ticket.lastMessageAt != null &&
                                  ticket.lastMessageSender != null &&
                                  ticket.lastMessageSender !=
                                      currentUser?.uid) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00A884),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 80, right: 16),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class TicketInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const TicketInfoRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: c.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Requester Row (async) ────────────────────────────────────────────────────
class RequesterInfoRow extends StatelessWidget {
  final String requesterId;
  const RequesterInfoRow({super.key, required this.requesterId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(requesterId)
          .get(),
      builder: (_, snap) {
        String display = 'Memuat...';
        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() as Map<String, dynamic>;
          final name = d['name'] ?? '-';
          final role = d['role'] ?? '';
          String roleLabel = '';
          if (role == 'student')
            roleLabel = 'Mahasiswa';
          else if (role == 'staff')
            roleLabel = 'Dosen';
          else if (role == 'admin')
            roleLabel = 'Admin';
          else
            roleLabel = role;
          display = roleLabel.isNotEmpty ? '$name ($roleLabel)' : name;
        }
        return TicketInfoRow(icon: Icons.person_outline_rounded, text: display);
      },
    );
  }
}

// ─── Bottom Nav Item ──────────────────────────────────────────────────────────
class NavItem {
  final IconData icon;
  final String label;
  const NavItem({required this.icon, required this.label});
}

// ─── Dashboard Bottom Nav ─────────────────────────────────────────────────────
class DashboardBottomNav extends StatelessWidget {
  final int selected;
  final void Function(int) onTap;
  final List<NavItem> items;
  const DashboardBottomNav({
    super.key,
    required this.selected,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: c.navBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(c.isDark ? 0.3 : 0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final sel = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? c.navSelected : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      items[i].icon,
                      size: 22,
                      color: sel ? Colors.white : c.navUnselected,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: sel ? c.navSelected : c.navUnselected,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class DashboardEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const DashboardEmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: c.textMuted),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 15, color: c.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Shared AppBar ────────────────────────────────────────────────────────────
PreferredSizeWidget buildSbmAppBar({
  BuildContext? context,
  VoidCallback? onSettingsTap,
  List<Widget>? extraActions,
  bool showBackButton = false,
  VoidCallback? onBackPressed,
  String? titleText,
}) {
  return _SbmAppBar(
    context: context,
    onSettingsTap: onSettingsTap,
    extraActions: extraActions,
    showBackButton: showBackButton,
    onBackPressed: onBackPressed,
    titleText: titleText,
  );
}

class _SbmAppBar extends StatelessWidget implements PreferredSizeWidget {
  final BuildContext? externalContext;
  final VoidCallback? onSettingsTap;
  final List<Widget>? extraActions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final String? titleText;

  const _SbmAppBar({
    BuildContext? context,
    this.onSettingsTap,
    this.extraActions,
    this.showBackButton = false,
    this.onBackPressed,
    this.titleText,
  }) : externalContext = context;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppBar(
      backgroundColor: c.appBarBg,
      elevation: 0.5,
      shadowColor: c.appBarShadow,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: c.primary,
              ),
              onPressed: onBackPressed,
            )
          : null,
      titleSpacing: showBackButton ? 0 : 16,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text(
              'ITB',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            titleText ?? 'SBM ITB Support',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: c.appBarFg,
            ),
          ),
        ],
      ),
      actions: [
        if (extraActions != null) ...extraActions!,
        if (onSettingsTap != null)
          IconButton(
            icon: Icon(Icons.settings_outlined, color: c.primary, size: 24),
            tooltip: 'Pengaturan',
            onPressed: onSettingsTap,
          ),
        const SizedBox(width: 4),
      ],
    );
  }
}
