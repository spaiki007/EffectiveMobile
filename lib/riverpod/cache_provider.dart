import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_project/models/character.dart';
import 'package:test_project/models/character_response.dart';
import 'package:test_project/riverpod/favorites_provider.dart';
import 'package:test_project/riverpod/queries_provider.dart';
import 'package:test_project/services/cache_service.dart';


/// Provider для CacheService
final cacheServiceProvider = Provider<CacheService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.when(
    data: (data) => CacheService(data),
    loading: () => throw Exception('SharedPreferences loading...'),
    error: (err, stack) => throw err,
  );
});

/// Provider для получения персонажей с кешированием
/// Сначала показывает данные из кеша, затем загружает с API
final cachedCharactersProvider = FutureProvider.family<CharacterResponse, int>((ref, page) async {
  final api = ref.watch(rickMortyApiProvider);
  final cacheService = ref.watch(cacheServiceProvider);

  // Для первой страницы пытаемся загрузить из кеша
  if (page == 1) {
    final cachedCharacters = cacheService.getCachedCharacters();
    if (cachedCharacters != null && cachedCharacters.isNotEmpty) {
      // Показываем кеш пользователю
      // (в фоне будет загрузка с API для обновления)
    }
  }

  // Загружаем с API
  try {
    final response = await api.getCharacters(page: page);

    if (response.error.isNotEmpty) {
      // Если ошибка и есть кеш - показываем кеш
      if (page == 1) {
        final cachedCharacters = cacheService.getCachedCharacters();
        if (cachedCharacters != null && cachedCharacters.isNotEmpty) {
          return CharacterResponse(
            info: Info(count: cachedCharacters.length, pages: 1, next: null, prev: null),
            results: cachedCharacters,
          );
        }
      }
      throw Exception(response.error);
    }

    final characterResponse = api.parseCharacterResponse(response.object);

    // Сохраняем в кеш
    if (page == 1) {
      // Первая страница - перезаписываем кеш
      await cacheService.cacheCharacters(characterResponse.results);
    } else {
      // Последующие страницы - добавляем к кешу
      await cacheService.appendToCache(characterResponse.results);
    }

    // Кешируем каждого персонажа отдельно для детальной страницы
    for (var character in characterResponse.results) {
      await cacheService.cacheCharacter(character);
    }

    return characterResponse;
  } catch (e) {
    // При ошибке сети показываем кеш
    if (page == 1) {
      final cachedCharacters = cacheService.getCachedCharacters();
      if (cachedCharacters != null && cachedCharacters.isNotEmpty) {
        return CharacterResponse(
          info: Info(count: cachedCharacters.length, pages: 1, next: null, prev: null),
          results: cachedCharacters,
        );
      }
    }
    rethrow;
  }
});

/// Provider для получения одного персонажа с кешированием
final cachedCharacterProvider = FutureProvider.family<Character, int>((ref, id) async {
  final api = ref.watch(rickMortyApiProvider);
  final cacheService = ref.watch(cacheServiceProvider);

  // Сначала пытаемся получить из кеша
  final cachedCharacter = cacheService.getCachedCharacter(id);

  try {
    // Загружаем с API
    final response = await api.getCharacter(id);

    if (response.error.isNotEmpty) {
      // Если ошибка и есть кеш - возвращаем кеш
      if (cachedCharacter != null) {
        return cachedCharacter;
      }
      throw Exception(response.error);
    }

    final character = api.parseCharacter(response.object);

    // Сохраняем в кеш
    await cacheService.cacheCharacter(character);

    return character;
  } catch (e) {
    // При ошибке сети показываем кеш
    if (cachedCharacter != null) {
      return cachedCharacter;
    }
    rethrow;
  }
});


/// Provider для проверки наличия кеша
final hasCacheProvider = Provider<bool>((ref) {
  final cacheService = ref.watch(cacheServiceProvider);
  return cacheService.hasCache();
});

/// Provider для получения времени последнего обновления
final lastUpdateTimeProvider = Provider<DateTime?>((ref) {
  final cacheService = ref.watch(cacheServiceProvider);
  return cacheService.getLastUpdateTime();
});

/// Provider для проверки устаревания кеша
final isCacheExpiredProvider = Provider<bool>((ref) {
  final cacheService = ref.watch(cacheServiceProvider);
  return cacheService.isCacheExpired(hours: 24);
});
