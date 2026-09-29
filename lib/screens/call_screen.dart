import 'dart:async';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class CallScreen extends StatefulWidget {
  final String displayName;
  final String number;
  final bool isIncoming;
  final Uint8List? photoThumbnail;

  const CallScreen({
    Key? key,
    required this.displayName,
    required this.number,
    this.isIncoming = false,
    this.photoThumbnail,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isHold = false;
  bool _showKeypad = false;
  String _callStatus = '';
  static const platform = MethodChannel('com.example.phone_dialer/default_dialer');
  static const callEvents = EventChannel('com.example.phone_dialer/call_events');
  StreamSubscription? _callSubscription;

  bool _isLocked = false;
  
  @override
  void initState() {
    super.initState();
    _callStatus = widget.isIncoming ? 'incoming call' : 'calling...';
    if (!widget.isIncoming) {
      _initiateRealCall();
    } else {
      _checkDeviceLockState();
    }
    _listenForCallEvents();
  }

  Future<void> _checkDeviceLockState() async {
    try {
      final locked = await platform.invokeMethod<bool>('isDeviceLocked');
      if (mounted) {
        setState(() {
          _isLocked = locked ?? false;
        });
      }
    } catch (e) {
      debugPrint('Could not check lock state: $e');
    }
  }

  void _listenForCallEvents() {
    _callSubscription = callEvents.receiveBroadcastStream().listen((dynamic event) {
      if (event is Map) {
        final state = event['state'] as int?;
        if (state == 7) { // 7 == STATE_DISCONNECTED
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initiateRealCall() async {
    final status = await Permission.phone.request();
    if (status.isGranted) {
      try {
        await platform.invokeMethod('makeCall', {'number': widget.number});
      } on PlatformException catch (e) {
        debugPrint("Error making call: ${e.message}");
      }
    } else {
      setState(() {
        _callStatus = 'Call failed: No Permission';
      });
    }
  }

  Future<void> _acceptCall() async {
    try {
      await platform.invokeMethod('answerCall');
    } catch (e) {
      debugPrint("Error answering: $e");
    }
    setState(() {
      _callStatus = '00:00'; // Mock timer
      _isLocked = false; // Transition to normal in-call UI
    });
  }

  Future<void> _endCall() async {
    try {
      await platform.invokeMethod(widget.isIncoming ? 'rejectCall' : 'disconnectCall');
    } catch (e) {
      debugPrint("Error ending: $e");
    }
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Widget _buildGlassButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? overrideColor,
    Color? iconColor,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: overrideColor ?? (isActive 
                      ? Colors.white
                      : Colors.white.withOpacity(0.15)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? (isActive ? Colors.black : Colors.white),
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveCallControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildGlassButton(
              icon: Icons.volume_up, 
              label: 'Audio', 
              onTap: () async {
                final newSpeaker = !_isSpeaker;
                setState(() => _isSpeaker = newSpeaker);
                await platform.invokeMethod('setSpeaker', {'isSpeaker': newSpeaker});
              }, 
              isActive: _isSpeaker
            ),
            _buildGlassButton(
              icon: Icons.videocam, 
              label: 'FaceTime', 
              onTap: () {}
            ),
            _buildGlassButton(
              icon: Icons.mic_off, 
              label: 'Mute', 
              onTap: () async {
                final newMuted = !_isMuted;
                setState(() => _isMuted = newMuted);
                await platform.invokeMethod('setMute', {'isMuted': newMuted});
              }, 
              isActive: _isMuted
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildGlassButton(
              icon: Icons.person_add, 
              label: 'Add', 
              onTap: () {}
            ),
            _buildGlassButton(
              icon: Icons.apps, 
              label: 'Keypad', 
              onTap: () => setState(() => _showKeypad = true),
            ),
            _buildGlassButton(
              icon: Icons.call_end, 
              label: 'End', 
              onTap: _endCall,
              overrideColor: const Color(0xFFFF3B30),
              iconColor: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildIncomingCallControls() {
    if (_isLocked) {
      return _buildSlideToAnswer();
    } else {
      return _buildTwoButtonIncoming();
    }
  }

  double _dragPosition = 0.0;
  
  Widget _buildSlideToAnswer() {
    final double containerWidth = MediaQuery.of(context).size.width * 0.8;
    const double containerHeight = 80.0;
    const double buttonSize = 70.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.1),
          child: Align(
            alignment: Alignment.centerRight,
            child: Column(
              children: [
                const Icon(Icons.alarm, color: Colors.white, size: 24),
                const SizedBox(height: 6),
                const Text("Remind Me", style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        Container(
          width: containerWidth,
          height: containerHeight,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Stack(
            children: [
              const Center(
                child: Text(
                  "slide to answer",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Positioned(
                left: _dragPosition,
                top: 5,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _dragPosition += details.delta.dx;
                      if (_dragPosition < 0) _dragPosition = 0;
                      if (_dragPosition > containerWidth - buttonSize - 10) {
                        _dragPosition = containerWidth - buttonSize - 10;
                      }
                    });
                  },
                  onPanEnd: (details) {
                    if (_dragPosition > (containerWidth - buttonSize) * 0.75) {
                      setState(() {
                        _dragPosition = containerWidth - buttonSize - 10;
                      });
                      _acceptCall();
                    } else {
                      // Snap back
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone, color: Colors.green, size: 36),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildTwoButtonIncoming() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildGlassButton(
              icon: Icons.alarm, 
              label: 'Remind Me', 
              onTap: () {}
            ),
            const SizedBox(width: 50),
            _buildGlassButton(
              icon: Icons.chat_bubble, 
              label: 'Message', 
              onTap: () {}
            ),
          ],
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Decline
            Column(
              children: [
                GestureDetector(
                  onTap: _endCall,
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: 8),
                const Text("Decline", style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
            const SizedBox(width: 50),
            // Accept
            Column(
              children: [
                GestureDetector(
                  onTap: _acceptCall,
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: const BoxDecoration(
                      color: Color(0xFF34C759),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call, color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: 8),
                const Text("Accept", style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildKeypad() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 1; i <= 9; i++) _buildKeypadButton(i.toString()),
            _buildKeypadButton('*'),
            _buildKeypadButton('0'),
            _buildKeypadButton('#'),
          ],
        ),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: () => setState(() => _showKeypad = false),
          child: const Text("Hide", style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildKeypadButton(String label) {
    return GestureDetector(
      onTap: () {
        platform.invokeMethod('playDtmfTone', {'digit': label});
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w400),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCallActive = _callStatus != 'incoming call' && _callStatus != 'calling...';

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image (Contact Poster) or Gradient
          if (widget.photoThumbnail != null)
            Positioned.fill(
              child: Image.memory(
                widget.photoThumbnail!,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.3), // Darken the image slightly so text is legible
                colorBlendMode: BlendMode.darken,
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF5A5D61), // Lighter grey at top
                    Color(0xFF2C2D31), // Darker grey at bottom
                  ],
                ),
              ),
            ),
          
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Status (e.g., "mobile" or "00:03")
                Text(
                  _callStatus == 'incoming call' ? 'mobile' : _callStatus,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                
                const SizedBox(height: 5),

                // Caller Name
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          widget.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(Icons.info_outline, color: Colors.white70, size: 24),
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Dynamic Bottom Controls
                if (_showKeypad)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: _buildKeypad(),
                  )
                else if (isCallActive || !widget.isIncoming)
                  _buildActiveCallControls()
                else
                  _buildIncomingCallControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
