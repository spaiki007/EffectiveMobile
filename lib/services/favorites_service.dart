import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_characters';

  final SharedPreferences _prefs;

  FavoritesService(this._prefs);

  /// Получить список ID избранных персонажей
  List<int> getFavorites() {
    final List<String>? favoriteStrings = _prefs.getStringList(_favoritesKey);
    if (favoriteStrings == null) {
      return [];
    }
    return favoriteStrings.map((id) => int.parse(id)).toList();
  }

  /// Добавить персонажа в избранное
  Future<bool> addFavorite(int characterId) async {
    final favorites = getFavorites();
    if (!favorites.contains(characterId)) {
      favorites.add(characterId);
      return await _saveFavorites(favorites);
    }
    return true;
  }

  /// Удалить персонажа из избранного
  Future<bool> removeFavorite(int characterId) async {
    final favorites = getFavorites();
    favorites.remove(characterId);
    return await _saveFavorites(favorites);
  }

  /// Проверить, находится ли персонаж в избранном
  bool isFavorite(int characterId) {
    final favorites = getFavorites();
    return favorites.contains(characterId);
  }

  /// Переключить состояние избранного
  Future<bool> toggleFavorite(int characterId) async {
    if (isFavorite(characterId)) {
      return await removeFavorite(characterId);
    } else {
      return await addFavorite(characterId);
    }
  }

  /// Очистить все избранное
  Future<bool> clearFavorites() async {
    return await _prefs.remove(_favoritesKey);
  }

  /// Сохранить список избранного
  Future<bool> _saveFavorites(List<int> favorites) async {
    final favoriteStrings = favorites.map((id) => id.toString()).toList();
    return await _prefs.setStringList(_favoritesKey, favoriteStrings);
  }

  /// Получить количество избранных
  int get favoritesCount => getFavorites().length;
}
