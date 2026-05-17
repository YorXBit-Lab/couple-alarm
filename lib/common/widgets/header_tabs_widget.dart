import 'package:couple_note/core/common/user_tab_model.dart';
import 'package:couple_note/core/config/theme/app_colors.dart';
import 'package:couple_note/core/providers/header_tab_notifier.dart';
import 'package:couple_note/core/providers/header_tabs_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoupleAlarmHeaderTabs extends ConsumerStatefulWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onFilterTap;
  final VoidCallback? onBackTap;
  final List<Widget>? actions;
  final List<UserTab> userTabs;
  final String currentUserTab;
  final Function(String) onUserTabChanged;
  final double tabsHeight;
  final EdgeInsets margin;

  const CoupleAlarmHeaderTabs({
    Key? key,
    required this.title,
    this.subtitle,
    this.onFilterTap,
    this.onBackTap,
    this.actions,
    required this.userTabs,
    required this.currentUserTab,
    required this.onUserTabChanged,
    this.tabsHeight = 35,
    this.margin = const EdgeInsets.all(0),
  }) : super(key: key);

  @override
  ConsumerState<CoupleAlarmHeaderTabs> createState() =>
      _CoupleAlarmHeaderTabsState();
}

class _CoupleAlarmHeaderTabsState extends ConsumerState<CoupleAlarmHeaderTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late HeaderTabsConfig _config;

  @override
  void initState() {
    super.initState();
    _config = HeaderTabsConfig(
      userTabs: widget.userTabs,
      initialTab: widget.currentUserTab,
    );
    _tabController = TabController(length: widget.userTabs.length, vsync: this);
    _tabController.index = _getIndexFromUserTab(widget.currentUserTab);

    _tabController.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(CoupleAlarmHeaderTabs oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userTabs != widget.userTabs ||
        oldWidget.currentUserTab != widget.currentUserTab) {
      _config = HeaderTabsConfig(
        userTabs: widget.userTabs,
        initialTab: widget.currentUserTab,
      );
    }

    if (oldWidget.currentUserTab != widget.currentUserTab) {
      final newIndex = _getIndexFromUserTab(widget.currentUserTab);
      if (newIndex != _tabController.index) {
        _tabController.animateTo(newIndex);
      }
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final tabKey = widget.userTabs[_tabController.index].key;

      ref.read(headerTabsProvider(_config).notifier).changeUserTab(tabKey);

      widget.onUserTabChanged(tabKey);
    }
  }

  int _getIndexFromUserTab(String userTab) {
    for (int i = 0; i < widget.userTabs.length; i++) {
      if (widget.userTabs[i].key == userTab) return i;
    }
    return 0;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(headerTabsProvider(_config));

    return Container(
      margin: widget.margin,
      decoration: _buildContainerDecoration(),
      child: Column(children: [_buildHeader(), _buildTabBar(state)]),
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, Color.fromARGB(255, 250, 129, 180)],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (widget.onBackTap != null) ...[
            IconButton(
              onPressed: widget.onBackTap,
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(child: _buildHeaderTitle()),
          ..._buildHeaderActions(),
        ],
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (widget.subtitle != null)
          Text(
            widget.subtitle!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildHeaderActions() {
    final actions = <Widget>[];

    if (widget.actions != null) {
      actions.addAll(
        widget.actions!.map((action) {
          if (action is IconButton) {
            return IconButton(
              onPressed: action.onPressed,
              icon: Icon((action.icon as Icon).icon, color: Colors.white),
            );
          }
          return action;
        }),
      );
    }

    if (widget.onFilterTap != null) {
      actions.add(
        IconButton(
          onPressed: widget.onFilterTap,
          icon: const Icon(Icons.filter_list, color: Colors.white),
        ),
      );
    }

    return actions;
  }

  Widget _buildTabBar(HeaderTabsState state) {
    return Container(
      height: widget.tabsHeight,
      child: TabBar(
        controller: _tabController,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(width: 3.0, color: Colors.white),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: state.userTabs
            .map((tab) => _buildUserTab(tab, state.currentIndex))
            .toList(),
      ),
    );
  }

  Widget _buildUserTab(UserTab tab, int currentIndex) {
    final isSelected = widget.userTabs.indexOf(tab) == currentIndex;

    return Tab(
      height: widget.tabsHeight,
      child: Stack(
        children: [Center(child: _buildTabContent(tab, isSelected))],
      ),
    );
  }

  Widget _buildTabContent(UserTab tab, bool isSelected) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (tab.icon != null) ...[
          Icon(tab.icon, size: 16),
          const SizedBox(width: 4),
        ],
        Text(
          tab.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
