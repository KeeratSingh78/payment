import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final settings = ref.watch(appSettingsProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B82F6),
              Color(0xFF10B981),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: _buildContent(user, settings),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              ref.read(navigationProvider.notifier).navigateTo('home');
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 28,
            ),
          ),
          const Expanded(
            child: Text(
              'Settings',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildContent(user, settings) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Profile Section
          _buildProfileSection(user),

          const SizedBox(height: 24),

          // Settings Options
          Expanded(
            child: ListView(
              children: [
                _buildSettingsSection('Voice & Language', [
                  _buildSwitchTile(
                    'Voice Commands',
                    'Enable voice recognition',
                    settings['voice_enabled'] ?? true,
                    (value) {
                      ref.read(appSettingsProvider.notifier).updateSettings(
                            userId: user.id,
                            voiceEnabled: value,
                          );
                    },
                    Icons.mic,
                  ),
                  _buildSwitchTile(
                    'Text-to-Speech',
                    'Enable voice feedback',
                    settings['tts_enabled'] ?? true,
                    (value) {
                      ref.read(appSettingsProvider.notifier).updateSettings(
                            userId: user.id,
                            ttsEnabled: value,
                          );
                    },
                    Icons.volume_up,
                  ),
                  _buildListTile(
                    'Language',
                    settings['preferred_language'] ?? 'hi-IN',
                    Icons.language,
                    () {
                      _showLanguageDialog(user);
                    },
                  ),
                ]),

                const SizedBox(height: 24),

                _buildSettingsSection('Security', [
                  _buildSwitchTile(
                    'Fraud Alerts',
                    'Get notified about suspicious activity',
                    settings['fraud_alerts_enabled'] ?? true,
                    (value) {
                      ref.read(appSettingsProvider.notifier).updateSettings(
                            userId: user.id,
                            fraudAlertsEnabled: value,
                          );
                    },
                    Icons.security,
                  ),
                  _buildListTile(
                    'Change PIN',
                    'Update your security PIN',
                    Icons.lock,
                    () {
                      _showChangePinDialog(user);
                    },
                  ),
                  _buildListTile(
                    'Trusted Contact',
                    user.trustedContact,
                    Icons.contact_phone,
                    () {
                      _showUpdateContactDialog(user);
                    },
                  ),
                ]),

                const SizedBox(height: 24),

                _buildSettingsSection('Support', [
                  _buildListTile(
                    'Help & Support',
                    'Get help with the app',
                    Icons.help,
                    () {
                      _showHelpDialog();
                    },
                  ),
                  _buildListTile(
                    'About',
                    'App version and info',
                    Icons.info,
                    () {
                      _showAboutDialog();
                    },
                  ),
                ]),

                const SizedBox(height: 24),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showSignOutDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF3B82F6),
              child: Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.phone,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Balance: ₹${user.balance.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: const Color(0xFF3B82F6)),
      activeColor: const Color(0xFF3B82F6),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      leading: Icon(icon, color: const Color(0xFF3B82F6)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLanguageDialog(user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('hi-IN', 'Hindi', user),
            _buildLanguageOption('en-US', 'English', user),
            _buildLanguageOption('bn-IN', 'Bengali', user),
            _buildLanguageOption('ta-IN', 'Tamil', user),
            _buildLanguageOption('te-IN', 'Telugu', user),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String code, String name, user) {
    return ListTile(
      title: Text(name),
      onTap: () {
        ref.read(appSettingsProvider.notifier).updateSettings(
              userId: user.id,
              preferredLanguage: code,
            );
        // Language will be set when VoiceService is used next time
        Navigator.pop(context);
      },
    );
  }

  void _showChangePinDialog(user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change PIN'),
        content: const Text('This feature will be available soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUpdateContactDialog(user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Trusted Contact'),
        content: const Text('This feature will be available soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'For help, call: 1800-123-4567\n\nOr email: support@surakshapay.com',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About SurakshaPay'),
        content: const Text(
          'SurakshaPay v1.0.0\n\nA secure payment app with voice commands and fraud detection.\n\n© 2024 SurakshaPay',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(userProvider.notifier).signOut();
              ref.read(navigationProvider.notifier).navigateTo('login');
              Navigator.pop(context);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
