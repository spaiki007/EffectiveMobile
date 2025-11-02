import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test_project/models/character.dart';
import 'package:test_project/riverpod/cache_provider.dart';
import 'package:test_project/riverpod/theme_provider.dart';
import 'package:test_project/widgets/character_card.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = useState(1);
    final allCharacters = useState<List<Character>>([]);
    final isLoadingMore = useState(false);
    final hasMorePages = useState(true);
    final scrollController = useScrollController();

    // Загрузка первой страницы с кешированием
    final firstPageAsync = ref.watch(cachedCharactersProvider(1));

    // Слушатель скролла для пагинации
    useEffect(() {
      Future<void> loadMoreCharacters() async {
        if (isLoadingMore.value || !hasMorePages.value) return;

        isLoadingMore.value = true;
        final nextPage = currentPage.value + 1;

        try {
          final response = await ref.read(cachedCharactersProvider(nextPage).future);

          if (response.results.isNotEmpty) {
            allCharacters.value = [...allCharacters.value, ...response.results];
            currentPage.value = nextPage;
            hasMorePages.value = response.info.hasNextPage;
          } else {
            hasMorePages.value = false;
          }
        } catch (e) {
          // Достигли конца списка или произошла ошибка
          hasMorePages.value = false;
        } finally {
          isLoadingMore.value = false;
        }
      }

      void onScroll() {
        if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
          if (!isLoadingMore.value && hasMorePages.value) {
            loadMoreCharacters();
          }
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Персонажи Рик и Морти',
              style: TextStyle(
                color: Theme.of(context).appBarTheme.titleTextStyle?.color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Индикатор кеша
            Consumer(
              builder: (context, ref, child) {
                final hasCache = ref.watch(hasCacheProvider);
                final lastUpdate = ref.watch(lastUpdateTimeProvider);

                if (hasCache && lastUpdate != null) {
                  final now = DateTime.now();
                  final diff = now.difference(lastUpdate);
                  String timeAgo;

                  if (diff.inMinutes < 1) {
                    timeAgo = 'только что';
                  } else if (diff.inHours < 1) {
                    timeAgo = '${diff.inMinutes} мин назад';
                  } else if (diff.inDays < 1) {
                    timeAgo = '${diff.inHours} ч назад';
                  } else {
                    timeAgo = '${diff.inDays} дн назад';
                  }

                  return Text(
                    'Обновлено: $timeAgo',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Переключатель темы
          Consumer(
            builder: (context, ref, child) {
              final themeMode = ref.watch(themeProvider);
              final isDark = themeMode == ThemeMode.dark;

              return IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: Theme.of(context).iconTheme.color,
                ),
                tooltip: isDark ? 'Светлая тема' : 'Темная тема',
                onPressed: () {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              );
            },
          ),
        ],
      ),
      body: firstPageAsync.when(
        data: (response) {
          // Инициализация списка при первой загрузке
          if (allCharacters.value.isEmpty && response.results.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              allCharacters.value = response.results;
              hasMorePages.value = response.info.hasNextPage;
            });
          }

          final characters = allCharacters.value.isNotEmpty ? allCharacters.value : response.results;

          if (characters.isEmpty) {
            return const Center(
              child: Text('Персонажи не найдены'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Сброс и перезагрузка
              currentPage.value = 1;
              allCharacters.value = [];
              hasMorePages.value = true;
              ref.invalidate(cachedCharactersProvider(1));
            },
            child: ListView.builder(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: characters.length + (hasMorePages.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == characters.length) {
                  // Индикатор загрузки внизу списка
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                return CharacterCard(
                  character: characters[index],
                  index: index,
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки:\n${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(cachedCharactersProvider(1));
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

