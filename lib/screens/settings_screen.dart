import 'dart:io';

import 'package:Higa/models/user.dart';
import 'package:Higa/screens/services/database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEffectsEnabled = false;
  bool _autoplayEnabled = true;
  bool _dailyReminderEnabled = false;
  bool _offlineModeEnabled = false;
  
  // Enhanced notification settings
  bool _dailyWordNotification = true;
  bool _streakReminderNotification = true;
  bool _achievementNotification = true;
  bool _bookmarkReminderNotification = false;
  TimeOfDay _dailyReminderTime = const TimeOfDay(hour: 9, minute: 0);

  ImageProvider _getAvatarImage(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const AssetImage('assets/sagiri.jpg'); // Default avatar
    }
    if (avatarUrl.startsWith('assets/')) {
      return AssetImage(avatarUrl);
    } else {
      return FileImage(File(avatarUrl));
    }
  }

  @override
  void initState() {
    super.initState();
    // Load user data first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = Provider.of<UserData?>(context);
      setState(() {
        _soundEffectsEnabled = userData?.soundEffectsEnabled ?? false;
      });
    });
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyWordNotification = prefs.getBool('daily_word_notification') ?? true;
      _streakReminderNotification = prefs.getBool('streak_reminder_notification') ?? true;
      _achievementNotification = prefs.getBool('achievement_notification') ?? true;
      _bookmarkReminderNotification = prefs.getBool('bookmark_reminder_notification') ?? false;
      _dailyReminderEnabled = prefs.getBool('daily_reminder_enabled') ?? false;
      
      final hour = prefs.getInt('daily_reminder_hour') ?? 9;
      final minute = prefs.getInt('daily_reminder_minute') ?? 0;
      _dailyReminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_word_notification', _dailyWordNotification);
    await prefs.setBool('streak_reminder_notification', _streakReminderNotification);
    await prefs.setBool('achievement_notification', _achievementNotification);
    await prefs.setBool('bookmark_reminder_notification', _bookmarkReminderNotification);
    await prefs.setBool('daily_reminder_enabled', _dailyReminderEnabled);
    await prefs.setInt('daily_reminder_hour', _dailyReminderTime.hour);
    await prefs.setInt('daily_reminder_minute', _dailyReminderTime.minute);
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNotificationSettingsSheet(),
    );
  }

  Widget _buildNotificationSettingsSheet() {
    final theme = Theme.of(context);
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) => Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      const Text(
                        'Notification Settings',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildNotificationSection(
                        'Daily Learning',
                        [
                          SwitchListTile(
                            title: const Text('Word of the Day'),
                            subtitle: const Text('Get daily Higaonon words'),
                            value: _dailyWordNotification,
                            onChanged: (value) {
                              setState(() => _dailyWordNotification = value);
                              setModalState(() {});
                              _saveNotificationSettings();
                            },
                            secondary: const Icon(Icons.today_rounded),
                          ),
                          SwitchListTile(
                            title: const Text('Practice Reminder'),
                            subtitle: const Text('Daily practice notifications'),
                            value: _dailyReminderEnabled,
                            onChanged: (value) {
                              setState(() => _dailyReminderEnabled = value);
                              setModalState(() {});
                              _saveNotificationSettings();
                            },
                            secondary: const Icon(Icons.schedule_rounded),
                          ),
                          ListTile(
                            enabled: _dailyReminderEnabled,
                            leading: const Icon(Icons.access_time_rounded),
                            title: const Text('Reminder Time'),
                            subtitle: Text(_dailyReminderTime.format(context)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _dailyReminderTime,
                              );
                              if (time != null) {
                                setState(() => _dailyReminderTime = time);
                                setModalState(() {});
                                _saveNotificationSettings();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildNotificationSection(
                        'Achievements',
                        [
                          SwitchListTile(
                            title: const Text('Learning Streaks'),
                            subtitle: const Text('Notify about streak milestones'),
                            value: _streakReminderNotification,
                            onChanged: (value) {
                              setState(() => _streakReminderNotification = value);
                              setModalState(() {});
                              _saveNotificationSettings();
                            },
                            secondary: const Icon(Icons.local_fire_department_rounded),
                          ),
                          SwitchListTile(
                            title: const Text('Achievements'),
                            subtitle: const Text('Celebrate your progress'),
                            value: _achievementNotification,
                            onChanged: (value) {
                              setState(() => _achievementNotification = value);
                              setModalState(() {});
                              _saveNotificationSettings();
                            },
                            secondary: const Icon(Icons.emoji_events_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildNotificationSection(
                        'Reminders',
                        [
                          SwitchListTile(
                            title: const Text('Bookmark Review'),
                            subtitle: const Text('Remind to review saved words'),
                            value: _bookmarkReminderNotification,
                            onChanged: (value) {
                              setState(() => _bookmarkReminderNotification = value);
                              setModalState(() {});
                              _saveNotificationSettings();
                            },
                            secondary: const Icon(Icons.bookmark_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);
    final userData = Provider.of<UserData?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _getAvatarImage(userData?.avatarUrl),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  userData?.name ?? 'User',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'General',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const Divider(),
              ListTile(
                title: const Text('Notifications'),
                subtitle: Text(_notificationsEnabled ? 'Customize notifications' : 'All notifications disabled'),
                leading: const Icon(Icons.notifications_outlined),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: _notificationsEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        if (value) {
                          _showNotificationSettings();
                        }
                      },
                    ),
                    if (_notificationsEnabled) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ],
                ),
                onTap: _notificationsEnabled ? _showNotificationSettings : null,
              ),
              ListTile(
                title: const Text('Sound Effect'),
                subtitle: Text(_soundEffectsEnabled ? 'Audio feedback enabled' : 'Audio feedback disabled'),
                leading: const Icon(Icons.volume_up_outlined),
                trailing: Switch(
                  value: _soundEffectsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _soundEffectsEnabled = value;
                    });
                    if (user != null) {
                      DatabaseService(uid: user.uid).updateSoundEffects(value);
                    }
                  },
                ),
              ),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme'),
                value: userData?.isDarkMode ?? false,
                onChanged: (value) {
                  if (user != null) {
                    DatabaseService(uid: user.uid).updateTheme(value);
                  }
                },
                secondary: const Icon(Icons.dark_mode_outlined),
              ),
              const SizedBox(height: 30),
              const Text(
                'Learning',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Autoplay'),
                subtitle: const Text('Automatically play pronunciations'),
                value: _autoplayEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _autoplayEnabled = value;
                  });
                },
                secondary: const Icon(Icons.play_circle_outline),
              ),
              SwitchListTile(
                title: const Text('Daily Reminder'),
                subtitle: const Text('Remind me to practice'),
                value: _dailyReminderEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _dailyReminderEnabled = value;
                  });
                },
                secondary: const Icon(Icons.notifications_active_outlined),
              ),
              SwitchListTile(
                title: const Text('Offline Mode'),
                subtitle: const Text('Download content for offline use'),
                value: _offlineModeEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _offlineModeEnabled = value;
                  });
                },
                secondary: const Icon(Icons.download_outlined),
              ),
              const SizedBox(height: 30),
              const Text(
                'Other',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('Language'),
                subtitle: const Text('English'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Implement language selection
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy'),
                subtitle: const Text('Manage your data'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Implement privacy screen navigation
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                subtitle: const Text('Get help and FAQs'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Implement help screen navigation
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Clear Cache'),
                subtitle: const Text('Free up storage space'),
                onTap: () {
                  // TODO: Implement clear cache functionality
                },
              ),
              const SizedBox(height: 40),
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement reset to default settings
                  },
                  child: const Text(
                    'Reset to Default Settings',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

