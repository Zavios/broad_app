import 'package:broad_app/pages/my_rides/my_rides_page.dart';
import 'package:broad_app/pages/post/post_page.dart';
import 'package:broad_app/pages/profile/profile_page.dart';
import 'package:broad_app/pages/search/search_page.dart';
import 'package:broad_app/themes/app_theme.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 0;

  final List<BottomNavigationBarItem> items = const [
    BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Post'),
    BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
    BottomNavigationBarItem(
      icon: Icon(Icons.drive_eta_sharp),
      label: 'My rides',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  // One page per tab, in the same order as `items`.
  final List<Widget> _pages = const [
    PostPage(),
    SearchPage(),
    MyRidesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        // IndexedStack keeps each page's state when switching tabs.
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: items,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondaryText,
        backgroundColor: AppColors.background,
        elevation: 0,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
