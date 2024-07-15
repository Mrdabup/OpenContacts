import 'package:flutter/material.dart';
import 'package:OpenContacts/widgets/friends/friends_list.dart';
import 'package:OpenContacts/widgets/friends/friends_list_app_bar.dart';
import 'package:OpenContacts/widgets/inventory/inventory_browser.dart';
import 'package:OpenContacts/widgets/inventory/inventory_browser_app_bar.dart';
import 'package:OpenContacts/widgets/sessions/session_list.dart';
import 'package:OpenContacts/widgets/sessions/session_list_app_bar.dart';
import 'package:OpenContacts/widgets/settings_app_bar.dart';
import 'package:OpenContacts/widgets/settings_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const List<Widget> _appBars = [
    SessionListAppBar(),
    FriendsListAppBar(),
    InventoryBrowserAppBar(),
    SettingsAppBar()
  ];
  final PageController _pageController = PageController();

  int _selectedPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _appBars[_selectedPage],
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          SessionList(),
          FriendsList(),
          InventoryBrowser(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedPage,
        onDestinationSelected: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
          setState(() {
            _selectedPage = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.public),
            label: "Sessions",
          ),
          NavigationDestination(
            icon: Icon(Icons.message),
            label: "Chat",
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory),
            label: "Inventory",
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
