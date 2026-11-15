<!-- #!/usr/bin/env markdown
-*- coding: utf-8 -*-
region header
Copyright Torben Sickert (info["~at~"]tsickert.com) 16.12.2012

License
-------

This library written by Torben Sickert stands under a creative commons naming
4.0 international license.
See https://creativecommons.org/licenses/by/4.0/deed.de
endregion -->

<!--|deDE:Einsatzmöglichkeiten-->
<!--|frFR:Cas d'utilisation-->
Use case
--------

A composite GitHub action which releases a new version of a repository. It
determines and commits the new version, tags it and publishes the package
depending on the files the repository contains: a "package.json" is published
to the npm registry, a "PKGBUILD" to the arch user repository (AUR). A
repository can contain both.
<!--deDE:
    Eine zusammengesetzte GitHub-Action, die eine neue Version eines
    Repositorys veröffentlicht. Sie ermittelt und committet die neue Version,
    taggt sie und veröffentlicht das Paket abhängig von den Dateien des
    Repositorys: eine "package.json" in der npm-Registry, ein "PKGBUILD" im
    Arch User Repository (AUR). Ein Repository kann beides enthalten.
-->
<!--frFR:
    Une action GitHub composite qui publie une nouvelle version d'un dépôt.
    Elle détermine et committe la nouvelle version, la tague et publie le
    paquet selon les fichiers du dépôt : un "package.json" est publié dans le
    registre npm, un "PKGBUILD" dans l'Arch User Repository (AUR). Un dépôt
    peut contenir les deux.
-->

<div class="wd-table-of-contents">
    <h2 id="content">Content<!--deDE:Inhalt--><!--frFR:Contenu--></h2>
    <!--wd-table-of-contents-->
</div>

<!--|deDE:Verwendung-->
<!--|frFR:Utilisation-->
Usage
-----

The action checks out the repository itself, so a job only needs this one
step. The following workflow releases a new version when it is started
manually from the "Actions" tab:
<!--deDE:
    Die Action checkt das Repository selbst aus, ein Job braucht also nur
    diesen einen Schritt. Der folgende Workflow veröffentlicht eine neue
    Version, wenn er manuell im Reiter "Actions" gestartet wird:
-->
<!--frFR:
    L'action récupère elle-même le dépôt, un job n'a donc besoin que de
    cette seule étape. Le workflow suivant publie une nouvelle version
    lorsqu'il est lancé manuellement depuis l'onglet "Actions" :
-->

```yaml
name: Build package and push

on:
  workflow_dispatch:
    inputs:
      debug:
        description: Sets "NODE_ENV" to "debug".
        default: false
        type: boolean
      type:
        description: Sets semantic version update type.
        default: patch
        type: choice
        options:
          - major
          - minor
          - patch
          - candidate

permissions:
  # Required for "Trusted Publishing" to npm.
  id-token: write
  # Required to push the release commit and tag.
  contents: write

jobs:
  main:
    runs-on: ubuntu-latest
    container: node:lts

    steps:
      - uses: thaibault/build-package-push-action@main
        id: build-package-and-push
        with:
          debug: ${{ inputs.debug || '' }}
          aur-ssh-private-key: ${{ secrets.AUR_SSH_PRIVATE_KEY }}
          type: ${{ inputs.type || 'patch' }}

      - name: Print determined version.
        run: echo Newly determined version is \"${{ steps.build-package-and-push.outputs.version }}\".
        shell: bash
```

A release runs through the following steps:
<!--deDE:Eine Veröffentlichung durchläuft die folgenden Schritte:-->
<!--frFR:Une publication passe par les étapes suivantes :-->

1. [prepare-release-action](https://github.com/thaibault/prepare-release-action) checks out the repository, installs the dependencies if a "package.json" exists and determines the new version from "package.json", "PKGBUILD" or the existing tags.<!--deDE:[prepare-release-action](https://github.com/thaibault/prepare-release-action) checkt das Repository aus, installiert die Abhängigkeiten, falls eine "package.json" existiert, und ermittelt die neue Version aus "package.json", "PKGBUILD" oder den vorhandenen Tags.--><!--frFR:[prepare-release-action](https://github.com/thaibault/prepare-release-action) récupère le dépôt, installe les dépendances si un "package.json" existe et détermine la nouvelle version à partir de "package.json", "PKGBUILD" ou des tags existants.-->
2. The changed manifest files are committed as "Publish new version "v&lt;version&gt;"." and tagged as "v&lt;version&gt;".<!--deDE:Die geänderten Manifest-Dateien werden als "Publish new version "v&lt;version&gt;"." committet und als "v&lt;version&gt;" getaggt.--><!--frFR:Les fichiers manifestes modifiés sont committés sous "Publish new version "v&lt;version&gt;"." et tagués "v&lt;version&gt;".-->
3. With a "package.json" the package is published to the npm registry, see [npm registry](#npm-registry).<!--deDE:Mit einer "package.json" wird das Paket in der npm-Registry veröffentlicht, siehe [npm-Registry](#npm-registry).--><!--frFR:Avec un "package.json", le paquet est publié dans le registre npm, voir [Registre npm](#npm-registry).-->
4. With a "PKGBUILD" the package is published to the AUR, see [Arch user repository](#arch-user-repository).<!--deDE:Mit einem "PKGBUILD" wird das Paket im AUR veröffentlicht, siehe [Arch User Repository](#arch-user-repository).--><!--frFR:Avec un "PKGBUILD", le paquet est publié dans l'AUR, voir [Arch User Repository](#arch-user-repository).-->

<!--|deDE:Eingaben-->
<!--|frFR:Entrées-->
Inputs
------

- "type": "major", "minor", "patch" (default) or "candidate". A candidate keeps the version and appends "-&lt;number&gt;", see [Release candidates](#release-candidates).<!--deDE:"type": "major", "minor", "patch" (Standard) oder "candidate". Ein Kandidat behält die Version und hängt "-&lt;number&gt;" an, siehe [Release-Kandidaten](#release-candidates).--><!--frFR:"type": "major", "minor", "patch" (par défaut) ou "candidate". Une version candidate garde la version et ajoute "-&lt;number&gt;", voir [Versions candidates](#release-candidates).-->
- "debug": "true" sets "NODE_ENV" to "debug" while installing dependencies and publishing to npm. Default "false".<!--deDE:"debug": "true" setzt "NODE_ENV" beim Installieren der Abhängigkeiten und beim Veröffentlichen auf npm auf "debug". Standard "false".--><!--frFR:"debug": "true" met "NODE_ENV" à "debug" lors de l'installation des dépendances et de la publication sur npm. Par défaut "false".-->
- "npm-token": token for npm. Not used anymore since "Trusted Publishing" is used.<!--deDE:"npm-token": Token für npm. Wird nicht mehr verwendet, da "Trusted Publishing" genutzt wird.--><!--frFR:"npm-token": jeton pour npm. N'est plus utilisé puisque "Trusted Publishing" est employé.-->
- "aur-ssh-private-key": private SSH key registered in the AUR account. Without it nothing is published to the AUR.<!--deDE:"aur-ssh-private-key": im AUR-Konto registrierter privater SSH-Schlüssel. Ohne ihn wird nichts im AUR veröffentlicht.--><!--frFR:"aur-ssh-private-key": clé SSH privée enregistrée dans le compte AUR. Sans elle, rien n'est publié dans l'AUR.-->
- "aur-commit-name": author name of AUR commits. Defaults to the actor triggering the workflow.<!--deDE:"aur-commit-name": Autorenname der AUR-Commits. Standardmäßig der Akteur, der den Workflow auslöst.--><!--frFR:"aur-commit-name": nom d'auteur des commits AUR. Par défaut, l'acteur qui déclenche le workflow.-->
- "aur-commit-email": author email address of AUR commits. Defaults to "&lt;actor&gt;@users.noreply.github.com".<!--deDE:"aur-commit-email": Autoren-E-Mail-Adresse der AUR-Commits. Standardmäßig "&lt;actor&gt;@users.noreply.github.com".--><!--frFR:"aur-commit-email": adresse e-mail d'auteur des commits AUR. Par défaut "&lt;actor&gt;@users.noreply.github.com".-->

<!--|deDE:Ausgaben-->
<!--|frFR:Sorties-->
Outputs
-------

- "version": the newly released version including the "v" prefix, e.g. "v1.0.3" or "v1.0.3-1".<!--deDE:"version": die neu veröffentlichte Version inklusive des Präfixes "v", z. B. "v1.0.3" oder "v1.0.3-1".--><!--frFR:"version": la version nouvellement publiée, préfixe "v" inclus, par exemple "v1.0.3" ou "v1.0.3-1".-->

<!--|deDE:npm-Registry-->
<!--|frFR:Registre npm-->
npm registry
------------

If the repository contains a "package.json", the package is published to
"https://registry.npmjs.org" via "npm publish". Regular versions get the
dist-tag "latest", release candidates the dist-tag "candidate", so "npm
install" keeps resolving to the last regular version.
<!--deDE:
    Enthält das Repository eine "package.json", wird das Paket per "npm
    publish" auf "https://registry.npmjs.org" veröffentlicht. Reguläre
    Versionen erhalten das Dist-Tag "latest", Release-Kandidaten das Dist-Tag
    "candidate", sodass "npm install" weiterhin die letzte reguläre Version
    auflöst.
-->
<!--frFR:
    Si le dépôt contient un "package.json", le paquet est publié sur
    "https://registry.npmjs.org" via "npm publish". Les versions régulières
    reçoivent le dist-tag "latest", les versions candidates le dist-tag
    "candidate", de sorte que "npm install" continue de résoudre la dernière
    version régulière.
-->

Authentication works via npm's "Trusted Publishing" without a token: register
the repository and the workflow file as trusted publisher in the package
settings on npmjs.com and grant the workflow "id-token: write".
<!--deDE:
    Die Authentifizierung erfolgt über npms "Trusted Publishing" ohne Token:
    Registrieren Sie das Repository und die Workflow-Datei in den
    Paket-Einstellungen auf npmjs.com als Trusted Publisher und geben Sie dem
    Workflow "id-token: write".
-->
<!--frFR:
    L'authentification passe par le "Trusted Publishing" de npm, sans jeton :
    enregistrez le dépôt et le fichier de workflow comme éditeur de confiance
    dans les paramètres du paquet sur npmjs.com et accordez au workflow
    "id-token: write".
-->

<!--|deDE:Arch User Repository-->
<!--|frFR:Arch User Repository-->
Arch user repository
--------------------

If the repository contains a "PKGBUILD" and "aur-ssh-private-key" is given,
each regular release is published to the AUR:
<!--deDE:
    Enthält das Repository ein "PKGBUILD" und ist "aur-ssh-private-key"
    gesetzt, wird jede reguläre Version im AUR veröffentlicht:
-->
<!--frFR:
    Si le dépôt contient un "PKGBUILD" et que "aur-ssh-private-key" est
    défini, chaque version régulière est publiée dans l'AUR :
-->

1. "pkgver" is set to the new version and "pkgrel" to "1". With a "package.json" its version is the source of truth, otherwise the current "pkgver" is incremented.<!--deDE:"pkgver" wird auf die neue Version und "pkgrel" auf "1" gesetzt. Mit einer "package.json" ist deren Version maßgeblich, sonst wird das aktuelle "pkgver" erhöht.--><!--frFR:"pkgver" est mis à la nouvelle version et "pkgrel" à "1". Avec un "package.json", sa version fait foi, sinon le "pkgver" actuel est incrémenté.-->
2. The action waits up to 20 minutes until every remote source is downloadable, since a just published npm package or tag archive may need some time to become available.<!--deDE:Die Action wartet bis zu 20 Minuten, bis jede entfernte Quelle herunterladbar ist, da ein gerade veröffentlichtes npm-Paket oder Tag-Archiv etwas Zeit brauchen kann.--><!--frFR:L'action attend jusqu'à 20 minutes que chaque source distante soit téléchargeable, car un paquet npm ou une archive de tag tout juste publiés peuvent mettre un peu de temps à être disponibles.-->
3. Checksums are updated, a ".SRCINFO" is generated and both files are pushed together with all local sources, the "install" and the "changelog" file to the AUR package named after "pkgbase" or "pkgname". A package which does not exist yet is created, files which are not part of the package anymore are removed.<!--deDE:Die Prüfsummen werden aktualisiert, eine ".SRCINFO" wird erzeugt und beide Dateien werden zusammen mit allen lokalen Quellen, der "install"- und der "changelog"-Datei in das nach "pkgbase" oder "pkgname" benannte AUR-Paket gepusht. Ein noch nicht existierendes Paket wird angelegt, nicht mehr zum Paket gehörende Dateien werden entfernt.--><!--frFR:Les sommes de contrôle sont mises à jour, un ".SRCINFO" est généré et les deux fichiers sont poussés avec toutes les sources locales, le fichier "install" et le fichier "changelog" vers le paquet AUR nommé d'après "pkgbase" ou "pkgname". Un paquet qui n'existe pas encore est créé, les fichiers qui ne font plus partie du paquet sont supprimés.-->
4. The updated checksums are committed back to the repository.<!--deDE:Die aktualisierten Prüfsummen werden ins Repository zurück committet.--><!--frFR:Les sommes de contrôle mises à jour sont committées dans le dépôt.-->

Local sources, the "install" and the "changelog" file may be located in sub
directories (e.g. "service/a.service"). They are published by their file name
next to the "PKGBUILD", whose published copy references them accordingly
(e.g. "a.service"), since "makepkg" looks them up there. So they have to be
written literally in the "PKGBUILD", need distinct file names and are
referenced by their file name in "package()" (e.g. "${srcdir}/a.service").
Otherwise the release fails before anything is published. Only the updated
checksums are committed back, the repository's "PKGBUILD" keeps its paths.
<!--deDE:
    Lokale Quellen, die "install"- und die "changelog"-Datei dürfen in
    Unterverzeichnissen liegen (z. B. "service/a.service"). Sie werden unter
    ihrem Dateinamen neben dem "PKGBUILD" veröffentlicht, dessen
    veröffentlichte Kopie sie entsprechend referenziert (z. B. "a.service"),
    da "makepkg" sie dort sucht. Daher müssen sie im "PKGBUILD" wörtlich
    angegeben sein, unterschiedliche Dateinamen haben und in "package()" über
    ihren Dateinamen referenziert werden (z. B. "${srcdir}/a.service").
    Andernfalls schlägt die Veröffentlichung fehl, bevor etwas veröffentlicht
    wird. Nur die aktualisierten Prüfsummen werden zurück committet, das
    "PKGBUILD" des Repositorys behält seine Pfade.
-->
<!--frFR:
    Les sources locales, le fichier "install" et le fichier "changelog"
    peuvent se trouver dans des sous-répertoires (par exemple
    "service/a.service"). Elles sont publiées sous leur nom de fichier à côté
    du "PKGBUILD", dont la copie publiée les référence en conséquence (par
    exemple "a.service"), puisque "makepkg" les y cherche. Elles doivent donc
    être écrites littéralement dans le "PKGBUILD", avoir des noms de fichier
    distincts et être référencées par leur nom de fichier dans "package()"
    (par exemple "${srcdir}/a.service"). Sinon, la publication échoue avant
    que quoi que ce soit ne soit publié. Seules les sommes de contrôle mises
    à jour sont committées, le "PKGBUILD" du dépôt garde ses chemins.
-->

The AUR part is done by
[KSXGitHub/github-actions-deploy-aur](https://github.com/KSXGitHub/github-actions-deploy-aur),
pinned to a commit since it gets the private key.
<!--deDE:
    Den AUR-Teil übernimmt
    [KSXGitHub/github-actions-deploy-aur](https://github.com/KSXGitHub/github-actions-deploy-aur),
    auf einen Commit festgelegt, da sie den privaten Schlüssel erhält.
-->
<!--frFR:
    La partie AUR est réalisée par
    [KSXGitHub/github-actions-deploy-aur](https://github.com/KSXGitHub/github-actions-deploy-aur),
    fixée à un commit puisqu'elle reçoit la clé privée.
-->

<!--|deDE:Einrichtung-->
<!--|frFR:Mise en place-->
### Setup

1. Register the public part of an SSH key in your AUR account under "My Account".<!--deDE:Registrieren Sie den öffentlichen Teil eines SSH-Schlüssels in Ihrem AUR-Konto unter "My Account".--><!--frFR:Enregistrez la partie publique d'une clé SSH dans votre compte AUR sous "My Account".-->
2. Store the private key as repository secret, e.g. "AUR_SSH_PRIVATE_KEY".<!--deDE:Hinterlegen Sie den privaten Schlüssel als Repository-Secret, z. B. "AUR_SSH_PRIVATE_KEY".--><!--frFR:Enregistrez la clé privée comme secret du dépôt, par exemple "AUR_SSH_PRIVATE_KEY".-->
3. Pass it to the action as "aur-ssh-private-key", see [Usage](#usage).<!--deDE:Übergeben Sie ihn der Action als "aur-ssh-private-key", siehe [Verwendung](#usage).--><!--frFR:Transmettez-la à l'action via "aur-ssh-private-key", voir [Utilisation](#usage).-->

Without "aur-ssh-private-key" the AUR part is skipped with a warning, so the
input can be passed before the secret exists.
<!--deDE:
    Ohne "aur-ssh-private-key" wird der AUR-Teil mit einer Warnung
    übersprungen, die Eingabe kann also schon vor dem Secret übergeben werden.
-->
<!--frFR:
    Sans "aur-ssh-private-key", la partie AUR est ignorée avec un
    avertissement, l'entrée peut donc être transmise avant que le secret
    n'existe.
-->

<!--|deDE:Lokale Quellen-->
<!--|frFR:Sources locales-->
### Local sources

Local sources are copied flat into the AUR package, since "makepkg" looks
them up by file name next to the "PKGBUILD". A source like
"service/systemd.service" therefore ends up as "systemd.service".
<!--deDE:
    Lokale Quellen werden flach in das AUR-Paket kopiert, da "makepkg" sie
    über ihren Dateinamen neben dem "PKGBUILD" sucht. Eine Quelle wie
    "service/systemd.service" landet daher als "systemd.service".
-->
<!--frFR:
    Les sources locales sont copiées à plat dans le paquet AUR, car
    "makepkg" les cherche par leur nom de fichier à côté du "PKGBUILD". Une
    source comme "service/systemd.service" se retrouve donc sous
    "systemd.service".
-->

<!--|deDE:Release-Kandidaten-->
<!--|frFR:Versions candidates-->
### Release candidates

"pkgver" can not contain "-", so the AUR does not get release candidates and
the "PKGBUILD" stays at the last regular version. The candidate is still
tagged as "v&lt;version&gt;-&lt;number&gt;". With a "package.json" the
number is kept in its version, otherwise the next free number of the existing
tags is used.
<!--deDE:
    "pkgver" darf kein "-" enthalten, daher erhält das AUR keine
    Release-Kandidaten und das "PKGBUILD" bleibt auf der letzten regulären
    Version. Der Kandidat wird trotzdem als "v&lt;version&gt;-&lt;number&gt;"
    getaggt. Mit einer "package.json" steht die Nummer in deren Version,
    sonst wird die nächste freie Nummer der vorhandenen Tags verwendet.
-->
<!--frFR:
    "pkgver" ne peut pas contenir "-", l'AUR ne reçoit donc pas de versions
    candidates et le "PKGBUILD" reste à la dernière version régulière. La
    version candidate est tout de même taguée sous "v&lt;version&gt;-&lt;number&gt;".
    Avec un "package.json", le numéro figure dans sa version, sinon le
    prochain numéro libre parmi les tags existants est utilisé.
-->
