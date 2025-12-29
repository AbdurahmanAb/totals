import 'dart:ui';
import 'package:flutter/material.dart';

class CustomBottomNavModern extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavModern({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {'icon': Icons.analytics_outlined, 'filledIcon': Icons.analytics, 'label': 'Analytics'},
      {'icon': Icons.account_balance_wallet_outlined, 'filledIcon': Icons.account_balance_wallet, 'label': 'Budget'},
      {'icon': Icons.home_outlined, 'filledIcon': Icons.home, 'label': 'Home'},
      {'icon': Icons.web_outlined, 'filledIcon': Icons.web, 'label': 'Web'},
      {'icon': Icons.settings_outlined, 'filledIcon': Icons.settings, 'label': 'Settings'},
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    const homeIndex = 2; // Home is in the center

    // --- Floating Pill Glassmorphism Container ---
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor.withOpacity(0.85),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 5),
                  spreadRadius: 3,
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Left side: Analytics and Budget
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (int index = 0; index < homeIndex; index++)
                            Flexible(
                              flex: currentIndex == index ? 2 : 1,
                              child: GestureDetector(
                                onTap: () => onTap(index),
                                behavior: HitTestBehavior.opaque,
                                child: _BottomNavItem(
                                  isActive: currentIndex == index,
                                  primaryColor: primaryColor,
                                  iconColor: iconColor,
                                  icon: tabs[index]['icon'] as IconData,
                                  filledIcon: tabs[index]['filledIcon'] as IconData,
                                  label: tabs[index]['label'] as String,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Center: Fixed Home button
                    GestureDetector(
                      onTap: () => onTap(homeIndex),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 64,
                        height: 64,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentIndex == homeIndex
                              ? primaryColor
                              : Theme.of(context).colorScheme.surfaceVariant,
                          boxShadow: [
                            BoxShadow(
                              color: currentIndex == homeIndex
                                  ? primaryColor.withOpacity(0.4)
                                  : Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          currentIndex == homeIndex
                              ? tabs[homeIndex]['filledIcon'] as IconData
                              : tabs[homeIndex]['icon'] as IconData,
                          size: 28,
                          color: currentIndex == homeIndex
                              ? Colors.white
                              : iconColor,
                        ),
                      ),
                    ),
                    // Right side: Web and Settings
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (int index = homeIndex + 1; index < tabs.length; index++)
                            Flexible(
                              flex: currentIndex == index ? 2 : 1,
                              child: GestureDetector(
                                onTap: () => onTap(index),
                                behavior: HitTestBehavior.opaque,
                                child: _BottomNavItem(
                                  isActive: currentIndex == index,
                                  primaryColor: primaryColor,
                                  iconColor: iconColor,
                                  icon: tabs[index]['icon'] as IconData,
                                  filledIcon: tabs[index]['filledIcon'] as IconData,
                                  label: tabs[index]['label'] as String,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final bool isActive;
  final Color primaryColor;
  final Color iconColor;
  final IconData icon;
  final IconData filledIcon;
  final String label;

  const _BottomNavItem({
    required this.isActive,
    required this.primaryColor,
    required this.iconColor,
    required this.icon,
    required this.filledIcon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    const double iconSize = 24.0;
    const Duration duration = Duration(milliseconds: 300);
    const double textSpacing = 4.0; // Reduced spacing

    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeInOutCubic,
      alignment: Alignment.center,
      height: 48,
      padding: EdgeInsets.symmetric(
        horizontal: isActive ? 12 : 4, // Reduced padding for inactive state prevents overflow
      ),
      decoration: BoxDecoration(
        color: isActive
            ? primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView( // Add scrolling to prevent crash on small overflow
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.0 : 1.0, // Keep scale simple to avoid jitter
              duration: duration,
              curve: Curves.easeInOutCubic,
              child: Icon(
                isActive ? filledIcon : icon,
                size: iconSize,
                color: isActive ? primaryColor : iconColor,
              ),
            ),
            AnimatedSize(
              duration: duration,
              curve: Curves.easeInOutCubic,
              alignment: Alignment.centerLeft,
              child: isActive
                  ? Padding(
                      padding: const EdgeInsets.only(left: textSpacing),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}