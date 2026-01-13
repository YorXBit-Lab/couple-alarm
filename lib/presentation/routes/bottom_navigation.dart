import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/presentation/themes/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavigationScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavigationScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _buildBottomNavBar(context),
      floatingActionButton: _buildFloatingButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildFloatingButton(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 248, 241, 236),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: const Color.fromARGB(255, 248, 241, 236),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          // Nút hồng tròn
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B9D),
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Xử lý khi nhấn nút thêm
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Thêm mới'),
                        content: const Text('Chức năng thêm mới'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Đóng'),
                          ),
                        ],
                      ),
                    );
                  },
                  customBorder: const CircleBorder(),
                  child: const Center(
                    child: Icon(Icons.add, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home, label: TransKeys.home.tr()),
      _NavItem(icon: Icons.alarm, label: TransKeys.reminder.tr()),
      _NavItem(icon: Icons.person, label: TransKeys.lover.tr()),
      _NavItem(icon: Icons.person, label: TransKeys.profile.tr()),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // First 2 items
              ...List.generate(2, (index) {
                final isSelected = index == navigationShell.currentIndex;
                return Expanded(
                  child: _buildNavItem(
                    context: context,
                    item: items[index],
                    index: index,
                    isSelected: isSelected,
                  ),
                );
              }),

              // Spacer for center button with circular notch
              Expanded(
                child: Container(
                  height: 70,
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: const SizedBox(width: 64),
                ),
              ),

              // Last 2 items
              ...List.generate(2, (index) {
                final actualIndex = index + 2;
                final isSelected = actualIndex == navigationShell.currentIndex;
                return Expanded(
                  child: _buildNavItem(
                    context: context,
                    item: items[actualIndex],
                    index: actualIndex,
                    isSelected: isSelected,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required _NavItem item,
    required int index,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      child: Container(
        height: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: isSelected ? AppColors.primary : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem({required this.icon, required this.label});
}
