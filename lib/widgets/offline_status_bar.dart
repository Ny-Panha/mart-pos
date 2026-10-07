import 'package:flutter/material.dart';

class OfflineStatusBar extends StatefulWidget {
  const OfflineStatusBar({super.key});

  @override
  State<OfflineStatusBar> createState() => _OfflineStatusBarState();
}

class _OfflineStatusBarState extends State<OfflineStatusBar> {
  // Can be toggled or connected to connectivity stream
  bool _isOnline = true;
  int _pendingSyncCount = 0;

  @override
  Widget build(BuildContext context) {
    if (_isOnline && _pendingSyncCount == 0) {
      // Sleek subtle online bar
      return Container(
        height: 26,
        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF0284C7),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Online — Cloud Firestore Sync Active (រាល់ទិន្នន័យត្រូវបានធ្វើសមកាលកម្មរួចរាល់)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0369A1),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                setState(() {
                  _isOnline = !_isOnline;
                  _pendingSyncCount = _isOnline ? 0 : 3;
                });
              },
              child: const Text(
                'Simulate Offline Mode',
                style: TextStyle(fontSize: 10, decoration: TextDecoration.underline, color: Color(0xFF0369A1)),
              ),
            ),
          ],
        ),
      );
    }

    // Offline / Syncing banner (Orange)
    return Container(
      height: 30,
      color: Colors.amber.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            '⚠️ របៀបគ្មានអ៊ីនធឺណិត (Offline Mode) — $_pendingSyncCount វិក្កយបត្រកំពុងរង់ចាំ Sync ទៅកាន់ Cloud Firestore',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              setState(() {
                _isOnline = true;
                _pendingSyncCount = 0;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Sync Now / Online',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
