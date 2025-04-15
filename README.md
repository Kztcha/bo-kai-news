# **Rapport Technique - Évolution de l'Application Bo Kay News**

## **1. Introduction**

Ce document compare deux versions de l'application **Bo Kay News** :

- **Version Initiale (V1)** : Une application de lecture d'actualités basique
- **Version Améliorée (V2)** : Une refonte complète avec mode hors ligne, gestion des favoris et UI avancée

**Objectif** : Mettre en évidence les différences techniques et fonctionnelles entre les deux versions.

---

## **2. Comparaison des Fonctionnalités**

| **Fonctionnalité** | **Version Initiale (V1)** | **Version Améliorée (V2)** |
| --- | --- | --- |
| **Gestion des Favoris** | ❌ Absente | ✅ Contenu HTML + titres sauvegardés |
| **Mode Hors Ligne** | ❌ Non supporté | ✅ Lecture des articles en cache |
| **Navigation** | WebView standard | Immersive + boutons flottants |
| **Cache des Articles** | ❌ Aucun | ✅ 30 jours de rétention |
| **Gestion d'État** | `setState` simple | Centralisée via `FavoritesManager` |
| **UI/UX** | Material Design basique | Animations et feedbacks visuels |

---

## **3. Analyse Technique**

### **3.1. Version Initiale (V1)**

**Fichiers clés** :

- `main.dart`, `news_service.dart`, `article_model.dart`, `webview_screen.dart`

**Fonctionnalités** :

- Affichage des articles via `WebView` (`webview_screen.dart`)
- Récupération des données depuis NewsAPI et Antilla (`news_service.dart`)
- Pas de système de favoris ni de cache

**Limitations** :

- Pas de persistance des données
- Impossible de lire les articles hors connexion
- UI basique sans interactions avancées

---

### **3.2. Version Améliorée (V2)**

**Nouveaux fichiers clés** :

- `favorites_manager.dart`, `offline_page.dart`, `favorite_card.dart`, `fullscreen_webview.dart`

**Améliorations majeures** :

#### **a. Gestion des Favoris et Cache**

- **`favorites_manager.dart`** :
  - Stocke les URLs, titres et contenu HTML via `SharedPreferences`
  - Nettoie automatiquement le cache expiré
    
    ```dart
    Future<void> cachePageContent(String url, String htmlContent, {String? title}) async {
    await _prefs.setString(_cacheContentPrefix + url, htmlContent);
    }
    ```
    

#### **b. Mode Hors Ligne**

- **`offline_page.dart`** :
  - Affiche les articles sauvegardés sans connexion
    
    ```dart
    final cachedContent = await widget.favoritesManager.getCachedContent(url);
    ```
    

#### **c. UI/UX Avancée**

- **`favorite_card.dart`** :
  - Indicateur visuel pour le mode hors ligne
    
    ```dart
    Icon(Icons.signal_wifi_off, color: Colors.orange)
    ```
    
- **`fullscreen_webview.dart`** :
  - Navigation immersive avec menu flottant
    
    ```dart
    Positioned(right: 16, child: _buildFloatingMenu())
    ```
    

---

## **4. Schéma Architectural (V2)**

```
bo_kay_news/
└── lib/
    ├── favorites_manager.dart       # Gestionnaire des favoris
    ├── fullscreen_webview.dart      # WebView améliorée
    ├── home_wrapper.dart            # Wrapper pour l'écran principal
    ├── main.dart                    # Point d'entrée de l'application
    ├── offline_error_page.dart      # Page d'erreur hors ligne
    ├── offline_page.dart            # Page affichée lorsque hors ligne
    └── widgets/                     # Dossier contenant des widgets réutilisables
        ├── favorite_card.dart       # Carte de favori interactive
        └── favorites_panel.dart     # Panneau de gestion des favoris
```

---

## **5. Avantages de la V2**

✅ **Expérience Utilisateur Améliorée** :

- Navigation fluide, animations et feedbacks
- Accès aux articles même sans internet

✅ **Robustesse Technique** :

- Cache auto-nettoyé après 30 jours
- Gestion centralisée des favoris

✅ **Maintenabilité** :

- Code modulaire et séparation claire des responsabilités

---

## **6. Conclusion**

La **V2** représente une **évolution majeure** avec :

- Un **système de favoris persistant**
- Une **expérience offline complète**
- Une **UI plus interactive**

Ces améliorations en font une application plus **complète, performante et conviviale**.

