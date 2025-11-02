import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test_project/riverpod/favorites_provider.dart';
import 'package:test_project/widgets/character_card.dart';

class FavoritesScreen extends HookConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedCharactersAsync = ref.watch(sortedFavoriteCharactersProvider);
    final currentSortOrder = ref.watch(sortOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        centerTitle: true,
        actions: [
          // Кнопка сортировки
          PopupMenuButton<SortOrder>(
            icon: Icon(Icons.sort, color: Theme.of(context).iconTheme.color),
            onSelected: (SortOrder order) {
              ref.read(sortOrderProvider.notifier).setSortOrder(order);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortOrder.nameAsc,
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      size: 18,
                      color: currentSortOrder == SortOrder.nameAsc
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Имя (А-Я)',
                      style: TextStyle(
                        color: currentSortOrder == SortOrder.nameAsc
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortOrder.nameDesc,
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      size: 18,
                      color: currentSortOrder == SortOrder.nameDesc
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Имя (Я-А)',
                      style: TextStyle(
                        color: currentSortOrder == SortOrder.nameDesc
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortOrder.statusAlive,
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 18,
                      color: currentSortOrder == SortOrder.statusAlive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Живые первыми',
                      style: TextStyle(
                        color: currentSortOrder == SortOrder.statusAlive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortOrder.statusDead,
                child: Row(
                  children: [
                    Icon(
                      Icons.heart_broken,
                      size: 18,
                      color: currentSortOrder == SortOrder.statusDead
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Мертвые первыми',
                      style: TextStyle(
                        color: currentSortOrder == SortOrder.statusDead
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: sortedCharactersAsync.when(
        data: (characters) {
          if (characters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_border,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет избранных персонажей',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Добавьте персонажей в избранное,\nнажав на звездочку',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: characters.length,
            itemBuilder: (context, index) {
              final character = characters[index];
              return Dismissible(
                key: Key('character_${character.id}'),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  ref.read(favoritesProvider.notifier).toggleFavorite(character.id);

                  // Показываем SnackBar с возможностью отмены
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${character.name} удален из избранного'),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'Отменить',
                        onPressed: () {
                          ref.read(favoritesProvider.notifier).toggleFavorite(character.id);
                        },
                      ),
                    ),
                  );
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                child: CharacterCard(
                  character: character,
                  index: index,
                ),
              );
            },
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
                  ref.invalidate(sortedFavoriteCharactersProvider);
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
