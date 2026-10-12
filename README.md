# Micraa Flutter

Application mobile Flutter pour les classes audio en direct.

## Structure du projet

```
lib/
├── main.dart                     # Entry point + Provider
├── config/
│   └── app_config.dart           # URLs API + LiveKit, constantes
├── models/
│   ├── user_model.dart           # UserModel (teacher/student)
│   ├── live_class_model.dart     # LiveClassModel (SCHEDULED/LIVE/ENDED)
│   └── join_class_response.dart  # Token + roomName LiveKit
├── services/
│   ├── api_service.dart          # HTTP REST calls → Spring Boot
│   └── livekit_service.dart      # WebRTC audio via livekit_client SDK
├── providers/
│   └── app_state.dart            # ChangeNotifier (user courant, chargement)
└── screens/
    ├── select_user_screen.dart   # Sélection / création utilisateur
    ├── classes_screen.dart       # Liste classes + actions teacher/student
    └── live_room_screen.dart     # Room audio + indicateurs speaking
```

## Prérequis

- Flutter ≥ 3.10
- Dart ≥ 3.0
- Backend Micraa démarré (`docker-compose up -d`)
- Xcode (iOS) ou Android Studio (Android)

## Installation

```bash
cd micraa_flutter
flutter pub get
```

## Lancer l'application

### Sur simulateur iOS
```bash
flutter run
```

### Sur Android
```bash
flutter run
```

> ⚠️ Sur device physique, changez `kApiBaseUrl` dans `lib/config/app_config.dart`
> avec l'IP de votre machine : `http://192.168.x.x:8080`

## Flux d'utilisation

### Professeur
1. Sélectionner un profil Professeur
2. Créer une nouvelle classe (bouton +)
3. Appuyer sur **Démarrer** pour passer la classe en LIVE
4. Appuyer sur **Rejoindre** pour entrer dans la session audio
5. Parler — l'indicateur passe au vert chez les étudiants

### Étudiant
1. Sélectionner un profil Étudiant
2. Voir les classes assignées
3. Appuyer sur **Rejoindre** dès qu'une classe est LIVE
4. Entendre le professeur, utiliser le bouton micro

## Configuration réseau

| Variable | Valeur locale | Valeur device physique |
|---|---|---|
| `kApiBaseUrl` | `http://localhost:8080` | `http://192.168.x.x:8080` |
| `kLiveKitUrl` | `ws://localhost:7880` | `ws://192.168.x.x:7880` |

Modifier dans `lib/config/app_config.dart`.

## Publier sur Google Play (Android)

Une version destinée à Google Play doit être signée avec une clé release, jamais avec la clé debug.

1. Créer une clé de téléversement et conserver le fichier `.jks` en lieu sûr :

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias micraa
```

2. Créer `android/key.properties` à partir de `android/key.properties.example`, puis renseigner les mots de passe, l’alias et le chemin absolu vers `upload-keystore.jks`. Ce fichier et la clé ne doivent jamais être commités; sauvegardez-les de façon sécurisée.

3. Générer le bundle à importer dans Play Console :

```bash
flutter build appbundle --release
```

Le fichier généré se trouve dans `build/app/outputs/bundle/release/app-release.aab`. Pour mettre à jour une application existante, utilisez la même clé de téléversement que pour les versions précédentes.
