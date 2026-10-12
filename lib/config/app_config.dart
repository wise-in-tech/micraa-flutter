import 'package:flutter/foundation.dart';

/// IP de votre Mac pour les tests locaux
const String kMacLocalIp = '192.168.129.2';

/// URLs publiques de production. Les services ajoutent eux-mêmes le préfixe /api.
const String kApiBaseUrl = 'https://micraa.be';
const String kLiveKitWsUrl = 'wss://livekit.micraa.be';

/// Google Sign-In : ID client OAuth de type "Web application" (Google Cloud
/// Console). Passé comme serverClientId pour que l'ID token ait ce client comme
/// audience ; le backend doit l'avoir dans GOOGLE_AUTH_CLIENT_IDS.
/// Vide = bouton Google affiché mais renvoie une erreur de configuration.
const String kGoogleServerClientId = '';

/// Palette de l'application : thème sombre inspiré d'une مقرأة (lieu de
/// récitation/étude du Coran) - vert profond islamique, or pour les accents,
/// fond charbon.
const kPrimaryColor = 0xFF0F5C4E; // vert profond (motif d'en-tête, boutons principaux)
const kPrimaryDarkColor = 0xFF0A3D33; // vert plus foncé (base du motif géométrique)
const kAccentColor = 0xFFC9A227; // or (badges, mise en valeur)
const kSuccessColor = 0xFF1FA37A; // vert-émeraude (statut "جارية"/live)
const kDangerColor = 0xFFD9534F; // rouge doux (fin de session, alertes)
const kBackgroundColor = 0xFF12161C; // fond d'écran, charbon profond
const kSurfaceColor = 0xFF1C222B; // fond des cartes/panneaux
const kSurfaceVariantColor = 0xFF262E39; // éléments légèrement plus clairs sur une surface
const kTextPrimaryColor = 0xFFF5F5F0;
const kTextSecondaryColor = 0xFFA9B0BC;
