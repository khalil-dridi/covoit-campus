<div align="center">

# 🚗 Covoit Campus

### Le covoiturage pensé pour la vie étudiante

Application mobile Flutter de mise en relation autour des trajets et demandes de trajet, avec des espaces dédiés aux passagers, conducteurs et administrateurs.

![Flutter](https://img.shields.io/badge/Flutter-Framework-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-Language-0175C2?logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-Local%20database-003B57?logo=sqlite&logoColor=white)

<img src="docs/screens/Passenger/HomePassengerScreen1.png" width="250" alt="Accueil Passenger de Covoit Campus">

</div>

## Sommaire

- [À propos](#à-propos)
- [Fonctionnalités](#fonctionnalités)
- [Rôles et matrice fonctionnelle](#rôles-et-matrice-fonctionnelle)
- [Aperçu de l’application](#aperçu-de-lapplication)
- [Parcours utilisateur](#-parcours-utilisateur)
- [Architecture](#-architecture)
- [Base de données](#base-de-données)
- [Technologies](#technologies)
- [Structure du projet](#structure-du-projet)
- [Installation et lancement](#installation-et-lancement)
- [Tests](#tests)
- [Sécurité et limites](#sécurité-et-limites)
- [Roadmap](#roadmap)
- [Auteur](#auteur)
- [Licence](#licence)

## À propos

Les déplacements vers le campus peuvent être coûteux ou difficiles à organiser. Covoit Campus propose une application mobile qui permet aux membres de la communauté étudiante de publier des trajets, de rechercher des trajets proposés et d’échanger autour d’une réservation ou d’une demande.

Le dépôt contient une application Flutter avec stockage SQLite sur l’appareil. Les rôles Passenger, Driver et Admin disposent d’interfaces et d’actions distinctes. Le projet s’adresse aux étudiants et à l’équipe qui administre les comptes, trajets et signalements.

## Fonctionnalités

### Passenger

- Inscription, connexion et étape de vérification de compte
- Fil d’accueil communautaire présentant trajets et demandes
- Recherche de trajets avec critères de recherche
- Consultation des détails et réservation de places
- Publication d’une demande de trajet et consultation de ses réservations
- Messagerie liée aux trajets et demandes, avec notifications locales dans l’application
- Profil personnel et consultation de profils publics
- Notation après trajet terminé et signalement d’un utilisateur ou d’un trajet

### Driver

- Fil d’accueil avec trajets et demandes de passagers
- Publication d’un trajet et gestion des trajets publiés
- Gestion des véhicules associés au compte
- Consultation des réservations et traitement de leur statut
- Messagerie, notifications, profil et consultation des notes

### Admin

- Dashboard avec indicateurs issus des données enregistrées
- Consultation et gestion des utilisateurs, trajets et signalements
- Consultation des détails utilisateur et trajet
- Gestion du profil administrateur

## Rôles et matrice fonctionnelle

| Fonctionnalité | Passenger | Driver | Admin |
|---|:---:|:---:|:---:|
| Inscription et connexion | ✅ | ✅ | ✅ |
| Recherche de trajets | ✅ | — | — |
| Réserver / gérer des réservations | ✅ | ✅ | — |
| Publier un trajet | Demande de trajet | ✅ | — |
| Gérer les véhicules | — | ✅ | — |
| Messagerie et notifications | ✅ | ✅ | — |
| Profils | ✅ | ✅ | ✅ |
| Notation | ✅ | ✅ | — |
| Signalements | ✅ | ✅ | ✅ |
| Administration des utilisateurs et trajets | — | — | ✅ |

## Aperçu de l’application

Les captures intégrées ci-dessous sont celles versionnées dans `docs/screens/`. Les noms et leur casse sont conservés tels quels.

### Authentification

<table>
<tr>
<td align="center"><img src="docs/screens/SplashScreen.png" width="150" alt="Écran de démarrage"><br><strong>Démarrage</strong></td>
<td align="center"><img src="docs/screens/WelcomeScreen1.png" width="150" alt="Bienvenue, écran 1"><br><strong>Bienvenue</strong></td>
<td align="center"><img src="docs/screens/welcomeScreen2.png" width="150" alt="Bienvenue, écran 2"><br><strong>Présentation</strong></td>
<td align="center"><img src="docs/screens/WelcomeScreen3.png" width="150" alt="Bienvenue, écran 3"><br><strong>Découverte</strong></td>
<td align="center"><img src="docs/screens/LoginScreen.png" width="150" alt="Connexion"><br><strong>Connexion</strong></td>
<td align="center"><img src="docs/screens/SignUpScreen.png" width="150" alt="Inscription"><br><strong>Inscription</strong></td>
<td align="center"><img src="docs/screens/VerificationScreen.png" width="150" alt="Vérification"><br><strong>Vérification</strong></td>
</tr>
</table>

### Passenger

#### 🏠 Accueil et recherche

<table>
<tr>
<td align="center"><img src="docs/screens/Passenger/HomePassengerScreen1.png" width="170" alt="Accueil Passenger"><br><strong>Accueil</strong></td>
<td align="center"><img src="docs/screens/Passenger/HomePassengerSrenn2.png" width="170" alt="Accueil Passenger, variante"><br><strong>Fil communautaire</strong></td>
<td align="center"><img src="docs/screens/Passenger/SearchPassengerScreen.png" width="170" alt="Recherche de trajets"><br><strong>Recherche</strong></td>
<td align="center"><img src="docs/screens/Passenger/PublishSearchTripPassengerScreen.png" width="170" alt="Demande de trajet"><br><strong>Demande de trajet</strong></td>
</tr>
</table>

#### 🚗 Trajets et réservations

<table>
<tr>
<td align="center"><img src="docs/screens/Passenger/TripsDetailsPassengerScreen.png" width="170" alt="Détails du trajet"><br><strong>Détails du trajet</strong></td>
<td align="center"><img src="docs/screens/Passenger/TripReservationPassengerScreen.png" width="170" alt="Réservation"><br><strong>Réserver</strong></td>
<td align="center"><img src="docs/screens/Passenger/MyReservationsPassengerScreen.png" width="170" alt="Mes réservations"><br><strong>Mes réservations</strong></td>
<td align="center"><img src="docs/screens/Passenger/ReservationDetailsPassengerScreen.png" width="170" alt="Détails de réservation"><br><strong>Détails</strong></td>
</tr>
</table>

#### 💬 Messagerie et notifications

<table>
<tr>
<td align="center"><img src="docs/screens/Passenger/MessagesPassengerScreen.png" width="170" alt="Messages"><br><strong>Conversations</strong></td>
<td align="center"><img src="docs/screens/Passenger/ConversationPassengerScreen.png" width="170" alt="Conversation"><br><strong>Conversation</strong></td>
<td align="center"><img src="docs/screens/Passenger/NotificationsDropDownPassengerScreen.png" width="170" alt="Notifications"><br><strong>Notifications</strong></td>
</tr>
</table>

#### 👤 Profil et 🚨 signalement

<table>
<tr>
<td align="center"><img src="docs/screens/Passenger/MyProfilePassengerScreen.png" width="170" alt="Profil Passenger"><br><strong>Profil</strong></td>
<td align="center"><img src="docs/screens/Passenger/MyProfilePassengerScreen2.png" width="170" alt="Profil Passenger, détails"><br><strong>Profil, détails</strong></td>
<td align="center"><img src="docs/screens/Passenger/ProfileInspectionPassengerScreen.png" width="170" alt="Profil public"><br><strong>Profil consulté</strong></td>
<td align="center"><img src="docs/screens/Passenger/ReportsPassengerScreen.png" width="170" alt="Signalement"><br><strong>Signalement</strong></td>
</tr>
</table>

### Driver

#### 🏠 Home et 🚗 publication

<table>
<tr>
<td align="center"><img src="docs/screens/Driver/HomeDriverScreen.png" width="170" alt="Accueil Driver"><br><strong>Accueil</strong></td>
<td align="center"><img src="docs/screens/Driver/PublishTripDriverScreen1.png" width="170" alt="Publication de trajet, étape 1"><br><strong>Publication · 1</strong></td>
<td align="center"><img src="docs/screens/Driver/PublishTripDriverScreen2.png" width="170" alt="Publication de trajet, étape 2"><br><strong>Publication · 2</strong></td>
<td align="center"><img src="docs/screens/Driver/PublishTripDriverScreen3.png" width="170" alt="Publication de trajet, étape 3"><br><strong>Publication · 3</strong></td>
</tr>
</table>

#### 📋 Trajets, réservations et profil

<table>
<tr>
<td align="center"><img src="docs/screens/Driver/MytripsDriversScreen.png" width="170" alt="Mes trajets Driver"><br><strong>Mes trajets</strong></td>
<td align="center"><img src="docs/screens/Driver/TripDetailsDriverScreen.png" width="170" alt="Détails du trajet Driver"><br><strong>Détails</strong></td>
<td align="center"><img src="docs/screens/Driver/TripUpdateDriverScreen.png" width="170" alt="Modification du trajet"><br><strong>Modification</strong></td>
<td align="center"><img src="docs/screens/Driver/TripReservationListDriverScreen.png" width="170" alt="Réservations du trajet"><br><strong>Réservations</strong></td>
</tr>
<tr>
<td align="center"><img src="docs/screens/Driver/MessagesDriverScreen.png" width="170" alt="Messages Driver"><br><strong>Messages</strong></td>
<td align="center"><img src="docs/screens/Driver/ProfileDriverScreen1.png" width="170" alt="Profil Driver"><br><strong>Profil</strong></td>
<td align="center"><img src="docs/screens/Driver/ProfileDriverScreen2.png" width="170" alt="Profil Driver, détails"><br><strong>Profil, détails</strong></td>
</tr>
</table>

### Admin

#### 📊 Dashboard et 👥 utilisateurs

<table>
<tr>
<td align="center"><img src="docs/screens/Admin/DashboardAdminScreen.png" width="170" alt="Dashboard Admin"><br><strong>Dashboard</strong></td>
<td align="center"><img src="docs/screens/Admin/DashboardAdminScreen2.png" width="170" alt="Dashboard Admin, vue complémentaire"><br><strong>Indicateurs</strong></td>
<td align="center"><img src="docs/screens/Admin/UserManagementAdminScreen.png" width="170" alt="Gestion des utilisateurs"><br><strong>Utilisateurs</strong></td>
<td align="center"><img src="docs/screens/Admin/UserDetailsAdminScreen.png" width="170" alt="Détails utilisateur"><br><strong>Détails utilisateur</strong></td>
</tr>
</table>

#### 🚗 Trajets, 🚨 signalements et profil

<table>
<tr>
<td align="center"><img src="docs/screens/Admin/TripManagementAdminScreen.png" width="170" alt="Gestion des trajets"><br><strong>Trajets</strong></td>
<td align="center"><img src="docs/screens/Admin/TripDetailsAdminScreen.png" width="170" alt="Détails du trajet"><br><strong>Détails trajet</strong></td>
<td align="center"><img src="docs/screens/Admin/ReportAdminScreen.png" width="170" alt="Gestion des signalements"><br><strong>Signalements</strong></td>
<td align="center"><img src="docs/screens/Admin/ProfileAdminScreen.png" width="170" alt="Profil Admin"><br><strong>Profil Admin</strong></td>
</tr>
</table>

## 🔄 Parcours utilisateur

```mermaid
flowchart LR
    A[Connexion ou inscription] --> B{Rôle du compte}
    B -->|Passenger| P[Accueil et recherche]
    P --> PD[Détails du trajet]
    PD --> R[Réservation]
    P --> D[Publier une demande]
    R --> PM[Suivre les réservations et échanger]
    D --> PM
    B -->|Driver| H[Accueil communautaire]
    H --> T[Publier ou gérer un trajet]
    T --> BR[Gérer les réservations]
    BR --> M[Échanger avec les passagers]
    B -->|Admin| AD[Dashboard]
    AD --> U[Utilisateurs]
    AD --> AT[Trajets]
    AD --> AR[Signalements]
```

Les parcours représentent les écrans et actions reliés dans l’application. La gestion d’un trajet ou d’une réservation dépend de son statut.

## 🏗️ Architecture

L’application suit une organisation par écrans, modèles, repositories et accès centralisé à la base de données. Les repositories utilisent `DatabaseHelper` et `sqflite`; l’interface Flutter consomme leurs données.

```mermaid
flowchart TB
    UI[Flutter UI\nScreens et Widgets] --> RP[Repositories]
    RP --> MD[Models]
    RP --> DH[DatabaseHelper]
    DH --> DB[(SQLite local\ncovoit_campus.db)]
    UI --> AS[Assets images]
```

Les interfaces sont séparées sous `screens/passenger`, `screens/driver`, `screens/admin` et `screens/shared`. Les trois espaces principaux sont assemblés par des shells avec navigation dédiée.

## Base de données

`DatabaseHelper` crée la base SQLite `covoit_campus.db`, active les clés étrangères et gère les migrations jusqu’à la version 5. Les tables définies couvrent notamment :

- comptes utilisateurs et véhicules;
- préférences de trajet;
- trajets, demandes de trajet et réservations;
- messages et notifications;
- notes et signalements;
- contacts d’urgence et partages de trajet.

Les données sont stockées localement sur l’appareil. Le dépôt ne configure pas de synchronisation distante.

## Technologies

| Domaine | Outils présents |
|---|---|
| Application | Flutter, Dart |
| Persistance | SQLite via `sqflite` |
| Chemins et dates | `path`, `intl` |
| Empreinte de mot de passe | `crypto` (SHA-256 dans le code actuel) |
| Tests | `flutter_test`, `sqflite_common_ffi` |
| Qualité de code | `flutter_lints` |

## Structure du projet

```text
.
├── assets/images/          # Images embarquées
├── docs/screens/           # Captures d’écran documentées ci-dessus
├── lib/
│   ├── database/           # Initialisation et migrations SQLite
│   ├── models/             # Modèles de données
│   ├── repositories/       # Accès et logique de données
│   ├── screens/
│   │   ├── admin/
│   │   ├── driver/
│   │   ├── passenger/
│   │   └── shared/
│   ├── utils/              # Utilitaires, dont le hachage
│   ├── widgets/            # Composants réutilisables
│   └── main.dart
├── test/                   # Tests Flutter présents dans le dépôt
├── android/
├── ios/
├── analysis_options.yaml
└── pubspec.yaml
```

## Installation et lancement

### Prérequis

- Flutter installé et disponible dans le `PATH`;
- un émulateur ou appareil Android/iOS configuré;
- les outils de plateforme requis par Flutter pour la cible choisie.

### Démarrer l’application

```bash
git clone <URL_DU_DEPOT>
cd covoit_campus
flutter pub get
flutter run
```

Remplacez `<URL_DU_DEPOT>` par l’adresse Git du dépôt. Au démarrage, l’application initialise SQLite et applique ses migrations.

## Tests

Des tests Flutter sont présents dans `test/`, couvrant notamment les utilisateurs, les signalements, les notifications, les demandes avec messagerie et les interfaces Admin. Pour les exécuter localement :

```bash
flutter test
```

Aucun workflow GitHub Actions n’est présent dans le dépôt au moment de la rédaction.

## Sécurité et limites

- L’application utilise une base SQLite locale; aucun backend ou service cloud n’est configuré dans le dépôt.
- L’écran de vérification de compte est implémenté, mais aucun fournisseur d’envoi d’e-mail n’est déclaré dans `pubspec.yaml`.
- Le hachage des mots de passe utilise SHA-256 sans sel dédié. Pour un déploiement réel, remplacer ce mécanisme par une solution de hachage adaptée aux mots de passe et revoir la gestion du compte administrateur initial.
- Les tables de contacts d’urgence et de partage existent dans le schéma; leur présence seule ne signifie pas qu’un parcours utilisateur complet est exposé.
- Aucune licence n’est déclarée dans les fichiers du dépôt.

## Roadmap

Aucune roadmap officielle n’est enregistrée dans le dépôt. Les améliorations ci-dessous sont des pistes possibles, et non des fonctionnalités annoncées comme engagées :

- connecter l’application à un backend sécurisé pour la synchronisation multi-appareils;
- intégrer un service de vérification d’adresse e-mail;
- renforcer le stockage et la vérification des mots de passe;
- définir et publier une politique de confidentialité et une licence adaptées au produit.

## Auteur

Projet **Covoit Campus**. Les informations de contact et de contribution ne sont pas précisées dans le dépôt.

## Licence

Aucune licence n’est actuellement fournie. Tous droits réservés par défaut; ajoutez un fichier `LICENSE` avant toute redistribution selon les conditions souhaitées.
