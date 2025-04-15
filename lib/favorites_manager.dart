import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gère la persistance des favoris et le cache de leur contenu
class FavoritesManager {
  // Clés de stockage
  static const String _favoritesStorageKey = 'web_favorites';
  static const String _cacheContentPrefix = 'cached_content_';
  static const String _cacheTitlePrefix = 'cached_title_';
  static const String _cacheTimestampPrefix = 'cached_timestamp_';
  static const Duration _cacheValidityDuration = Duration(days: 30);

  // Données en mémoire
  final Set<String> _favorites = {};
  final List<VoidCallback> _listeners = [];
  late SharedPreferences _prefs;

  /// Initialise le gestionnaire et charge les données
  FavoritesManager() {
    _initialize();
  }

  /// Charge les données depuis le stockage persistant
  Future<void> _initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadFavorites();
      await _cleanExpiredCache();
    } catch (error) {
      debugPrint('Erreur d\'initialisation: $error');
    }
  }

  /// Charge les favoris depuis les préférences partagées
  Future<void> _loadFavorites() async {
    try {
      final savedFavorites = _prefs.getStringList(_favoritesStorageKey);
      if (savedFavorites != null) {
        _favorites.addAll(savedFavorites);
        _notifyListeners();
      }
    } catch (error) {
      debugPrint('Erreur de chargement des favoris: $error');
    }
  }

  /// Sauvegarde les favoris dans les préférences partagées
  Future<void> _saveFavorites() async {
    try {
      await _prefs.setStringList(_favoritesStorageKey, _favorites.toList());
      _notifyListeners();
    } catch (error) {
      debugPrint('Erreur de sauvegarde des favoris: $error');
    }
  }

  /// Nettoie le cache expiré
  Future<void> _cleanExpiredCache() async {
    try {
      final now = DateTime.now();
      final allKeys = _prefs.getKeys();

      for (final key in allKeys) {
        if (key.startsWith(_cacheContentPrefix)) {
          final url = key.substring(_cacheContentPrefix.length);
          final timestampKey = _cacheTimestampPrefix + url;

          if (_prefs.containsKey(timestampKey)) {
            final timestamp = DateTime.parse(_prefs.getString(timestampKey)!);
            if (now.difference(timestamp) > _cacheValidityDuration) {
              await _removeCachedContent(url);
            }
          }
        }
      }
    } catch (error) {
      debugPrint('Erreur de nettoyage du cache: $error');
    }
  }

  /// Gestion des écouteurs de changement
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Vérifie si une URL est dans les favoris
  bool isFavorite(String url) {
    return _favorites.contains(url);
  }

  /// Ajoute une URL aux favoris
  Future<void> addFavorite(String url) async {
    if (_favorites.add(url)) {
      await _saveFavorites();
    }
  }

  /// Retire une URL des favoris et son cache associé
  Future<void> removeFavorite(String url) async {
    if (_favorites.remove(url)) {
      await _removeCachedContent(url);
      await _saveFavorites();
    }
  }

  /// Bascule l'état favori d'une URL
  Future<void> toggleFavorite(String url) async {
    if (isFavorite(url)) {
      await removeFavorite(url);
    } else {
      await addFavorite(url);
    }
  }

  /// Récupère tous les favoris
  Set<String> getAllFavorites() {
    return Set<String>.from(_favorites);
  }

  /// Vide tous les favoris et leur cache
  Future<void> clearAllFavorites() async {
    for (final url in _favorites) {
      await _removeCachedContent(url);
    }
    _favorites.clear();
    await _saveFavorites();
  }

  /// Cache le contenu et le titre d'une page
  Future<void> cachePageContent(String url, String htmlContent, {String? title}) async {
    try {
      final contentKey = _cacheContentPrefix + url;
      final titleKey = _cacheTitlePrefix + url;
      final timestampKey = _cacheTimestampPrefix + url;

      await Future.wait([
        _prefs.setString(contentKey, htmlContent),
        if (title != null) _prefs.setString(titleKey, title),
        _prefs.setString(timestampKey, DateTime.now().toIso8601String()),
      ]);
    } catch (error) {
      debugPrint('Erreur de mise en cache: $error');
    }
  }

  /// Récupère le contenu en cache d'une page
  Future<String?> getCachedContent(String url) async {
    try {
      final contentKey = _cacheContentPrefix + url;
      final timestampKey = _cacheTimestampPrefix + url;

      if (!_prefs.containsKey(contentKey)) return null;

      // Vérification de l'expiration du cache
      if (_prefs.containsKey(timestampKey)) {
        final timestamp = DateTime.parse(_prefs.getString(timestampKey)!);
        if (DateTime.now().difference(timestamp) > _cacheValidityDuration) {
          await _removeCachedContent(url);
          return null;
        }
      }

      return _prefs.getString(contentKey);
    } catch (error) {
      debugPrint('Erreur de récupération du cache: $error');
      return null;
    }
  }

  /// Récupère le titre en cache d'une page
  Future<String?> getCachedTitle(String url) async {
    try {
      final titleKey = _cacheTitlePrefix + url;
      return _prefs.getString(titleKey);
    } catch (error) {
      debugPrint('Erreur de récupération du titre: $error');
      return null;
    }
  }

  /// Supprime le contenu en cache d'une page
  Future<void> _removeCachedContent(String url) async {
    try {
      final contentKey = _cacheContentPrefix + url;
      final titleKey = _cacheTitlePrefix + url;
      final timestampKey = _cacheTimestampPrefix + url;

      await Future.wait([
        _prefs.remove(contentKey),
        _prefs.remove(titleKey),
        _prefs.remove(timestampKey),
      ]);
    } catch (error) {
      debugPrint('Erreur de suppression du cache: $error');
    }
  }

  /// Compte le nombre de favoris
  int get favoritesCount {
    return _favorites.length;
  }
}