import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fullscreen_webview.dart';
import 'favorites_manager.dart';
import 'home_wrapper.dart'; // Import du wrapper que tu viens de créer

void main() async {
  // Initialisation obligatoire de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration du mode d'interface immersive
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [SystemUiOverlay.top],
  );

  // Initialisation des préférences partagées
  final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

  // Création de l'instance du gestionnaire de favoris
  final FavoritesManager favoritesManager = FavoritesManager();

  // Lancement de l'application
  runApp(
    MyApplication(
      favoritesManager: favoritesManager,
      sharedPreferences: sharedPreferences,
    ),
  );
}

class MyApplication extends StatelessWidget {
  final FavoritesManager favoritesManager;
  final SharedPreferences sharedPreferences;

  const MyApplication({
    super.key,
    required this.favoritesManager,
    required this.sharedPreferences,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bo Kay News',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: HomeWrapper( // Utilisation du nouveau wrapper ici
        favoritesManager: favoritesManager,
      ),
    );
  }
}
