import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_colors.dart';

// ── Breakpoints ───────────────────────────────────────────────────────────────
// ≥ 900 → full sidebar (desktop)
// 600–899 → collapsible drawer + top AppBar (tablet)
// < 600 → bottom navigation bar (mobile)

const double kDesktopBreak = 900;
const double kTabletBreak = 600;

// ── Nav items (role-aware) ────────────────────────────────────────────────────
class WebNavItem {
  final IconData icon;
  final IconData iconActive;
  final String label;
  const WebNavItem({
    required this.icon,
    required this.iconActive,
    required this.label,
  });
}

List<WebNavItem> getNavItemsForRole(String role) {
  switch (role) {
    case 'admin':
      return const [
        WebNavItem(
          icon: Icons.dashboard_outlined,
          iconActive: Icons.dashboard_rounded,
          label: 'Dashboard',
        ),
        WebNavItem(
          icon: Icons.confirmation_number_outlined,
          iconActive: Icons.confirmation_number_rounded,
          label: 'Tiket',
        ),
        WebNavItem(
          icon: Icons.bar_chart_outlined,
          iconActive: Icons.bar_chart_rounded,
          label: 'Statistik',
        ),
        WebNavItem(
          icon: Icons.people_outline_rounded,
          iconActive: Icons.people_rounded,
          label: 'Pengguna',
        ),
      ];
    case 'technician':
      return const [
        WebNavItem(
          icon: Icons.dashboard_outlined,
          iconActive: Icons.dashboard_rounded,
          label: 'Dashboard',
        ),
        WebNavItem(
          icon: Icons.assignment_outlined,
          iconActive: Icons.assignment_rounded,
          label: 'Tiket Saya',
        ),
        WebNavItem(
          icon: Icons.bar_chart_outlined,
          iconActive: Icons.bar_chart_rounded,
          label: 'Statistik',
        ),
      ];
    case 'student':
    case 'staff':
    default:
      return const [
        WebNavItem(
          icon: Icons.dashboard_outlined,
          iconActive: Icons.dashboard_rounded,
          label: 'Dashboard',
        ),
        WebNavItem(
          icon: Icons.confirmation_number_outlined,
          iconActive: Icons.confirmation_number_rounded,
          label: 'Tiket Saya',
        ),
        WebNavItem(
          icon: Icons.bar_chart_outlined,
          iconActive: Icons.bar_chart_rounded,
          label: 'Laporan',
        ),
      ];
  }
}

// ── Public layout shell ───────────────────────────────────────────────────────
class WebLayout extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavSelected;
  final Widget child;

  const WebLayout({
    Key? key,
    required this.selectedIndex,
    required this.onNavSelected,
    required this.child,
  }) : super(key: key);

  @override
  State<WebLayout> createState() => _WebLayoutState();
}

class _WebLayoutState extends State<WebLayout> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final role = context.watch<AuthProvider>().user?.role ?? 'student';

    if (width >= kDesktopBreak) {
      return _DesktopLayout(
        selectedIndex: widget.selectedIndex,
        onNavSelected: widget.onNavSelected,
        collapsed: _sidebarCollapsed,
        onToggleCollapse: () =>
            setState(() => _sidebarCollapsed = !_sidebarCollapsed),
        role: role,
        child: widget.child,
      );
    } else if (width >= kTabletBreak) {
      return _TabletLayout(
        selectedIndex: widget.selectedIndex,
        onNavSelected: widget.onNavSelected,
        role: role,
        child: widget.child,
      );
    } else {
      return _MobileLayout(
        selectedIndex: widget.selectedIndex,
        onNavSelected: widget.onNavSelected,
        role: role,
        child: widget.child,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DESKTOP LAYOUT  (≥ 900px) — persistent sidebar
// ─────────────────────────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavSelected;
  final bool collapsed;
  final VoidCallback onToggleCollapse;
  final String role;
  final Widget child;

  const _DesktopLayout({
    required this.selectedIndex,
    required this.onNavSelected,
    required this.collapsed,
    required this.onToggleCollapse,
    required this.role,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final navItems = getNavItemsForRole(role);
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: c.background,
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: collapsed ? 68 : 220,
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(right: BorderSide(color: c.border)),
            ),
            child: Column(
              children: [
                // Logo/Header
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.confirmation_num_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      if (!collapsed) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'SBM Support',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Divider(height: 1, color: c.divider),

                // Nav Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: navItems.length,
                    itemBuilder: (ctx, i) {
                      final item = navItems[i];
                      final selected = i == selectedIndex;
                      return _SidebarNavTile(
                        icon: selected ? item.iconActive : item.icon,
                        label: item.label,
                        selected: selected,
                        collapsed: collapsed,
                        onTap: () => onNavSelected(i),
                      );
                    },
                  ),
                ),

                // Bottom section
                Divider(height: 1, color: c.divider),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _SidebarUserTile(
                    name: user?.name ?? 'User',
                    email: user?.email ?? '',
                    collapsed: collapsed,
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border(bottom: BorderSide(color: c.border)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          collapsed
                              ? Icons.menu_open_rounded
                              : Icons.menu_rounded,
                          color: c.textPrimary,
                        ),
                        onPressed: onToggleCollapse,
                      ),
                      const Spacer(),
                      // Theme toggle
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          return IconButton(
                            icon: Icon(
                              themeProvider.isDarkMode
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              color: c.textSecondary,
                            ),
                            onPressed: () =>
                                themeProvider.toggleTheme(!themeProvider.isDarkMode),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // User menu
                      PopupMenuButton(
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: c.primaryLight,
                          child: Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: c.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            child: const Text('Pengaturan'),
                            onTap: () {
                              // TODO: Navigate to settings
                            },
                          ),
                          PopupMenuItem(
                            child: const Text('Keluar'),
                            onTap: () {
                              context.read<AuthProvider>().logout();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Page content
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TABLET LAYOUT  (600-899px) — drawer + AppBar
// ─────────────────────────────────────────────────────────────────────────────
class _TabletLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavSelected;
  final String role;
  final Widget child;

  const _TabletLayout({
    required this.selectedIndex,
    required this.onNavSelected,
    required this.role,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final navItems = getNavItemsForRole(role);
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        title: Text(
          'SBM Support',
          style: TextStyle(
            color: c.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: c.textSecondary,
                ),
                onPressed: () =>
                    themeProvider.toggleTheme(!themeProvider.isDarkMode),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: c.primary),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 24,
                        color: c.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: navItems.length,
                itemBuilder: (ctx, i) {
                  final item = navItems[i];
                  final selected = i == selectedIndex;
                  return ListTile(
                    leading: Icon(
                      selected ? item.iconActive : item.icon,
                      color: selected ? c.primary : c.textSecondary,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: selected ? c.primary : c.textPrimary,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onNavSelected(i);
                    },
                  );
                },
              ),
            ),
            Divider(height: 1, color: c.divider),
            ListTile(
              leading: Icon(Icons.logout, color: c.textSecondary),
              title: Text('Keluar', style: TextStyle(color: c.textPrimary)),
              onTap: () => context.read<AuthProvider>().logout(),
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MOBILE LAYOUT  (<600px) — bottom navigation bar
// ─────────────────────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavSelected;
  final String role;
  final Widget child;

  const _MobileLayout({
    required this.selectedIndex,
    required this.onNavSelected,
    required this.role,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final navItems = getNavItemsForRole(role);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        title: Text(
          'SBM Support',
          style: TextStyle(
            color: c.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (ctx) => [
              PopupMenuItem(
                child: const Text('Pengaturan'),
                onTap: () {
                  // TODO: Navigate to settings
                },
              ),
              PopupMenuItem(
                child: const Text('Keluar'),
                onTap: () {
                  context.read<AuthProvider>().logout();
                },
              ),
            ],
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onNavSelected,
        selectedItemColor: c.primary,
        unselectedItemColor: c.textSecondary,
        backgroundColor: c.surface,
        type: BottomNavigationBarType.fixed,
        items: navItems
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.iconActive),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SidebarNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? c.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? c.primary : c.textSecondary,
                  size: 22,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                        color: selected ? c.primary : c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarUserTile extends StatelessWidget {
  final String name;
  final String email;
  final bool collapsed;

  const _SidebarUserTile({
    required this.name,
    required this.email,
    required this.collapsed,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: collapsed
          ? Center(
              child: CircleAvatar(
                radius: 16,
                backgroundColor: c.primaryLight,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 14,
                    color: c.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: c.primaryLight,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 14,
                      color: c.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 11,
                            color: c.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
