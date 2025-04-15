import 'package:flutter/material.dart';
import 'fullscreen_webview.dart';
import 'favorites_manager.dart';

class HomeWrapper extends StatelessWidget {
  final FavoritesManager favoritesManager;

  const HomeWrapper({super.key, required this.favoritesManager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FullScreenWebView(
          favoritesManager: favoritesManager,
          key: const ValueKey('fullscreen_webview'),
        ),
      ),
    );
  }
}
