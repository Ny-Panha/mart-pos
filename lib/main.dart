import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'firebase_options.dart';

export 'app.dart';

import 'data/services/api_service.dart';

/// Mini-Mart POS Entry Point
/// Architecture: Feature-first with Flutter Riverpod, GoRouter, Laravel REST API & MySQL
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();

  // TODO: For Android production APK build, ensure google-services.json is at:
  // android/app/google-services.json
  // TODO: For iOS release build, ensure GoogleService-Info.plist is at:
  // ios/Runner/GoogleService-Info.plist

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable Cloud Firestore Offline Persistence (works without internet)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(
    const ProviderScope(
      child: MartPosApp(),
    ),
  );
}
