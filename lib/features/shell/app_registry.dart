import 'package:flutter/material.dart';

/// The apps on the phone. Order here is the home-screen order.
class PhoneApp {
  const PhoneApp({
    required this.id,
    required this.label,
    required this.icon,
    this.dock = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final bool dock;
}

const phoneApps = <PhoneApp>[
  PhoneApp(id: 'messages', label: 'Messages', icon: Icons.chat_bubble_rounded),
  PhoneApp(id: 'calls', label: 'Calls', icon: Icons.call_rounded),
  PhoneApp(id: 'gallery', label: "Wren's Library", icon: Icons.photo_library_rounded),
  PhoneApp(id: 'browser', label: 'Browser', icon: Icons.explore_rounded),
  PhoneApp(id: 'cloud', label: 'Cloud Backup', icon: Icons.cloud_sync_rounded),
  PhoneApp(id: 'notes', label: 'Notes', icon: Icons.sticky_note_2_rounded),
  PhoneApp(id: 'feed', label: 'Feed', icon: Icons.rss_feed_rounded),
  PhoneApp(id: 'board', label: 'Case Board', icon: Icons.fingerprint_rounded),
  PhoneApp(id: 'evidence', label: 'Evidence', icon: Icons.folder_special_rounded, dock: true),
  PhoneApp(id: 'journal', label: 'Journal', icon: Icons.menu_book_rounded, dock: true),
  PhoneApp(id: 'settings', label: 'Settings', icon: Icons.settings_rounded, dock: true),
];

PhoneApp appOf(String id) => phoneApps.firstWhere((a) => a.id == id);
