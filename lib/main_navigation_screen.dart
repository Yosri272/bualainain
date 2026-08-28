import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'news_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

import 'widgets/custom_bottom_nav.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();

    selectedIndex = widget.initialIndex;
  }

  void _changePage(int index) {
    if (selectedIndex == index) {
      return;
    }

    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: selectedIndex,
          children: [
            const HomeScreen(
              showBottomNav: false,
            ),

            NewsScreen(
              showBottomNav: false,
              onBackToHome: () {
                _changePage(0);
              },
            ),

            NotificationsScreen(
              showBottomNav: false,
              onBackToHome: () {
                _changePage(0);
              },
            ),

            ProfileScreen(
              showBottomNav: false,
              onBackToHome: () {
                _changePage(0);
              },
            ),
          ],
        ),

        bottomNavigationBar: CustomBottomNav(
          selectedIndex: selectedIndex,

          onTap: (index) {
            _changePage(index);
          },
        ),
      ),
    );
  }
}