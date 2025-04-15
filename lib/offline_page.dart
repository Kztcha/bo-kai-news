import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../favorites_manager.dart';
import 'widgets/favorites_panel.dart';

class OfflinePage extends StatefulWidget {
  final FavoritesManager favoritesManager;
  final VoidCallback onRetryConnection;
  final VoidCallback onReturnToHome;

  const OfflinePage({
    super.key,
    required this.favoritesManager,
    required this.onRetryConnection,
    required this.onReturnToHome,
  });

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  bool _isLoadingCachedContent = false;
  String? _cachedContentToDisplay;
  String? _currentCachedUrl;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          _buildOfflineHeader(context),
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.orange.withOpacity(0.3),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.signal_wifi_off,
                size: 24.0,
                color: Colors.orange,
              ),
              const SizedBox(width: 12.0),
              Text(
                'Mode hors ligne activé',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_errorMessage != null) {
      return _buildErrorState();
    } else if (_cachedContentToDisplay != null) {
      return _buildCachedContentView();
    } else {
      return _buildFavoritesListView();
    }
  }

  Widget _buildCachedContentView() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _returnToFavoritesList,
                tooltip: 'Retour aux favoris',
              ),
              Expanded(
                child: Text(
                  _currentCachedUrl != null
                      ? _simplifyUrl(_currentCachedUrl!)
                      : 'Article en cache',
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1.0),
        Expanded(
          child: InAppWebView(
            initialData: InAppWebViewInitialData(
              data: _cachedContentToDisplay!,
              mimeType: "text/html",
              encoding: "utf-8",
              baseUrl: WebUri(_currentCachedUrl!),
            ),
            onLoadStart: (controller, url) {
              _handleNavigationAttempt(url.toString());
            },
            onLoadError: (controller, url, code, message) {
              _handleNavigationError();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesListView() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
          child: Text(
            'Sélectionnez un article à consulter',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(height: 1.0),
        Expanded(
          child: FavoritesPanel(
            favoritesManager: widget.favoritesManager,
            onFavoriteSelected: _loadCachedContent,
            isOfflineMode: true,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.error_outline,
            size: 48.0,
            color: Colors.orange,
          ),
          const SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 24.0),
          FilledButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour aux articles disponibles'),
            onPressed: _returnToFavoritesList,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCachedContent(String url) async {
    if (_isLoadingCachedContent) return;

    setState(() {
      _isLoadingCachedContent = true;
      _errorMessage = null;
    });

    try {
      final cachedContent = await widget.favoritesManager.getCachedContent(url);

      if (cachedContent != null && cachedContent.isNotEmpty) {
        setState(() {
          _cachedContentToDisplay = cachedContent;
          _currentCachedUrl = url;
        });
      } else {
        setState(() {
          _errorMessage = 'Le contenu de cet article n\'a pas été mis en cache';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement du contenu en cache';
      });
    } finally {
      setState(() => _isLoadingCachedContent = false);
    }
  }

  void _handleNavigationAttempt(String url) {
    if (url != _currentCachedUrl) {
      setState(() {
        _errorMessage = 'Navigation bloquée en mode hors ligne';
        _cachedContentToDisplay = null;
      });
    }
  }

  void _handleNavigationError() {
    setState(() {
      _errorMessage = 'Erreur de chargement du contenu';
      _cachedContentToDisplay = null;
    });
  }

  void _returnToFavoritesList() {
    setState(() {
      _errorMessage = null;
      _cachedContentToDisplay = null;
    });
  }

  String _simplifyUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host + (uri.path.isEmpty ? '' : uri.path.split('/').first);
    } catch (e) {
      return url.length > 50
          ? '${url.substring(0, 50)}...'
          : url;
    }
  }
}