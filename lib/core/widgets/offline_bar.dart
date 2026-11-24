import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class OfflineBar extends StatefulWidget {
  final int pendingSyncCount;

  final ValueChanged<bool>? onConnectivityChanged;

  const OfflineBar({
    super.key,
    this.pendingSyncCount = 0,
    this.onConnectivityChanged,
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
        _setOnline(isNowOnline);
      }
    });
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (mounted) {
        _setOnline(!results.contains(ConnectivityResult.none));
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

  void _setOnline(bool online) {
    if (online == _isOnline) return;
    setState(() => _isOnline = online);
    widget.onConnectivityChanged?.call(online);
  }

  @override
  Widget build(BuildContext context) {
    final available = _isOnline && widget.pendingSyncCount == 0;
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: available ? colors.surface : colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(
              available ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              size: 15,
              color: available ? colors.secondary : colors.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                available ? 'Online' : 'Offline · Checkout unavailable',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            InkWell(
              onTap: () => _setOnline(!available),
              child: Text(
                available ? 'Test offline' : 'Resume online',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
