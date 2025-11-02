import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/wrap.dart';
import 'screens/home.dart';
import 'screens/favorites_screen.dart';
import 'screens/character_detail_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
        return MainScreen(navigationShell: navigationShell);
      },
      branches: [
        // Главная - список персонажей
        StatefulShellBranch(
          initialLocation: "/",
          routes: [
            GoRoute(
              path: "/",
              builder: (context, state) {
                return const HomeScreen();
              },
              routes: [
                // Детальная страница персонажа
                GoRoute(
                  path: 'character/:id',
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return CharacterDetailScreen(characterId: id);
                  },
                ),
              ],
            ),
          ],
        ),

        // Избранное
        StatefulShellBranch(
          initialLocation: "/favorites",
          routes: [
            GoRoute(
              path: '/favorites',
              builder: (context, state) => const FavoritesScreen(),
              routes: [
                // Детальная страница персонажа из избранного
                GoRoute(
                  path: 'character/:id',
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return CharacterDetailScreen(characterId: id);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
