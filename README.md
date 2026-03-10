Battery Monitor v2.0 — HUD Edition

Le rapport natif de Windows est très détaillé, mais reste peu lisible. De son côté, le logiciel populaire BatteryInfoView de Nirsoft manque un peu de modernité et n'est pas toujours très intuitif au premier abord.
Battery_Monitor propose une alternative : un outil open‑source léger développé en PowerShell, désormais doté d’une interface graphique (GUI) au style HUD / sci‑fi, permettant de surveiller simplement l’état de santé et les performances de votre batterie sous Windows.

 Nouveautés de la v2.0

   Nouvelle Interface "Instrument de bord" : Un design sombre (Dark Mode) avec des accents néons bleus, optimisé pour la lisibilité et l'esthétique tech.

   Historique de Charge (3 jours) : Analyse automatique des cycles de charge des dernières 72 heures pour surveiller l'évolution de votre autonomie.


 Aperçu
L'interface HUD v2.0 

<img width="301" height="420" alt="Capture d&#39;écran 2026-02-24 142502" src="https://github.com/user-attachments/assets/bd5aea96-c4b2-4ce6-8c5a-2b25f43ff0e8" />

L’interface est découpée en plusieurs sections que je vais vous détailler :
1. Identification du matériel

Tout d'abord, le modèle de votre ordinateur. C'est une information très utile, notamment pour certains modèles Asus (gamme Zenbook), afin d'obtenir la référence exacte (la lettre manquante) nécessaire lors du remplacement de pièces.

<img width="750" height="100" alt="Capture d&#39;écran 2026-03-10 165244" src="https://github.com/user-attachments/assets/5d05f41f-14a7-4daa-a290-41e9f99705b8" />

2. Caractéristiques et État de santé

Ensuite, nous retrouvons deux tuiles principales :

 La fiche technique : Elle regroupe les informations essentielles pour commander une nouvelle batterie sans se tromper.
 Capacité et cycles : Vous y trouverez la capacité d'origine (usine), la capacité réelle actuelle et le nombre de cycles de charge (si l'information est disponible).
 
<img width="748" height="190" alt="Capture d&#39;écran 2026-03-10 165303" src="https://github.com/user-attachments/assets/9dbe0aa6-61bd-45a1-8cce-3feab16b2940" />

Santé de la batterie : Un score en pourcentage, calculé en comparant la capacité d'usine à la capacité actuelle, pour connaître instantanément l'usure de votre matériel.

<img width="734" height="143" alt="Capture d&#39;écran 2026-03-10 165352" src="https://github.com/user-attachments/assets/3af8a882-a7ed-4dbe-9883-6821ce8051b1" />

3. Statut en temps réel et Historique

Juste en dessous, vous pouvez consulter le niveau de charge actuel et savoir si la batterie est en cours de charge ou de décharge.

<img width="738" height="125" alt="Capture d&#39;écran 2026-03-10 165409" src="https://github.com/user-attachments/assets/a7fbb2f3-aff1-40ab-ab54-6ea6c52cf19f" />

Nous avons également intégré l'usage de la batterie sur les 3 derniers jours avec un code couleur simple :

    Bleu : PC sur secteur.  Orange : PC sur batterie. Gris : PC en veille.

   <img width="722" height="384" alt="Capture d&#39;écran 2026-03-10 165429" src="https://github.com/user-attachments/assets/3e57f796-4eae-4d7a-9647-d5402e78deb9" />

4. Les accès rapides aux paramètres Windows

Pour vous éviter de chercher dans les menus, j'ai intégré trois boutons qui regroupent les réglages essentiels :
<img width="734" height="57" alt="Capture d&#39;écran 2026-03-10 165452" src="https://github.com/user-attachments/assets/45e91b3b-3349-422c-a9ea-4db5b3036228" />

1. [ Rapport détaillé ] (PowerCfg) :

Il ouvre le rapport HTML complet généré par Windows. C'est pratique pour consulter :
   -L’historique des capacités : L'évolution de la batterie depuis le début.
   -Estimations de l'autonomie : Une comparaison entre l'autonomie théorique et réelle.
   -Données constructeur : Le nom précis, le fabricant et le numéro de série de la batterie.

2. [ Paramètres batterie ] (Interface Moderne) 

Il vous envoie directement dans les réglages de Windows 10/11 pour gérer le quotidien :
   -Économiseur de batterie : Pour régler le seuil d'activation automatique.
   -Consommation par application : Pour voir quels logiciels utilisent le plus d'énergie.
   -Graphique d'utilisation : Une vue simple du niveau de batterie sur les dernières 24 heures.
 
<img width="498" height="510" alt="Capture d&#39;écran 2026-03-10 170108" src="https://github.com/user-attachments/assets/436590da-2dbe-4bf3-9d5f-e51a533d4922" />

 3. [ Options d’alimentation ] (Panneau de configuration) : 

Il permet d'accéder aux réglages classiques du panneau de configuration :
   -Modes de performance : Choisir entre les modes Économie ou Performances.
   -Action à la fermeture du capot : Choisir si le PC se met en veille ou s'éteint.
   -Mise en veille : Régler le temps avant que l'écran ou le PC ne s'éteigne tout seul.
   
<img width="537" height="262" alt="Capture d&#39;écran 2026-03-10 170020" src="https://github.com/user-attachments/assets/5c1c00d3-fce8-4af2-8d1b-3eb988f53d03" />


Installation et Utilisation

L'outil est prêt à l'emploi :

   Téléchargez la dernière version depuis l'onglet Releases.

   Lancez le fichier .exe (ou le script .ps1).

   Profitez de l'analyse automatique.

    [!TIP]
    Si vous utilisez le script .ps1 et qu'il est bloqué, ouvrez PowerShell en administrateur et lancez :

    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

 Configuration requise

   Système d'exploitation : Windows 10 ou Windows 11.

   Environnement : PowerShell 5.1 ou supérieur.

   Matériel : Ordinateur portable ou tablette Windows.

📄 Licence

Ce projet est sous licence MIT. Consultez le fichier LICENSE pour plus de détails.

Développé avec ⚡ par ofbridge_lab pour la communauté Windows.
