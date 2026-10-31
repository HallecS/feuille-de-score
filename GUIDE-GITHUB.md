# Feuille de score sur GitHub Pages

Dépôt : <https://github.com/HallecS/feuille-de-score>
Appli en ligne : <https://hallecs.github.io/feuille-de-score/>

## Les fichiers

- `feuille-de-score.html` : la source de l'appli. C'est elle qu'on modifie.
- `build-site.ps1` : regénère les fichiers en ligne à partir de la source.
- Les fichiers servis par GitHub Pages, regénérés par `build-site.ps1` :
  - `index.html` ;
  - `manifest.webmanifest` ;
  - `sw.js` (le cache hors connexion) ;
  - les icônes `.png`.

## Activer GitHub Pages (une seule fois)

1. Sur GitHub, ouvre le dépôt.
2. Va dans **Settings** → **Pages**.
3. Règle **Source** sur *Deploy from a branch*.
4. Choisis **Branch** `main`, dossier `/ (root)`, puis clique sur **Save**.
5. Attends 1 à 2 minutes : le lien de l'appli apparaît en haut de la page.

Le dépôt doit être **public** : c'est obligatoire pour utiliser GitHub Pages gratuitement.

## Mettre à jour l'appli

1. Modifie `feuille-de-score.html`.
2. Lance le script qui regénère les fichiers en ligne :

   ```bash
   powershell -NoProfile -File build-site.ps1
   ```

3. Commit puis push : GitHub Desktop, ou `git add -A`, `git commit`, `git push`.

Les téléphones prennent la nouvelle version à la prochaine ouverture avec du réseau.

## L'installer sur le téléphone

- **iPhone** : ouvre le lien dans Safari, puis **Partager** → **Sur l'écran d'accueil**.
- **Android** : ouvre le lien dans Chrome, puis menu **⋮** → **Ajouter à l'écran d'accueil** (ou **Installer l'application**).

Ouvre l'appli une première fois avec du réseau : elle marche ensuite hors connexion.

## L'historique des parties

Les parties restent sur chaque téléphone, elles ne sont pas en ligne. Pour les sauvegarder ou les partager, ouvre **Parties enregistrées** :

- **Exporter** les enregistre dans un fichier.
- **Importer** ajoute les parties d'un fichier, sans créer de doublons.
