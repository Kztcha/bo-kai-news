import 'package:flutter/material.dart';

/// Widget personnalisé pour afficher un favori avec son titre et son favicon
class FavoriteCard extends StatelessWidget {
  final String url;
  final String? title;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final Color? cardColor;
  final bool isOffline;

  const FavoriteCard({
    super.key,
    required this.url,
    required this.onTap,
    this.title,
    this.onRemove,
    this.cardColor,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: cardColor ?? Theme.of(context).cardColor,
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Favicon du site
              _buildFavicon(),
              const SizedBox(width: 12),
              // Contenu textuel
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre de l'article (prioritaire) ou titre généré depuis l'URL
                    Text(
                      _getDisplayTitle(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Indicateur hors ligne si nécessaire
                    if (isOffline) _buildOfflineIndicator(context),
                  ],
                ),
              ),
              // Bouton de suppression (masqué en mode hors ligne)
              if (onRemove != null && !isOffline) _buildRemoveButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit le favicon du site
  Widget _buildFavicon() {
    return Image.network(
      'https://www.google.com/s2/favicons?domain=$url',
      width: 32,
      height: 32,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.public, size: 20),
        );
      },
    );
  }

  /// Construit le bouton de suppression
  Widget _buildRemoveButton() {
    return IconButton(
      icon: const Icon(Icons.close, size: 20),
      onPressed: onRemove,
      splashRadius: 20,
      tooltip: 'Supprimer des favoris',
    );
  }

  /// Construit l'indicateur hors ligne
  Widget _buildOfflineIndicator(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.signal_wifi_off,
          size: 14,
          color: Colors.orange,
        ),
        const SizedBox(width: 4),
        Text(
          'Disponible hors ligne',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  /// Obtient le titre à afficher
  String _getDisplayTitle() {
    // Priorité au titre stocké, puis extraction depuis l'URL
    return title ?? _extractArticleTitleFromUrl(url);
  }

  /// Extrait un titre d'article depuis l'URL (sans le nom de domaine)
  String _extractArticleTitleFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // Prend le dernier segment non vide du chemin
      final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty);
      if (pathSegments.isNotEmpty) {
        // Capitalise la première lettre et remplace les tirets par des espaces
        final lastSegment = pathSegments.last;
        return lastSegment
            .replaceAll('-', ' ')
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1)
            : '')
            .join(' ');
      }
      return 'Article favori';
    } catch (e) {
      return 'Article favori';
    }
  }
}