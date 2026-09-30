import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/constants/features.dart';
import 'data/local/hive_service.dart';
import 'services/supabase_service.dart';
import 'services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fonts ship in assets/google_fonts/ — never download them at runtime
  // (the free version has no INTERNET permission).
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in [('Inter', 'Inter'), ('Space Grotesk', 'SpaceGrotesk')]) {
      final text = await rootBundle.loadString('assets/google_fonts/$file-OFL.txt');
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });

  // Local storage is the source of truth for the UI — must be ready first.
  await HiveService.init();

  // Cloud sync is a future paid feature (AppFeatures.cloudSync). While it's
  // off, nothing below runs and the app never touches the network.
  if (AppFeatures.cloudSync) {
    await SupabaseService.init();
    await SyncService.instance.start();

    // Reconcile in the background if already logged in — never block UI.
    if (SupabaseService.isLoggedIn) {
      SyncService.instance.reconcile();
    }
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const SpendCraftApp());
}
