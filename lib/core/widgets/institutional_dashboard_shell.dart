import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../../features/school/presentation/providers/active_school_context_provider.dart';

class DashboardNavItem {
  final String key;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const DashboardNavItem({
    required this.key,
    required this.label,
    required this.icon,
    this.onTap,
  });
}

class InstitutionalDashboardShell extends ConsumerStatefulWidget {
  final String currentRole; // 'admin' or 'teacher'
  final String activeNavKey;
  final String title;
  final Widget body;
  final List<DashboardNavItem>? customNavItems;
  final ValueChanged<String>? onNavSelected;
  final VoidCallback? onRefresh;
  final List<Widget>? headerActions;

  const InstitutionalDashboardShell({
    super.key,
    required this.currentRole,
    required this.activeNavKey,
    required this.title,
    required this.body,
    this.customNavItems,
    this.onNavSelected,
    this.onRefresh,
    this.headerActions,
  });

  @override
  ConsumerState<InstitutionalDashboardShell> createState() =>
      _InstitutionalDashboardShellState();
}

class _InstitutionalDashboardShellState
    extends ConsumerState<InstitutionalDashboardShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<DashboardNavItem> get _adminNavItems => [
        DashboardNavItem(
          key: 'overview',
          label: 'Overview',
          icon: Icons.grid_view_rounded,
          onTap: () => widget.onNavSelected?.call('overview'),
        ),
        DashboardNavItem(
          key: 'streams',
          label: 'Stream parity',
          icon: Icons.layers_outlined,
          onTap: () => widget.onNavSelected?.call('streams'),
        ),
        DashboardNavItem(
          key: 'subjects',
          label: 'Subject performance',
          icon: Icons.menu_book_outlined,
          onTap: () => widget.onNavSelected?.call('subjects'),
        ),
        DashboardNavItem(
          key: 'sections',
          label: 'Class sections',
          icon: Icons.people_outline_rounded,
          onTap: () => widget.onNavSelected?.call('sections'),
        ),
        DashboardNavItem(
          key: 'support',
          label: 'Student support',
          icon: Icons.favorite_border_rounded,
          onTap: () => widget.onNavSelected?.call('support'),
        ),
        DashboardNavItem(
          key: 'assessments',
          label: 'Assessments',
          icon: Icons.analytics_outlined,
          onTap: () => widget.onNavSelected?.call('assessments'),
        ),
        DashboardNavItem(
          key: 'staff',
          label: 'Staff & coverage',
          icon: Icons.badge_outlined,
          onTap: () => widget.onNavSelected?.call('staff'),
        ),
        DashboardNavItem(
          key: 'reports',
          label: 'Reports hub',
          icon: Icons.description_outlined,
          onTap: () {
            if (widget.onNavSelected != null) {
              widget.onNavSelected!('reports');
            } else {
              context.push('/school/reports');
            }
          },
        ),
        DashboardNavItem(
          key: 'license',
          label: 'Licensing & seats',
          icon: Icons.shield_outlined,
          onTap: () => widget.onNavSelected?.call('license'),
        ),
        DashboardNavItem(
          key: 'onboarding',
          label: 'Onboarding',
          icon: Icons.add_circle_outline_rounded,
          onTap: () => widget.onNavSelected?.call('onboarding'),
        ),
      ];

  List<DashboardNavItem> get _teacherNavItems => [
        DashboardNavItem(
          key: 'overview',
          label: 'Overview',
          icon: Icons.grid_view_rounded,
          onTap: () {
            if (widget.onNavSelected != null) {
              widget.onNavSelected!('overview');
            } else {
              context.go('/teacher');
            }
          },
        ),
        DashboardNavItem(
          key: 'class',
          label: 'Class intelligence',
          icon: Icons.insights_rounded,
          onTap: () => widget.onNavSelected?.call('class'),
        ),
        DashboardNavItem(
          key: 'attention',
          label: 'Attention queue',
          icon: Icons.favorite_border_rounded,
          onTap: () => widget.onNavSelected?.call('attention'),
        ),
        DashboardNavItem(
          key: 'roster',
          label: 'Class roster',
          icon: Icons.people_outline_rounded,
          onTap: () => widget.onNavSelected?.call('roster'),
        ),
        DashboardNavItem(
          key: 'assignments',
          label: 'Assignments',
          icon: Icons.menu_book_outlined,
          onTap: () {
            if (widget.onNavSelected != null) {
              widget.onNavSelected!('assignments');
            } else {
              context.push('/teacher/assignments');
            }
          },
        ),
        DashboardNavItem(
          key: 'interventions',
          label: 'Interventions',
          icon: Icons.format_list_bulleted_rounded,
          onTap: () {
            if (widget.onNavSelected != null) {
              widget.onNavSelected!('interventions');
            } else {
              context.push('/teacher/interventions');
            }
          },
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navItems = widget.customNavItems ??
        (widget.currentRole == 'admin' ? _adminNavItems : _teacherNavItems);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.protoBg(context),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar(context, navItems, isDesktop)),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Persistent Sidebar on Desktop
          if (isDesktop)
            SizedBox(
              width: 254,
              child: _buildSidebar(context, navItems, isDesktop),
            ),

          // 2. Main Workspace
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, isDesktop, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 35.0 : 16.0,
                      vertical: isDesktop ? 31.0 : 20.0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1600),
                        child: widget.body,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    List<DashboardNavItem> navItems,
    bool isDesktop,
  ) {
    final schoolContext = ref.watch(activeSchoolContextProvider);
    final school = schoolContext.school;
    final schoolName = school?.displayName ?? school?.name ?? 'Unity Secondary School';
    final schoolCode = school?.schoolCode ?? 'ETH-AA-042';

    return Container(
      color: AppTheme.protoNavBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Brand Logo & Title
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8C9BFF), Color(0xFF4C5EE5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66121C3F),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'F',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FidelLearn',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'INSTITUTIONAL EDITION',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFA9B7D4),
                            letterSpacing: 0.8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Navigation Section Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  widget.currentRole == 'admin'
                      ? 'SCHOOL GOVERNANCE'
                      : 'TEACHING WORKSPACE',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8192B6),
                    letterSpacing: 1.35,
                  ),
                ),
              ),

              // 3. Navigation List
              Expanded(
                child: ListView.builder(
                  itemCount: navItems.length,
                  itemBuilder: (context, index) {
                    final item = navItems[index];
                    final isActive = item.key == widget.activeNavKey;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF35447B) : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        border: isActive
                            ? const Border(
                                left: BorderSide(
                                  color: Color(0xFF8492FF),
                                  width: 3.5,
                                ),
                              )
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(11),
                          onTap: () {
                            if (!isDesktop) Navigator.of(context).pop();
                            item.onTap?.call();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 18,
                                  color: isActive ? Colors.white : const Color(0xFFBDC7DE),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                                      color: isActive ? Colors.white : const Color(0xFFBDC7DE),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 4. Workspace Section (Sync refresh & School footer)
              InkWell(
                onTap: widget.onRefresh,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: const Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 16, color: Color(0xFFBDC7DE)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Refresh sample view',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFBDC7DE),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 5. School Footer Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF24314F),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF364561)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF40547F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.school_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                schoolName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$schoolCode · 2026/27',
                                style: const TextStyle(
                                  color: Color(0xFFACBDDB),
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Illustrative institution and academic data. Real metrics from authorized synced attempts only.',
                      style: TextStyle(
                        color: Color(0xFF8B9BB8),
                        fontSize: 9,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDesktop, bool isDark) {
    final schoolContext = ref.watch(activeSchoolContextProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    final roleLabel = widget.currentRole == 'admin'
        ? 'School Administration'
        : 'Teacher Portal';

    final displayName = currentUser?.displayName ??
        (widget.currentRole == 'admin' ? 'School Administrator' : 'Teacher · Physics');

    final initials = displayName.isNotEmpty
        ? displayName.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join()
        : (widget.currentRole == 'admin' ? 'AD' : 'TG');

    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 35 : 16),
      decoration: BoxDecoration(
        color: AppTheme.protoSurface(context),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.protoLine(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Mobile Hamburger Button
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),

          // Breadcrumbs
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'FidelLearn / $roleLabel / ',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.protoMutedDark : AppTheme.protoMutedLight,
                    ),
                  ),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.protoInkDark : AppTheme.protoInkLight,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Role Switcher Segmented Control
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF233452) : const Color(0xFFEEF1F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRoleButton(
                  context,
                  label: 'School Admin',
                  isSelected: widget.currentRole == 'admin',
                  onTap: () {
                    if (widget.currentRole != 'admin') {
                      context.go('/school');
                    }
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 2),
                _buildRoleButton(
                  context,
                  label: 'Teacher',
                  isSelected: widget.currentRole == 'teacher',
                  onTap: () {
                    if (widget.currentRole != 'teacher') {
                      context.go('/teacher');
                    }
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Header Actions
          if (widget.headerActions != null) ...widget.headerActions!,

          // User Profile Pill
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: AppTheme.protoLine(context)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: isDark
                      ? const Color(0xFF2B3869)
                      : AppTheme.protoBrandLight,
                  child: Text(
                    initials.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.protoBrand,
                    ),
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF17223A),
                        ),
                      ),
                      Text(
                        schoolContext.school?.displayName ?? 'Active School',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppTheme.protoMutedDark : AppTheme.protoMutedLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF30415F) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x12101D3B),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? (isDark ? const Color(0xFFB3BFFF) : const Color(0xFF3044C7))
                : (isDark ? AppTheme.protoMutedDark : const Color(0xFF71809A)),
          ),
        ),
      ),
    );
  }
}
