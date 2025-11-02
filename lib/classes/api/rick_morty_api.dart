import 'package:dio/dio.dart';
import 'package:test_project/classes/api/client.dart';
import 'package:test_project/classes/api/wrap_response.dart';
import 'package:test_project/models/character.dart';
import 'package:test_project/models/character_response.dart';

class RickMortyApi {
  final Client api;
  final Future<WrapResponse> Function(String methodName, Future<Response> Function() apiCall) handleRequest;

  RickMortyApi({
    required this.api,
    required this.handleRequest,
  });

  /// Получение списка персонажей с пагинацией
  /// [page] - номер страницы (по умолчанию 1)
  Future<WrapResponse> getCharacters({int page = 1}) {
    const methodName = 'getCharacters';
    return handleRequest(methodName, () {
      return api.dio.get('/character', queryParameters: {'page': page});
    });
  }

  /// Получение одного персонажа по ID
  Future<WrapResponse> getCharacter(int id) {
    const methodName = 'getCharacter';
    return handleRequest(methodName, () {
      return api.dio.get('/character/$id');
    });
  }

  /// Получение нескольких персонажей по списку ID
  /// [ids] - список ID персонажей, например [1, 2, 3]
  Future<WrapResponse> getMultipleCharacters(List<int> ids) {
    const methodName = 'getMultipleCharacters';
    final idsString = ids.join(',');
    return handleRequest(methodName, () {
      return api.dio.get('/character/$idsString');
    });
  }

  /// Поиск персонажей по имени
  /// [name] - имя для поиска
  /// [page] - номер страницы
  Future<WrapResponse> searchCharactersByName(String name, {int page = 1}) {
    const methodName = 'searchCharactersByName';
    return handleRequest(methodName, () {
      return api.dio.get('/character', queryParameters: {
        'name': name,
        'page': page,
      });
    });
  }

  /// Фильтрация персонажей по статусу
  /// [status] - статус: "alive", "dead", "unknown"
  /// [page] - номер страницы
  Future<WrapResponse> getCharactersByStatus(String status, {int page = 1}) {
    const methodName = 'getCharactersByStatus';
    return handleRequest(methodName, () {
      return api.dio.get('/character', queryParameters: {
        'status': status,
        'page': page,
      });
    });
  }

  /// Парсинг ответа в CharacterResponse
  CharacterResponse parseCharacterResponse(dynamic data) {
    return CharacterResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Парсинг ответа в Character
  Character parseCharacter(dynamic data) {
    return Character.fromJson(data as Map<String, dynamic>);
  }

  /// Парсинг ответа в список Character (для множественного запроса)
  /// API возвращает:
  /// - Один персонаж: объект {id: 1, name: "Rick", ...}
  /// - Несколько персонажей: массив [{...}, {...}]
  List<Character> parseCharacterList(dynamic data) {
    if (data is List) {
      // Несколько персонажей - парсим массив
      return data.map((e) => Character.fromJson(e as Map<String, dynamic>)).toList();
    } else if (data is Map<String, dynamic>) {
      // Один персонаж - парсим объект и оборачиваем в список
      return [Character.fromJson(data)];
    }
    return [];
  }
}
