<div align="center">
  <img src="docs/logo.png" width="128" height="128" alt="logo">

# BATTERY MONITOR

**// LA VRAIE SANTÉ DE TA BATTERIE**

PowerShell + WinForms · 100 % natif Windows · interface Cyber-HUD

</div>

<p align="center">
  <a href="../../releases"><img src="https://img.shields.io/badge/version-v2.3.003-41B375?style=flat-square&labelColor=0B0C14" alt="Version"></a>
  <img src="https://img.shields.io/badge/Windows-10%20%2F%2011-00D4FF?style=flat-square&labelColor=0B0C14&logo=windows&logoColor=white" alt="Windows 10 / 11">
  <img src="https://img.shields.io/badge/PowerShell-5.1-7B4FFF?style=flat-square&labelColor=0B0C14" alt="PowerShell 5.1">
  <a href="https://linktr.ee/ofbridgelab"><img src="https://img.shields.io/badge/Ofbridge%20Lab-blog-FF8C00?style=flat-square&labelColor=0B0C14" alt="Ofbridge Lab"></a>
</p>

---

Le **rapport batterie de Windows** est très complet, mais illisible. **BatteryInfoView** de NirSoft fait le travail, mais son interface a pris de l'âge. **Battery Monitor** affiche tout ce qui compte en un écran : **fiche technique**, **capacités**, **santé**, **charge en temps réel** et **historique d'usage sur 3 jours**. C'est un exe léger, open source, sans installation et sans droits administrateur.

> 🎯 **Certains firmwares affichent 100 % de santé alors que la batterie a perdu plus de 13 % de sa capacité. Battery Monitor détecte ce cas et donne la vraie valeur.**

<div align="center">
  <img src="docs/01-fenetre.png" width="602" alt="Battery Monitor — fenêtre principale">
</div>

## 📑 Sommaire

- ✨ [Fonctionnalités](#-fonctionnalités)
- 🧠 [Une santé fiable, même quand le firmware se trompe](#-une-santé-fiable-même-quand-le-firmware-se-trompe)
- 📊 [Historique d'usage sur 3 jours](#-historique-dusage-sur-3-jours)
- ⚡ [Accès rapides](#-accès-rapides)
- 📦 [Installation & utilisation](#-installation--utilisation)

---

## ✨ Fonctionnalités

- **Modèle exact du PC** : utile pour commander une pièce. Sur certains Asus (gamme Zenbook), il donne la lettre de référence qui manque souvent.
- **Fiche technique** : fabricant, modèle, chimie et tension de la batterie, pour commander la bonne batterie de remplacement.
- **Capacités** : capacité d'origine, capacité réelle actuelle et nombre de cycles (quand le firmware les communique).
- **Santé de la batterie** : pourcentage et barre de 20 segments, avec une bulle d'info **« i »** quand la valeur est estimée.
- **Charge en temps réel**, rafraîchie toutes les 5 s, avec 4 états distincts : **en charge**, **chargée sur secteur**, **branché mais ne charge pas** (chargeur trop faible, défaut ou limite constructeur à 60 / 80 %) et **sur batterie**.
- **Bip de fin de charge**, désactivable d'un clic (`[ SON : ACTIVÉ ]`).
- **Multi-batterie** : capacités et santé calculées sur l'ensemble des batteries, avec le détail par batterie.
- **Interface Cyber-HUD** : fond sombre, accents néon, police Consolas, barre de titre noire et croix rouge de fermeture. On déplace la fenêtre en tirant la barre de titre, et **Échap** la ferme.

---

## 🧠 Une santé fiable, même quand le firmware se trompe

La santé d'une batterie se calcule normalement ainsi : **capacité actuelle ÷ capacité d'origine**. Mais certains firmwares (constaté sur un HP Spectre x360) **recopient la capacité actuelle dans la capacité d'origine**. Le calcul donne alors toujours **100 %**, alors que l'historique de Windows montre une batterie passée de 58 965 à 51 374 mWh.

Battery Monitor repère ce cas : une vraie capacité d'origine ne change jamais, alors que celle-ci varie d'un relevé à l'autre et suit la capacité actuelle. Dans ce cas :

- la référence devient la **plus haute capacité jamais relevée** ;
- la santé s'affiche comme un **maximum** (**« ≤ 87.1 % »**), puisque la batterie neuve contenait au moins cette référence ;
- la carte Capacités indique **« Usine : inconnue (firmware) »**, puis la référence retenue ;
- la bulle **« i »** donne le détail au survol.

<div align="center">
  <img src="docs/02-sante-bulle.png" width="592" alt="Bulle d'info de la santé estimée">
</div>

> 🔗 **Suite Ofbridge Lab** : la référence est aussi lue dans `batterie-historique.json`, écrit par **CyclObs** (dans `%ProgramData%\OfbridgeLab\Batterie\` ou `Historique\` à côté de l'exe). Elle est ainsi conservée même quand l'historique de Windows est effacé, par exemple après une réinstallation. Les numéros de série n'y sont jamais écrits en clair.

Les **cycles de charge** à 0 sont affichés « non communiqué (firmware) » : beaucoup de firmwares ne remplissent pas cette valeur, ce qui ne veut pas dire zéro cycle.

---

## 📊 Historique d'usage sur 3 jours

Clique sur **► USAGE TIMELINE** pour déplier la frise des 3 derniers jours :

| Couleur | Signification |
|---|---|
| 🟦 **Cyan** | PC sur secteur |
| 🟧 **Orange** | PC sur batterie |
| ⬛ **Gris** | PC en veille |

Le survol d'une période affiche son détail.

<div align="center">
  <img src="docs/03-timeline.png" width="602" alt="Historique d'usage sur 3 jours">
</div>

---

## ⚡ Accès rapides

| Bouton | Ouvre | Pour quoi faire |
|---|---|---|
| **RAPPORT DÉTAILLÉ** | Le rapport HTML complet de Windows (`powercfg /batteryreport`) | Historique des capacités depuis le début, estimations d'autonomie, données constructeur (nom, fabricant, numéro de série) |
| **PARAM. BATTERIE** | Les paramètres batterie de Windows 10 / 11 | Économiseur de batterie, consommation par application, graphique des dernières 24 h |
| **OPTION ALIM.** | Les options d'alimentation du panneau de configuration | Mode de performance, action à la fermeture du capot, délais de mise en veille |
| **ACTIVER PERF. ÉLEVÉE** | Le mode « Performances élevées », après confirmation | Le crée depuis le modèle Windows s'il est masqué sur l'appareil, puis l'active |

---

## 📦 Installation & utilisation

1. Télécharge `Battery_Monitor.exe` depuis l'onglet [**Releases**](../../releases).
2. Lance-le : aucune installation et aucun droit administrateur ne sont nécessaires.
3. La fenêtre s'ouvre au premier plan après quelques secondes, le temps que Windows génère son rapport batterie.

> [!TIP]
> Si tu utilises le script `.ps1` et qu'il est bloqué, ouvre PowerShell et lance :
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

## 🖥 Prérequis

- **Windows 10 ou 11**, 64 bits.
- **PowerShell 5.1**, inclus dans Windows.
- Un **ordinateur portable ou une tablette** avec batterie.

## 🧰 Notes techniques

- **Sources** : `powercfg /batteryreport` (versions HTML et XML), WMI `root\wmi` (`BatteryStatus`, `BatteryFullChargedCapacity`, `BatteryStaticData`) et `Win32_Battery` en secours.
- **Rien n'est écrit sur le PC** : le réglage du son n'est pas mémorisé, et les rapports temporaires sont régénérés à chaque lancement.
- **Limite connue** : sans le cadre Windows, la fenêtre n'a pas de bouton de réduction.

## 📜 Historique des versions

Voir le [CHANGELOG](CHANGELOG.md) et les [Releases](../../releases).

## 📄 Licence

Projet sous licence **MIT** : voir le fichier [LICENSE](LICENSE).

---

<div align="center">
  <sub><a href="../../releases">Téléchargements</a> · <a href="https://linktr.ee/ofbridgelab">Linktree</a></sub>
  <br/>
  <sub><b>BATTERY MONITOR · OFBRIDGE LAB</b> · <i>// LA VRAIE SANTÉ DE TA BATTERIE</i></sub>
</div>
