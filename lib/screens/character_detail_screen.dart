import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test_project/riverpod/cache_provider.dart';
import 'package:test_project/riverpod/favorites_provider.dart';
import 'package:test_project/widgets/animated_favorite_button.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CharacterDetailScreen extends HookConsumerWidget {
  final int characterId;

  const CharacterDetailScreen({
    super.key,
    required this.characterId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterAsync = ref.watch(cachedCharacterProvider(characterId));
    final isFavorite = ref.watch(isFavoriteProvider(characterId));

    return Scaffold(
      body: characterAsync.when(
        data: (character) {
          return CustomScrollView(
            slivers: [
              // AppBar с изображением персонажа
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Изображение персонажа с кешированием
                      CachedNetworkImage(
                        imageUrl: character.image,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 100),
                        ),
                      ),
                      // Градиент для читаемости текста
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  // Кнопка избранного с анимацией
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: AnimatedFavoriteButton(
                      isFavorite: isFavorite,
                      size: 30,
                      activeColor: Colors.amber,
                      inactiveColor: Colors.white,
                      onPressed: () {
                        ref.read(favoritesProvider.notifier).toggleFavorite(characterId);
                      },
                    ),
                  ),
                ],
              ),

              // Информация о персонаже
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Имя персонажа
                      Text(
                        character.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Статус с индикатором
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(character.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${character.status} - ${character.species}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Карточки с информацией
                      _buildInfoCard('Пол', character.gender),
                      if (character.type.isNotEmpty) _buildInfoCard('Тип', character.type),
                      _buildInfoCard('Происхождение', character.origin.name),
                      _buildInfoCard('Локация', character.location.name),

                      const SizedBox(height: 16),

                      // Эпизоды
                      const Text(
                        'Эпизоды',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        'Количество эпизодов',
                        character.episode.length.toString(),
                        icon: Icons.tv,
                      ),

                      const SizedBox(height: 16),

                      // Дополнительная информация
                      const Text(
                        'Дополнительно',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        'Дата создания',
                        _formatDate(character.created),
                        icon: Icons.calendar_today,
                      ),
                      _buildInfoCard(
                        'ID',
                        character.id.toString(),
                        icon: Icons.tag,
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Назад'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Виджет для карточки с информацией
  Widget _buildInfoCard(String label, String value, {IconData? icon}) {
    return Builder(
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).cardTheme.color
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Получить цвет статуса
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'alive':
        return Colors.green;
      case 'dead':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Форматирование даты
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
