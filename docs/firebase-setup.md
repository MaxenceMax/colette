# Configuration Firebase et Apple pour Colette

Tout ce qui doit être créé à la main, dans l'ordre. Les commandes se lancent depuis la racine du projet. Compter environ une heure la première fois, l'essentiel étant l'attente de validation des index et la clé APNs.

## 1. Comptes et outils

| Quoi | Où | Pourquoi |
| --- | --- | --- |
| Compte Google | console.firebase.google.com | Projet Firebase |
| Apple Developer Program (99 €/an) | developer.apple.com | Push notifications sur iPhone réel, signature de l'app |
| Firebase CLI | `npm install -g firebase-tools` puis `firebase login` | Déployer règles, index et fonctions |
| FlutterFire CLI | `dart pub global activate flutterfire_cli` | Générer `lib/firebase_options.dart` et `GoogleService-Info.plist` |
| Node 22 | `node --version` | Compiler et déployer les Cloud Functions |

## 2. Projet Firebase

1. Console Firebase → **Ajouter un projet** → nom `colette` (ou autre). Désactiver Google Analytics : inutile ici.
2. Noter l'**identifiant du projet** (par exemple `colette-a1b2c`). Il sert dans `.firebaserc`.
3. **Plan tarifaire** (icône engrenage → Utilisation et facturation) → passer en **Blaze**. Obligatoire pour Cloud Functions. Le volume de Colette reste dans le quota gratuit.
4. Dans la console Google Cloud du même projet → **Facturation → Budgets et alertes** → créer un budget de **1 €** avec alerte e-mail à 50 % et 100 %.

## 3. Identifiant de bundle iOS

1. Choisir un bundle id définitif, par exemple `fr.montet.colette`. Le placeholder actuel `com.example.colette` ne peut pas être publié ni recevoir de push.
2. Dans Xcode : ouvrir `ios/Runner.xcworkspace` → cible **Runner** → onglet **Signing & Capabilities** :
   - Team : ton équipe Apple Developer.
   - Bundle Identifier : la valeur choisie.
   - **+ Capability → Push Notifications**.
   - **+ Capability → Background Modes** → cocher **Remote notifications**.
3. Xcode crée `ios/Runner/Runner.entitlements` avec `aps-environment`. Le committer.

## 4. Enregistrer l'app iOS dans Firebase

Depuis la racine du projet :

```bash
flutterfire configure --platforms=ios --project=<identifiant-du-projet> --ios-bundle-id=<bundle-id>
```

Cela remplace `lib/firebase_options.dart` (le placeholder) et dépose `ios/Runner/GoogleService-Info.plist`. Committer les deux fichiers : ils ne contiennent pas de secret, les règles Firestore et l'auth protègent les données.

## 5. Authentication

Console Firebase → **Authentication → Commencer → Sign-in method** → activer **Anonyme**. Rien d'autre. L'app ouvre une session anonyme au démarrage, invisible pour vous deux, uniquement pour que Firestore refuse les requêtes non signées.

## 6. Firestore

1. Console Firebase → **Firestore Database → Créer une base de données**.
2. Emplacement : **eur3 (europe-west)** ou **europe-west1**. Choisir une fois pour toutes, c'est définitif.
3. Mode **production** (les règles sont déployées à l'étape 9).
4. Persistance hors ligne : rien à faire, elle est activée par défaut sur iOS.

## 7. Cloud Messaging et clé APNs

1. developer.apple.com → **Certificates, Identifiers & Profiles → Keys → +**.
2. Nom `Colette APNs`, cocher **Apple Push Notifications service (APNs)**, continuer, enregistrer.
3. Télécharger le fichier `.p8` (une seule fois possible) et noter le **Key ID**. Le **Team ID** est en haut à droite de la page Membership.
4. Console Firebase → engrenage → **Paramètres du projet → Cloud Messaging** → section **Configuration de l'application Apple** → **Importer** la clé `.p8`, saisir Key ID et Team ID.

Sans cette étape, les fonctions s'exécutent mais aucun push n'arrive sur les iPhones.

## 8. Fichier `.firebaserc`

Remplacer `REPLACE_WITH_FIREBASE_PROJECT_ID` par l'identifiant du projet, ou lancer :

```bash
firebase use --add
```

## 9. Règles, index et fonctions

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Les deux index composites sur `events` mettent quelques minutes à se construire ; l'onglet Firestore → Index affiche leur état. Tant qu'ils ne sont pas prêts, le dashboard ne trouve pas le dernier bain ni le dernier biberon.

```bash
cd functions && npm install && npm test && cd ..
firebase deploy --only functions
```

Le premier déploiement d'une fonction planifiée active automatiquement Cloud Scheduler, Pub/Sub, Cloud Build et Artifact Registry sur le projet. Si la CLI demande d'activer une API, répondre oui.

## 10. Vérifier sur les deux iPhones

1. Installer l'app sur les deux iPhones (`flutter run --release` ou TestFlight). Le push ne fonctionne pas sur simulateur.
2. iPhone A : « Créer notre foyer ». iPhone B : « Rejoindre avec un code » avec le code affiché dans Réglages de A.
3. Accepter la demande de notifications sur chaque iPhone.
4. Ajouter un événement sur A : B reçoit la notification en quelques secondes.
5. Console Firebase → Firestore → `households/{code}/devices` : chaque iPhone doit avoir un `fcmToken`.

## Récapitulatif des éléments à conserver

- Identifiant du projet Firebase.
- Bundle id iOS.
- Fichier `.p8` APNs (sauvegarde hors du dépôt : impossible à re-télécharger).
- Key ID et Team ID Apple.
