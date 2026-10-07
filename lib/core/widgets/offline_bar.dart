import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class OfflineBar extends StatefulWidget {
  final int pendingSyncCount;

  const OfflineBar({
    super.key,
    this.pendingSyncCount = 0,
  });

  @override
  State<OfflineBar> createState() => _OfflineBarState();
}

class _OfflineBarState extends State<OfflineBar> {
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final isNowOnline = !results.contains(ConnectivityResult.none);
      if (mounted) {
        setState(() => _isOnline = isNowOnline);
      }
    });
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (mounted) {
        setState(() => _isOnline = !results.contains(ConnectivityResult.none));
      }
    } catch (_) {
      // Keep default online
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline && widget.pendingSyncCount == 0) {
      // Blue online bar
      return Container(
        height: 28,
        width: double.infinity,
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
              'Online — Sync Active (Cloud Firestore Connected)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0369A1),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                setState(() => _isOnline = false);
              },
              child: const Text(
                'Test Offline',
                style: TextStyle(
                  fontSize: 10,
                  decoration: TextDecoration.underline,
                  color: Color(0xFF0369A1),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Orange offline mode bar
    return Container(
      height: 32,
      width: double.infinity,
      color: Colors.amber.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '⚠️ Offline Mode — ${widget.pendingSyncCount > 0 ? "${widget.pendingSyncCount} sales pending sync to Cloud" : "Local cache active (WriteBatch offline)"}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() => _isOnline = true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Resume Online',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
