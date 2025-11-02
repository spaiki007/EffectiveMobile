import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_project/classes/api/client.dart';
import 'package:test_project/classes/api/rick_morty_api.dart';
import 'package:test_project/classes/api/wrap_response.dart';
import 'package:test_project/models/character.dart';
import 'package:test_project/models/character_response.dart';


/// Provider для Client (синглтон Dio)
final clientProvider = Provider<Client>((ref) {
  return Client();
});


/// Notifier для токена авторизации
class TokenNotifier extends Notifier<String> {
  @override
  String build() => '';
}

/// Provider для токена авторизации
final tokenProvider = NotifierProvider<TokenNotifier, String>(TokenNotifier.new);


/// Общий метод для обработки API запросов
final handleRequestProvider = Provider<Future<WrapResponse> Function(String methodName, Future<Response> Function() apiCall)>((ref) {
  
  return (String methodName, Future<Response> Function() apiCall) async {
    try {
      final response = await apiCall();

      if (response.statusCode != 200) {
        return WrapResponse(error: '$methodName: ${response.data['detail']}');
      }

      return WrapResponse(object: response.data);
    } on DioException catch (e) {
      final request = e.requestOptions;
      final response = e.response;

      if (response != null && response.statusCode != 200) {
        final errorDetail = response.data?['detail'] ?? 'Unknown error';
        return WrapResponse(
          error: '${Platform.isAndroid ? 'android' : 'ios'}, $methodName: ${response.statusCode}: ${e.type}, Request data: ${request.data}, Response: $errorDetail',
        );
      }

      return WrapResponse(
        error: '${Platform.isAndroid ? 'android' : 'ios'}, $methodName: ${e.type}, Request data: ${request.data}, ${e.toString()}',
      );
    } catch (e) {
      return WrapResponse(
        error: '${Platform.isAndroid ? 'android' : 'ios'}, $methodName: ${e.toString()}',
      );
    }
  };
});


/// Provider для RickMortyApi
final rickMortyApiProvider = Provider<RickMortyApi>((ref) {
  final client = ref.watch(clientProvider);
  final handleRequest = ref.watch(handleRequestProvider);

  return RickMortyApi(
    api: client,
    handleRequest: handleRequest,
  );
});


/// Provider для получения списка персонажей с пагинацией
final charactersProvider = FutureProvider.family<CharacterResponse, int>((ref, page) async {
  final api = ref.watch(rickMortyApiProvider);
  final response = await api.getCharacters(page: page);

  if (response.error.isNotEmpty) {
    throw Exception(response.error);
  }

  return api.parseCharacterResponse(response.object);
});

/// Provider для получения одного персонажа
final characterProvider = FutureProvider.family<Character, int>((ref, id) async {
  final api = ref.watch(rickMortyApiProvider);
  final response = await api.getCharacter(id);

  if (response.error.isNotEmpty) {
    throw Exception(response.error);
  }

  return api.parseCharacter(response.object);
});

/// Provider для получения нескольких персонажей по списку ID
final multipleCharactersProvider = FutureProvider.family<List<Character>, List<int>>((ref, ids) async {
  if (ids.isEmpty) {
    return [];
  }

  final api = ref.watch(rickMortyApiProvider);
  final response = await api.getMultipleCharacters(ids);

  if (response.error.isNotEmpty) {
    throw Exception(response.error);
  }

  return api.parseCharacterList(response.object);
});

/// Provider для поиска персонажей по имени
final searchCharactersProvider = FutureProvider.family<CharacterResponse, SearchParams>((ref, params) async {
  final api = ref.watch(rickMortyApiProvider);
  final response = await api.searchCharactersByName(params.query, page: params.page);

  if (response.error.isNotEmpty) {
    throw Exception(response.error);
  }

  return api.parseCharacterResponse(response.object);
});

/// Параметры для поиска
class SearchParams {
  final String query;
  final int page;

  const SearchParams({
    required this.query,
    this.page = 1,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          page == other.page;

  @override
  int get hashCode => query.hashCode ^ page.hashCode;
}


