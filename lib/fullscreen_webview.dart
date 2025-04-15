import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'favorites_manager.dart';
import 'widgets/favorites_panel.dart';
import 'offline_page.dart';
import 'offline_error_page.dart';

class FullScreenWebView extends StatefulWidget {
  final FavoritesManager favoritesManager;
  static const String homeUrl = 'https://kztcha.pythonanywhere.com/martinique';

  const FullScreenWebView({
    super.key,
    required this.favoritesManager,
  });

  @override
  State<FullScreenWebView> createState() => _FullScreenWebViewState();
}

class _FullScreenWebViewState extends State<FullScreenWebView> {
  late final InAppWebViewController webViewController;
  double loadingProgress = 0;
  bool isLoading = true;
  bool isMenuOpen = false;
  String? currentUrl;
  bool showBackButton = false;
  bool showHomeButton = false;
  bool isOffline = false;
  late StreamSubscription<ConnectivityResult> connectivitySubscription;

  @override
  void initState() {
    super.initState();
    currentUrl = FullScreenWebView.homeUrl;
    _initializeConnectivity();
    _checkInitialConnectivity();
  }

  @override
  void dispose() {
    connectivitySubscription.cancel();
    webViewController.dispose();
    super.dispose();
  }

  Future<void> _initializeConnectivity() async {
    connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_updateConnectionStatus);
  }

  Future<void> _checkInitialConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      isOffline = result == ConnectivityResult.none;
    });
  }

  void _updateNavigationState() async {
    final canGoBack = await webViewController.canGoBack();
    setState(() {
      showBackButton = canGoBack;
      showHomeButton = currentUrl != FullScreenWebView.homeUrl;
    });
  }

  Future<void> _loadUrl(String url) async {
    try {
      await webViewController.loadUrl(
        urlRequest: URLRequest(url: WebUri(url)),
      );
    } catch (e) {
      _showSnackBar('Erreur de chargement de la page');
    }
  }

  Future<void> _goBack() async {
    if (await webViewController.canGoBack()) {
      await webViewController.goBack();
    }
  }

  Future<void> _goHome() async {
    if (isOffline) {
      _showSnackBar('Non disponible hors ligne');
      return;
    }
    await _loadUrl(FullScreenWebView.homeUrl);
  }

  Future<void> _toggleFavorite() async {
    if (currentUrl == null || currentUrl == FullScreenWebView.homeUrl) return;

    try {
      await widget.favoritesManager.toggleFavorite(currentUrl!);
      if (!isOffline) {
        final content = await webViewController.getHtml();
        final title = await webViewController.getTitle();
        if (content != null) {
          await widget.favoritesManager.cachePageContent(
            currentUrl!,
            content,
            title: title,
          );
        }
      }
      setState(() {});
    } catch (e) {
      _showSnackBar('Erreur lors de la gestion des favoris');
    }
  }

  void _showFavoritesPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => FavoritesPanel(
        favoritesManager: widget.favoritesManager,
        onFavoriteSelected: (url) => _loadFavorite(context, url),
        isOfflineMode: isOffline,
      ),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  Future<void> _loadFavorite(BuildContext context, String url) async {
    Navigator.pop(context);
    await _loadUrl(url);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isOffline) {
      return OfflinePage(
        favoritesManager: widget.favoritesManager,
        onRetryConnection: _retryConnection,
        onReturnToHome: _goHome,
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildWebView(),
          if (isLoading) _buildProgressIndicator(),
          _buildNavigationButtons(context),
          _buildFloatingMenu(context),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(FullScreenWebView.homeUrl)),
      onWebViewCreated: (controller) {
        webViewController = controller;
      },
      onLoadStart: (controller, url) {
        setState(() {
          isLoading = true;
          currentUrl = url?.toString();
        });
      },
      onLoadStop: (controller, url) async {
        setState(() {
          isLoading = false;
          currentUrl = url?.toString();
        });
        _updateNavigationState();
        if (url != null && widget.favoritesManager.isFavorite(url.toString())) {
          await _cacheCurrentPage();
        }
      },
      onProgressChanged: (controller, progress) {
        setState(() {
          loadingProgress = progress / 100;
        });
      },
      onLoadError: (controller, url, code, message) async {
        final connectivity = await Connectivity().checkConnectivity();
        if (connectivity == ConnectivityResult.none) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OfflineErrorPage(
                requestedUrl: url?.toString() ?? '',
                favoritesManager: widget.favoritesManager,
                onRetryConnection: _retryConnection,
                onReturnToHome: _goHome,
              ),
            ),
          );
        } else {
          setState(() => isLoading = false);
          _showSnackBar('Erreur de chargement: $message');
        }
      },
    );
  }

  Widget _buildProgressIndicator() {
    return LinearProgressIndicator(
      value: loadingProgress,
      backgroundColor: Colors.grey[200],
      valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 8,
      right: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showBackButton) _buildBackButton(),
          if (showHomeButton) _buildHomeButton(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Material(
      borderRadius: BorderRadius.circular(24),
      color: Colors.pink.withOpacity(0.8),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _goBack,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton() {
    return Material(
      borderRadius: BorderRadius.circular(24),
      color: Colors.pink.withOpacity(0.8),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _goHome,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: const Icon(
            Icons.home,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingMenu(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isMenuOpen) _buildMenuOptions(),
            _buildMenuButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOptions() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentUrl != FullScreenWebView.homeUrl)
            _buildMenuButtonItem(
              icon: widget.favoritesManager.isFavorite(currentUrl ?? '')
                  ? Icons.star
                  : Icons.star_border,
              iconColor: widget.favoritesManager.isFavorite(currentUrl ?? '')
                  ? Colors.amber
                  : Colors.pink,
              tooltip: 'Gérer les favoris',
              onPressed: _toggleFavorite,
            ),
          _buildMenuButtonItem(
            icon: Icons.collections_bookmark,
            iconColor: Colors.pink,
            tooltip: 'Mes Favoris',
            onPressed: () => _showFavoritesPanel(context),
          ),
          const Divider(height: 1, color: Colors.grey),
          _buildMenuButtonItem(
            icon: Icons.refresh,
            iconColor: Colors.pink,
            tooltip: 'Rafraîchir',
            onPressed: () {
              webViewController.reload();
              setState(() => isMenuOpen = false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButtonItem({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color iconColor,
  }) {
    return SizedBox(
      width: 56,
      height: 56,
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildMenuButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.pink,
        child: Icon(
          isMenuOpen ? Icons.close : Icons.menu,
          color: Colors.white,
        ),
        onPressed: () {
          setState(() => isMenuOpen = !isMenuOpen);
        },
      ),
    );
  }

  Future<void> _cacheCurrentPage() async {
    try {
      final content = await webViewController.getHtml();
      final title = await webViewController.getTitle();
      if (content != null && currentUrl != null) {
        await widget.favoritesManager.cachePageContent(
          currentUrl!,
          content,
          title: title,
        );
      }
    } catch (e) {
      debugPrint('Erreur de mise en cache: $e');
    }
  }

  Future<void> _retryConnection() async {
    await _checkInitialConnectivity();
    if (!isOffline) {
      webViewController.reload();
    }
  }
}