import 'package:colette/app/colette_app.dart';
import 'package:colette/core/firebase/anonymous_auth.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/household/data/prefs_household_local_store.dart';
import 'package:colette/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ensureAnonymousSession(FirebaseAuth.instance);
  await initializeDateFormatting('fr');
  final prefs = await SharedPreferences.getInstance();
  await PrefsHouseholdLocalStore.ensureDeviceId(prefs, const UuidIdGenerator());
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ColetteApp(),
    ),
  );
}
