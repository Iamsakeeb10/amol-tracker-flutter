import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../../../core/services/local_storage_service.dart';
import '../models/dua_models.dart';

const _favoritesKey = 'dua_favorites';

List<DuaCategory> _parseCategories(String jsonStr) {
  final list = jsonDecode(jsonStr) as List<dynamic>;
  return list
      .map((e) => DuaCategory.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(growable: false);
}

List<DuaSubCategory> _parseSubCategories(String jsonStr) {
  final list = jsonDecode(jsonStr) as List<dynamic>;
  return list
      .map((e) => DuaSubCategory.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(growable: false);
}

Map<int, DuaModel> _parseDuasMap(String jsonStr) {
  final list = jsonDecode(jsonStr) as List<dynamic>;
  final map = <int, DuaModel>{};
  for (final item in list) {
    final dua = DuaModel.fromJson(Map<String, dynamic>.from(item as Map));
    if (dua.duaId > 0) {
      map[dua.duaId] = dua;
    }
  }
  return map;
}

final duaCategoriesProvider = FutureProvider<List<DuaCategory>>((ref) async {
  final raw = await rootBundle.loadString('assets/categories.json');
  return compute(_parseCategories, raw);
});

final duaSubCategoriesProvider = FutureProvider<List<DuaSubCategory>>((ref) async {
  final raw = await rootBundle.loadString('assets/sub_categories.json');
  return compute(_parseSubCategories, raw);
});

final duasMapProvider = FutureProvider<Map<int, DuaModel>>((ref) async {
  final raw = await rootBundle.loadString('assets/duas.json');
  return compute(_parseDuasMap, raw);
});

final duasListProvider = FutureProvider<List<DuaModel>>((ref) async {
  final map = await ref.watch(duasMapProvider.future);
  final list = map.values.toList(growable: false)
    ..sort((a, b) => a.duaId.compareTo(b.duaId));
  return list;
});

final duasByIdsProvider = FutureProvider.family<List<DuaModel>, List<int>>((
  ref,
  ids,
) async {
  final map = await ref.watch(duasMapProvider.future);
  final result = <DuaModel>[];
  for (final id in ids) {
    final dua = map[id];
    if (dua != null) {
      result.add(dua);
    }
  }
  return result;
});

final subCategoriesByCategoryProvider =
    FutureProvider.family<List<DuaSubCategory>, String>((ref, categoryUrl) async {
  final all = await ref.watch(duaSubCategoriesProvider.future);
  return all
      .where((sub) => sub.category == categoryUrl)
      .toList(growable: false);
});

class DuaFavoritesNotifier extends StateNotifier<Set<int>> {
  DuaFavoritesNotifier() : super(_loadFavorites());

  static Set<int> _loadFavorites() {
    final raw = LocalStorageService.getPref<List<dynamic>>(_favoritesKey, const []);
    return raw.map((e) => e as int).toSet();
  }

  Future<void> toggle(int duaId) async {
    final next = Set<int>.from(state);
    if (next.contains(duaId)) {
      next.remove(duaId);
    } else {
      next.add(duaId);
    }
    state = next;
    await LocalStorageService.setPref(_favoritesKey, next.toList());
  }

  bool isFavorite(int duaId) => state.contains(duaId);
}

final duaFavoritesProvider =
    StateNotifierProvider<DuaFavoritesNotifier, Set<int>>(
  (ref) => DuaFavoritesNotifier(),
);

final favoriteDuasProvider = FutureProvider<List<DuaModel>>((ref) async {
  final favorites = ref.watch(duaFavoritesProvider);
  if (favorites.isEmpty) return const [];

  final map = await ref.watch(duasMapProvider.future);
  final result = <DuaModel>[];
  for (final id in favorites) {
    final dua = map[id];
    if (dua != null) {
      result.add(dua);
    }
  }
  result.sort((a, b) => a.duaId.compareTo(b.duaId));
  return result;
});
