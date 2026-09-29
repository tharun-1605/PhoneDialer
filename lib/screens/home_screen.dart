import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dialpad_screen.dart';
import 'recents_screen.dart';
import 'contacts_screen.dart';
import 'call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 3; // Default to Keypad
  static const platform = MethodChannel('com.example.phone_dialer/default_dialer');
  static const callEvents = EventChannel('com.example.phone_dialer/call_events');

  bool _showIncomingCallBanner = false;
  String _incomingNumber = '';

  @override
  void initState() {
    super.initState();
    _requestDefaultDialer();
    _listenForIncomingCalls();
  }

  void _listenForIncomingCalls() {
    callEvents.receiveBroadcastStream().listen((dynamic event) async {
      if (event is Map) {
        final state = event['state'] as int?;
        final isIncoming = event['isIncoming'] as bool? ?? false;
        final number = event['number'] as String? ?? 'Unknown';

        // 2 == STATE_RINGING
        if (state == 2 && isIncoming) {
          final isLocked = await platform.invokeMethod<bool>('isDeviceLocked') ?? false;
          
          if (isLocked) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallScreen(
                    displayName: number,
                    number: number,
                    isIncoming: true,
                  ),
                ),
              );
            }
          } else {
            if (mounted) {
              setState(() {
                _showIncomingCallBanner = true;
                _incomingNumber = number;
              });
            }
          }
        } else if (state == 7) { // STATE_DISCONNECTED
          if (mounted) {
            setState(() {
              _showIncomingCallBanner = false;
            });
          }
        }
      }
    });
  }

  Future<void> _requestDefaultDialer() async {
    try {
      await platform.invokeMethod('requestDefaultDialer');
    } on PlatformException catch (e) {
      debugPrint("Failed to request default dialer: '${e.message}'.");
    }
  }

  final List<Widget> _screens = [
    const Center(child: Text("Favorites (Coming Soon)", style: TextStyle(color: Colors.white))),
    const RecentsScreen(),
    const ContactsScreen(),
    const DialpadScreen(),
    const Center(child: Text("Voicemail", style: TextStyle(color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true, // Allows body to go behind the transparent/floating navbar
      body: Stack(
        children: [
          // Background Gradient / Image for Liquid Glass look (matches iOS 17 aesthetic)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF000000),
                ],
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          
          // Floating Liquid Glass Navigation Bar
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1), // Glassmorphism color
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(Icons.star, 'Favorites', 0),
                      _buildNavItem(Icons.schedule, 'Recents', 1),
                      _buildNavItem(Icons.account_circle, 'Contacts', 2),
                      _buildNavItem(Icons.apps, 'Keypad', 3),
                      _buildNavItem(Icons.voicemail, 'Voicemail', 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          if (_showIncomingCallBanner) _buildIncomingCallBanner(),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blueAccent : Colors.white70,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : Colors.white70,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingCallBanner() {
    return Positioned(
      top: 50,
      left: 10,
      right: 10,
      child: GestureDetector(
        onTap: () {
          // Tap banner to expand to full screen CallScreen
          setState(() => _showIncomingCallBanner = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CallScreen(
                displayName: _incomingNumber,
                number: _incomingNumber,
                isIncoming: true,
              ),
            ),
          );
        },
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C), // Dark pill color matching screenshot
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade600,
                child: Text(
                  _incomingNumber.isNotEmpty ? _incomingNumber[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "iPhone", // Small text on top
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w400),
                    ),
                    Text(
                      _incomingNumber,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Buttons
              GestureDetector(
                onTap: () async {
                  setState(() => _showIncomingCallBanner = false);
                  try {
                    await platform.invokeMethod('rejectCall');
                  } catch (e) {
                    debugPrint('Reject error: $e');
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  setState(() => _showIncomingCallBanner = false);
                  try {
                    await platform.invokeMethod('answerCall');
                  } catch (e) {
                    debugPrint('Answer error: $e');
                  }
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CallScreen(
                          displayName: _incomingNumber,
                          number: _incomingNumber,
                          isIncoming: false, // Make it false to skip incoming call ringing states
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34C759),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
