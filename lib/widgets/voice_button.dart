import 'package:flutter/material.dart';

class VoiceButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isActive;
  final String? label;

  const VoiceButton({
    super.key,
    required this.onPressed,
    this.isActive = false,
    this.label,
  });

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Voice Button
        GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isActive ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: widget.isActive
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF8B5CF6),
                              Color(0xFF3B82F6),
                            ],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFE5E7EB),
                              Color(0xFFD1D5DB),
                            ],
                          ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.isActive
                            ? const Color(0xFF8B5CF6).withOpacity(0.3)
                            : Colors.black.withOpacity(0.1),
                        blurRadius: widget.isActive ? 20 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.mic,
                    size: 32,
                    color: widget.isActive
                        ? Colors.white
                        : const Color(0xFF6B7280),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Label
        Text(
          widget.label ?? (widget.isActive ? 'Listening...' : 'Tap to speak'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: widget.isActive
                ? const Color(0xFF8B5CF6)
                : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
