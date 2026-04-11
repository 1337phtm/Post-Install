# 🚀 Post‑Install — Optimisation & Configuration Automatisée de Windows

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207+-blue)
![License](https://img.shields.io/badge/License-MIT--Custom-green)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey)
![Status](https://img.shields.io/badge/Status-Active-success)

`Post‑Install` est un script PowerShell avancé permettant d’automatiser la configuration d’un système Windows fraîchement installé.
Il applique des réglages essentiels : **confidentialité**, **sécurité**, **apparence**, **performances**, **gaming**, **alimentation**, **barre des tâches**, **explorateur**, **menu Démarrer**, etc.

Le script inclut également un système de logs, une gestion intelligente des modes (`Admin`, `User`, `Test`) et une élévation automatique si nécessaire.

---

## ✨ Fonctionnalités principales

### 🔑 Licence Windows
- Détection de l’édition installée.
- Proposition de mise à niveau vers **Windows Pro**.
- Gestion automatique ou assistée selon le type de licence.

### ⚡ Alimentation
- Activation de l’hibernation.
- Configuration des actions du capot, bouton Power, veille.
- Désactivation des timeouts inutiles.
- Application du plan d’alimentation actif.

### 🎨 Apparence & Thèmes
- Mode sombre (Apps + Windows).
- Transparence.
- Paramètres visuels essentiels.

### 📋 Barre des tâches
- Alignement.
- Icône de recherche.
- Widgets.
- Horloge avec secondes.
- Bouton “Terminer la tâche”.

### 📁 Explorateur de fichiers
- Extensions visibles.
- Fichiers cachés visibles.
- Miniatures activées.
- Mode compact.
- Cases à cocher.
- Historique presse‑papier.
- Icône “Ce PC”.

### 🏠 Menu Démarrer
- Désactivation des recommandations.
- Désactivation de Bing dans la recherche.

### 🔒 Confidentialité & Télémétrie
- Désactivation de Cortana.
- Désactivation de l’ID publicitaire.
- Désactivation des suggestions Windows.
- Blocage de la collecte d’activité.
- Désactivation OneDrive (optionnel).
- Désactivation des sondes réseau NCSI.

### 🛡️ Sécurité Windows
- UAC renforcé (optionnel).
- Smart App Control.
- Désactivation AutoRun.
- Masquage du dernier utilisateur.
- `Ctrl+Alt+Suppr` obligatoire.

### 🎮 Gaming
- Désactivation de GameDVR.
- Désactivation de la Xbox Game Bar.
- Optimisations pour les performances.

---

## 🧠 Modes disponibles

- 🔵 **Mode normal (Admin)**
  Exécute toutes les modifications système.

- 🟣 **Mode Test (`-Test`)**
  Aucune modification expérimentale.
  Les actions sensibles sont ignorées.
  Permet de vérifier le comportement sans risque.

- ⚪ **Mode Utilisateur (`-User`)**
  Aucune modification dans `HKLM`.
  Idéal pour appliquer uniquement les réglages utilisateur.

---

## # 📦 Installation

1. **Cloner le repo**

   ```bash
   git clone https://github.com/1337phtm/Post-Install.git
   ```

2. **Ouvrir PowerShell dans le dossier**

   ```powershell
   cd .\Post-Install\
   ```

---

## ▶️ Utilisation

- **Exécution normale**

  ```powershell
  .\Post-Install.ps1
  ```

- **Mode Test**

  ```powershell
  .\Post-Install.ps1 -Test
  ```

- **Mode Utilisateur**

  ```powershell
  .\Post-Install.ps1 -User
  ```

- **Mode Utilisateur + Test**

  ```powershell
  .\Post-Install.ps1 -User -Test
  ```

---

## 🧾 Journalisation

Le script génère automatiquement :
- un fichier de log complet,
- un fichier d’erreurs séparé,
- un compteur des actions (`SUCCESS`, `ERROR`, `SKIP`, `TEST`, `USER`).

---

## 🛠️ Prérequis

- Windows 10 ou Windows 11.
- PowerShell 5.1 ou PowerShell 7+.
- Exécution autorisée (ex à lancer dans la session) :

  ```powershell
  Set-ExecutionPolicy Bypass -Scope Process -Force
  ```

---

## 📄 Licence

Ce projet est distribué sous **licence MIT**.

---

## 📚 Documentation

Pour obtenir l’aide intégrée du script :

```powershell
Get-Help .\Post-Install.ps1
```
