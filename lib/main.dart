import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/settings/presentation/screens/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  if (!AppConstants.hasRuntimeConfig) {
    runApp(const MissingRuntimeConfigApp());
    return;
  }

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    EasyLocalization(
      supportedLocales: AppConstants.supportedLocales,
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(
        child: UniSafeXApp(),
      ),
    ),
  );
}

class MissingRuntimeConfigApp extends StatelessWidget {
  const MissingRuntimeConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    const projectUrl = 'https://anslzankezcrxvuoidxj.supabase.co';
    const command = 'flutter run '
        '--dart-define=SUPABASE_URL=$projectUrl '
        '--dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.settings_suggest_rounded,
                      size: 42,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'UniSafeX needs Supabase config',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'The app is not broken. It is waiting for your Supabase '
                      'URL and publishable anon key. These are passed at run '
                      'time so keys are not committed to GitHub.',
                    ),
                    const SizedBox(height: 18),
                    const SelectableText(
                      command,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Find the anon key in Supabase Dashboard > Project '
                      'Settings > API > Project API keys.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UniSafeXApp extends ConsumerWidget {
  const UniSafeXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && context.locale != locale) {
        context.setLocale(locale);
      }
    });

    return MaterialApp.router(
      title: 'UniSafeX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: locale,
    );
  }
}
