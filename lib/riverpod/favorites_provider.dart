import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_project/models/character.dart';
import 'package:test_project/riverpod/cache_provider.dart';
import 'package:test_project/services/favorites_service.dart';


/// Provider для SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Provider для FavoritesService
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.when(
    data: (data) => FavoritesService(data),
    loading: () => throw Exception('SharedPreferences loading...'),
    error: (err, stack) => throw err,
  );
});


/// Notifier для управления состоянием избранного
class FavoritesNotifier extends Notifier<List<int>> {
  @override
  List<int> build() {
    // Инициализация из SharedPreferences
    final service = ref.watch(favoritesServiceProvider);
    return service.getFavorites();
  }

  /// Добавить в избранное
  Future<void> addFavorite(int characterId) async {
    final service = ref.read(favoritesServiceProvider);
    await service.addFavorite(characterId);
    state = service.getFavorites();
  }

  /// Удалить из избранного
  Future<void> removeFavorite(int characterId) async {
    final service = ref.read(favoritesServiceProvider);
    await service.removeFavorite(characterId);
    state = service.getFavorites();
  }

  /// Переключить состояние избранного
  Future<void> toggleFavorite(int characterId) async {
    final service = ref.read(favoritesServiceProvider);
    await service.toggleFavorite(characterId);
    state = service.getFavorites();
  }

  /// Проверить, находится ли персонаж в избранном
  bool isFavorite(int characterId) {
    return state.contains(characterId);
  }

  /// Очистить все избранное
  Future<void> clearFavorites() async {
    final service = ref.read(favoritesServiceProvider);
    await service.clearFavorites();
    state = [];
  }
}

/// Provider для списка ID избранных персонажей
final favoritesProvider = NotifierProvider<FavoritesNotifier, List<int>>(
  FavoritesNotifier.new,
);

/// Provider для проверки, является ли персонаж избранным
final isFavoriteProvider = Provider.family<bool, int>((ref, characterId) {
  final favorites = ref.watch(favoritesProvider);
  return favorites.contains(characterId);
});

/// Provider для получения полных данных избранных персонажей с кешированием
final favoriteCharactersProvider = FutureProvider<List<Character>>((ref) async {
  final favoriteIds = ref.watch(favoritesProvider);

  if (favoriteIds.isEmpty) {
    return [];
  }

  // Сначала пытаемся загрузить из кеша
  final cacheService = ref.watch(cacheServiceProvider);
  final cachedCharacters = cacheService.getCachedCharacters();

  List<Character> result = [];

  if (cachedCharacters != null && cachedCharacters.isNotEmpty) {
    // Фильтруем закешированных персонажей по ID избранных
    result = cachedCharacters.where((char) => favoriteIds.contains(char.id)).toList();
  }

  // Если не все избранные персонажи найдены в кеше, пытаемся загрузить с API
  final foundIds = result.map((char) => char.id).toSet();
  final missingIds = favoriteIds.where((id) => !foundIds.contains(id)).toList();

  if (missingIds.isNotEmpty) {
    try {
      // Загружаем недостающих персонажей с API по одному через кешированный провайдер
      for (final id in missingIds) {
        try {
          final character = await ref.read(cachedCharacterProvider(id).future);
          result.add(character);
        } catch (e) {
          // Игнорируем ошибку для отдельного персонажа, продолжаем загрузку остальных
        }
      }
    } catch (e) {
      // Если загрузка с API не удалась, возвращаем то, что есть в кеше
    }
  }

  return result;
});

// ============================================
// Sorting for Favorites
// ============================================

enum SortOrder {
  nameAsc,
  nameDesc,
  statusAlive,
  statusDead,
}

/// Provider для порядка сортировки
class SortOrderNotifier extends Notifier<SortOrder> {
  @override
  SortOrder build() => SortOrder.nameAsc;

  void setSortOrder(SortOrder order) {
    state = order;
  }
}

final sortOrderProvider = NotifierProvider<SortOrderNotifier, SortOrder>(
  SortOrderNotifier.new,
);

/// Provider для отсортированного списка избранных персонажей
final sortedFavoriteCharactersProvider = FutureProvider<List<Character>>((ref) async {
  final characters = await ref.watch(favoriteCharactersProvider.future);
  final sortOrder = ref.watch(sortOrderProvider);

  final sortedList = List<Character>.from(characters);

  switch (sortOrder) {
    case SortOrder.nameAsc:
      sortedList.sort((a, b) => a.name.compareTo(b.name));
      break;
    case SortOrder.nameDesc:
      sortedList.sort((a, b) => b.name.compareTo(a.name));
      break;
    case SortOrder.statusAlive:
      sortedList.sort((a, b) {
        if (a.status == 'Alive' && b.status != 'Alive') return -1;
        if (a.status != 'Alive' && b.status == 'Alive') return 1;
        return a.name.compareTo(b.name);
      });
      break;
    case SortOrder.statusDead:
      sortedList.sort((a, b) {
        if (a.status == 'Dead' && b.status != 'Dead') return -1;
        if (a.status != 'Dead' && b.status == 'Dead') return 1;
        return a.name.compareTo(b.name);
      });
      break;
  }

  return sortedList;
});
