import 'package:flutter/material.dart';
import '../favorites_manager.dart';
import 'favorite_card.dart';

class FavoritesPanel extends StatefulWidget {
  final FavoritesManager favoritesManager;
  final ValueChanged<String> onFavoriteSelected;
  final bool isOfflineMode;
  final VoidCallback? onClose;

  const FavoritesPanel({
    Key? key,
    required this.favoritesManager,
    required this.onFavoriteSelected,
    this.isOfflineMode = false,
    this.onClose,
  }) : super(key: key);

  @override
  State<FavoritesPanel> createState() => _FavoritesPanelState();
}

class _FavoritesPanelState extends State<FavoritesPanel> {
  late Set<String> _favorites;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    widget.favoritesManager.addListener(_handleFavoritesChange);
  }

  @override
  void dispose() {
    widget.favoritesManager.removeListener(_handleFavoritesChange);
    super.dispose();
  }

  void _handleFavoritesChange() {
    if (mounted) {
      setState(() {
        _favorites = widget.favoritesManager.getAllFavorites();
      });
    }
  }

  Future<void> _loadFavorites() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await Future.delayed(const Duration(milliseconds: 300));

      final loadedFavorites = widget.favoritesManager.getAllFavorites();

      setState(() {
        _favorites = loadedFavorites;
        _isLoading = false;
      });
    } catch (exception) {
      setState(() {
        _errorMessage = 'Error loading favorites';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(String url) async {
    if (_isDeleting || widget.isOfflineMode) return;

    setState(() => _isDeleting = true);

    try {
      await widget.favoritesManager.removeFavorite(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Favorite removed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove favorite'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          _buildContentArea(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'My Favorites',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.isOfflineMode) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.signal_wifi_off,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Offline',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          // Close button is now only visible in online mode
          if (!widget.isOfflineMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onClose ?? () => Navigator.pop(context),
              tooltip: 'Close',
            ),
        ],
      ),
    );
  }

  Widget _buildContentArea(BuildContext context) {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadFavorites,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_favorites.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_outline,
                size: 48,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No favorites saved',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (widget.isOfflineMode) ...[
                const SizedBox(height: 8),
                Text(
                  'Favorites are only available offline if you visited them while online',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final url = _favorites.elementAt(index);
          return FutureBuilder<String?>(
            future: widget.favoritesManager.getCachedTitle(url),
            builder: (context, titleSnapshot) {
              if (widget.isOfflineMode) {
                return FutureBuilder<String?>(
                  future: widget.favoritesManager.getCachedContent(url),
                  builder: (context, contentSnapshot) {
                    if (!contentSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    return _buildFavoriteCard(
                      url: url,
                      title: titleSnapshot.data,
                    );
                  },
                );
              }
              return _buildFavoriteCard(
                url: url,
                title: titleSnapshot.data,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFavoriteCard({
    required String url,
    required String? title,
  }) {
    return FavoriteCard(
      url: url,
      title: title,
      onTap: () => widget.onFavoriteSelected(url),
      onRemove: widget.isOfflineMode ? null : () => _removeFavorite(url),
      isOffline: widget.isOfflineMode,
    );
  }
}