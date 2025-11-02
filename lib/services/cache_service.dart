import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_project/models/character.dart';

class CacheService {
  static const String _charactersKey = 'cached_characters';
  static const String _characterKey = 'cached_character_';
  static const String _lastUpdateKey = 'cache_last_update';

  final SharedPreferences _prefs;

  CacheService(this._prefs);

  /// Сохранить список персонажей в кеш
  Future<bool> cacheCharacters(List<Character> characters) async {
    try {
      final jsonList = characters.map((c) => c.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      await _prefs.setString(_charactersKey, jsonString);
      await _prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Получить список персонажей из кеша
  List<Character>? getCachedCharacters() {
    try {
      final jsonString = _prefs.getString(_charactersKey);
      if (jsonString == null) return null;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Character.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
    }
  }

  /// Сохранить одного персонажа в кеш
  Future<bool> cacheCharacter(Character character) async {
    try {
      final jsonString = jsonEncode(character.toJson());
      await _prefs.setString('$_characterKey${character.id}', jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Получить одного персонажа из кеша
  Character? getCachedCharacter(int id) {
    try {
      final jsonString = _prefs.getString('$_characterKey$id');
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Character.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Добавить персонажей к существующему кешу (для пагинации)
  Future<bool> appendToCache(List<Character> newCharacters) async {
    try {
      final existing = getCachedCharacters() ?? [];

      // Создаем Map для быстрого поиска по ID
      final Map<int, Character> characterMap = {
        for (var char in existing) char.id: char
      };

      // Добавляем новые персонажи, избегая дубликатов
      for (var char in newCharacters) {
        characterMap[char.id] = char;
      }

      // Конвертируем обратно в список
      final allCharacters = characterMap.values.toList();

      return await cacheCharacters(allCharacters);
    } catch (e) {
      return false;
    }
  }

  /// Проверить, устарел ли кеш (старше N часов)
  bool isCacheExpired({int hours = 24}) {
    final lastUpdate = _prefs.getInt(_lastUpdateKey);
    if (lastUpdate == null) return true;

    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
    final now = DateTime.now();

    return now.difference(lastUpdateTime).inHours > hours;
  }

  /// Очистить весь кеш персонажей
  Future<bool> clearCache() async {
    try {
      await _prefs.remove(_charactersKey);
      await _prefs.remove(_lastUpdateKey);

      // Удаляем индивидуальные кеши персонажей
      final keys = _prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith(_characterKey)) {
          await _prefs.remove(key);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Получить время последнего обновления кеша
  DateTime? getLastUpdateTime() {
    final timestamp = _prefs.getInt(_lastUpdateKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Проверить, есть ли кеш
  bool hasCache() {
    return _prefs.getString(_charactersKey) != null;
  }
}
