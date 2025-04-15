import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../favorites_manager.dart';
import 'widgets/favorites_panel.dart';

class OfflineErrorPage extends StatelessWidget {
  final String requestedUrl;
  final FavoritesManager favoritesManager;
  final VoidCallback onRetryConnection;
  final VoidCallback onReturnToHome;

  const OfflineErrorPage({
    super.key,
    required this.requestedUrl,
    required this.favoritesManager,
    required this.onRetryConnection,
    required this.onReturnToHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildErrorHeader(context),
          Expanded(
            child: _buildErrorContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 24, color: Colors.orange),
              const SizedBox(width: 12),
              Text(
                'Contenu non disponible hors ligne',
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

  Widget _buildErrorContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.signal_wifi_off,
            size: 64,
            color: Colors.orange,
          ),
          _buildActionButtons(context),
          _buildAvailableContentSection(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return const SizedBox.shrink(); // Masque complètement la section
  }

  Widget _buildAvailableContentSection(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Contenus disponibles hors ligne',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vous pouvez consulter ces articles sans connexion :',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: FavoritesPanel(
            favoritesManager: favoritesManager,
            onFavoriteSelected: (url) {
              Navigator.of(context).pop(url);
            },
            isOfflineMode: true,
          ),
        ),
      ],
    );
  }

  String get _simplifiedRequestedUrl {
    try {
      final uri = Uri.parse(requestedUrl);
      return uri.host + (uri.path.isEmpty ? '' : uri.path.split('/').first);
    } catch (e) {
      return requestedUrl.length > 30
          ? '${requestedUrl.substring(0, 30)}...'
          : requestedUrl;
    }
  }
}