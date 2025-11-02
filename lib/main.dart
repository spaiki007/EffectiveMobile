import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_project/riverpod/favorites_provider.dart';
import 'package:test_project/riverpod/theme_provider.dart';
import 'package:test_project/theme/app_theme.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация SharedPreferences перед запуском приложения
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Переопределяем provider с уже загруженным SharedPreferences
        sharedPreferencesProvider.overrideWithValue(
          AsyncValue.data(sharedPreferences),
        ),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MediaQuery(
      key: const ValueKey('tes_app'),
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.0),
        boldText: false,
      ),
      child: MaterialApp.router(
        title: 'Rick and Morty',
        debugShowCheckedModeBanner: false,

        // Применение тем
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,

        routerDelegate: router.routerDelegate,
        routeInformationParser: router.routeInformationParser,
        routeInformationProvider: router.routeInformationProvider,
        restorationScopeId: 'tes',
      ),
    );
  }

}
