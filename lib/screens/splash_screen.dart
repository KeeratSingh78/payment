import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../config/app_config.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.5, 1.0),
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await _logoController.forward();
    await _textController.forward();
    
    // Wait for splash duration
    await Future.delayed(AppConfig.splashDuration);
    
    // Navigate to login screen
    if (mounted) {
      ref.read(navigationProvider.notifier).navigateTo('login');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F2FD),
              Colors.white,
              Color(0xFFE8F5E8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Animation
              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF3B82F6),
                            Color(0xFF10B981),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.security,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // App Name Animation
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - _textAnimation.value)),
                    child: Opacity(
                      opacity: _textAnimation.value,
                      child: const Text(
                        'SurakshaPay',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Tagline Animation
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: const Text(
                      'Secure Payments Made Simple',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 60),
              
              // Loading Animation
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLoadingDot(0),
                        const SizedBox(width: 8),
                        _buildLoadingDot(1),
                        const SizedBox(width: 8),
                        _buildLoadingDot(2),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingDot(int index) {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        final delay = index * 0.2;
        final animationValue = (_textController.value - delay).clamp(0.0, 1.0);
        
        return Transform.scale(
          scale: 0.5 + (0.5 * (1 - (animationValue * 2 - 1).abs())),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: index == 0 
                  ? const Color(0xFF3B82F6)
                  : index == 1 
                      ? const Color(0xFF10B981)
                      : const Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

