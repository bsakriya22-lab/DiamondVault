import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';
import 'inventory_list_screen.dart';
import 'price_calculator_screen.dart';
import 'parties_screen.dart';
import 'on_demand_price_screen.dart';
import 'user_menu_screen.dart';

class MainNavigationWrapper extends StatefulWidget {
  final int initialIndex;

  const MainNavigationWrapper({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late int _currentIndex;
  bool _isEmailVerified = false;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const InventoryListScreen(),
    const PriceCalculatorScreen(),
    const OnDemandPriceScreen(),
    const PartiesScreen(),
    const UserMenuScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkEmailVerification();
  }

  Future<void> _checkEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload(); // Refresh user data
      setState(() {
        _isEmailVerified = user.emailVerified;
      });
    }
  }

  void _onTabTapped(int index) {
    if (!_isEmailVerified && index != 5) {
      // Only allow menu (index 5) for unverified users
      _showVerificationDialog();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Email Verification Required',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Please verify your email address to access all features. Check your email for the verification link.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.currentUser
                    ?.sendEmailVerification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification email sent!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to send verification email.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A1A2E),
            ),
            child: const Text('Send Verification'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !_isEmailVerified
          ? AppBar(
              backgroundColor: Colors.orange,
              title: const Text('Email Verification Required',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _checkEmailVerification();
                    if (_isEmailVerified && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Email verified! All features now available.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Check Status',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            )
          : null,
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor:
            Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        selectedItemColor:
            Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: _isEmailVerified
            ? Theme.of(context).bottomNavigationBarTheme.unselectedItemColor
            : Theme.of(context)
                .bottomNavigationBarTheme
                .unselectedItemColor
                ?.withOpacity(0.4),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
              color: !_isEmailVerified ? Colors.white24 : null,
            ),
            activeIcon: Icon(
              Icons.home_filled,
              color: !_isEmailVerified ? Colors.white24 : null,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.shopping_bag_outlined,
              color: !_isEmailVerified ? Colors.white24 : null,
            ),
            activeIcon: Icon(
              Icons.shopping_bag,
              color: !_isEmailVerified ? Colors.white24 : null,
            ),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.calculate_outlined,
              color: !_isEmailVerified ? Colors.white24 : null,
            ),
            activeIcon: Icon(
              Icons.calculate,
              color: !_isEmailVerified ? Colors.white24 : null,
            ),
            label: 'Calculator',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.flash_on_outlined,
              color: !_isEmailVerified ? Colors.white24 : null,
            ),
            activeIcon: Icon(
              Icons.flash_on,
              color: !_isEmailVerified ? Colors.white24 : null,
            ),
            label: 'On-demand',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.people_outline,
              color: !_isEmailVerified ? Colors.white24 : null,
            ),
            activeIcon: Icon(
              Icons.people,
              color: !_isEmailVerified ? Colors.white24 : null,
            ),
            label: 'Parties',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.menu_outlined),
            activeIcon: Icon(Icons.menu),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}
