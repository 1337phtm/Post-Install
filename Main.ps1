<#
.SYNOPSIS
    Script Post-Install Windows automatisé avec gestion des modes (Admin, User, Test),
    configuration système, confidentialité, sécurité, apparence, alimentation et optimisation.

.DESCRIPTION
    Ce script applique une série d’optimisations Windows après installation :

    • Gestion de la licence Windows (upgrade vers Pro si nécessaire)
    • Paramètres d’alimentation (veille, hibernation, boutons, écran)
    • Apparence et thèmes (mode sombre, transparence, animations)
    • Barre des tâches (alignement, widgets, horloge avec secondes)
    • Explorateur de fichiers (extensions, fichiers cachés, miniatures, compact mode)
    • Menu Démarrer (recommandations, Bing Search)
    • Confidentialité & télémétrie (Cortana, ID pub, tracking, suggestions)
    • Sécurité Windows (UAC, Smart App Control, AutoRun, login)
    • Paramètres Windows Update
    • Optimisations Gaming (GameDVR, GameBar)

    Le script gère automatiquement :
    • L’élévation en administrateur si nécessaire
    • Le mode utilisateur (-User)
    • Le mode test (-Test) pour ignorer les modifications sensibles
    • La journalisation automatique (succès, erreurs, actions ignorées)

.PARAMETER User
    Exécute le script en mode utilisateur (aucune modification HKLM).

.PARAMETER Test
    Active le mode test : les actions expérimentales ou sensibles sont ignorées.

.EXAMPLE
    .\Post-Install.ps1
    Exécution normale avec élévation automatique (redémarrage nécessaire).

.EXAMPLE
    .\Post-Install.ps1 -User
    Exécution en mode utilisateur (aucune modification nécessitant une élévation).

.EXAMPLE
    .\Post-Install.ps1 -Test
    Exécution en mode test (aucune modification nécessitant le redémarrage de quoique ce soit).

.NOTES
    Auteur : 1337phtm
    Version : 1.0
    Compatibilité : Windows 10 / Windows 11
    Nécessite : PowerShell 5.1+ ou PowerShell 7+

.LINK
    GitHub :
    https://github.com/1337phtm/Powershell/Usefull/Scripts/Modules/System/Post-Install.ps1
#>

param(
    [Switch]$User,
    [switch]$Test
)

. $PSScriptRoot\src\Setup.ps1 -LogName $PSCommandPath

function Write-Status {
    param(
        [ValidateSet("SUCCESS", "ERROR", "SKIP", "INFO", "TEST", "USER")]$Type,
        [string]$Message
    )
    $timestamp = Get-Date -Format "HH:mm:ss"
    $Global:StatusCounters[$Type]++
    switch ($Type) {
        "SUCCESS" { Write-Host " [$timestamp] ✓ $Message" -ForegroundColor Green }
        "ERROR" { Write-Host " [$timestamp] ✗ $Message" -ForegroundColor Red }
        "SKIP" { Write-Host " [$timestamp] - $Message" -ForegroundColor Yellow }
        "INFO" { Write-Host " [$timestamp] → $Message" -ForegroundColor Cyan }
        "TEST" { Write-Host " [$timestamp] T $Message" -ForegroundColor Magenta }
        "USER" { Write-Host " [$timestamp] U $Message" -ForegroundColor White }
    }

    # LOG AUTOMATIQUE
    $logEntry = "[$timestamp] [$Type] $Message"
    Add-Content -Path $Global:LogFile -Value $logEntry -Force

    if ($Type -eq "ERROR") {
        Add-Content -Path $Global:ErrorLogFile -Value $logEntry -Force
    }
}


function Set-RegistryValueSafe {
    [CmdletBinding()]
    param(
        [string]$Path,
        [string]$Name,
        [Parameter(Mandatory = $true)]
        $Value,
        [string]$Description,
        [switch]$Experimental
    )

    if ($Path -like "HKLM:*" -and $User) {
        Write-Status USER "$Description ignorée (HKLM)"
        return
    }

    if ($Experimental -and $Test) {
        Write-Status TEST "$Description ignorée"
        return
    }

    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
            Write-Status INFO "Clé $Name créée : $Path"
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction Stop
        Write-Status SUCCESS $Description

    }
    catch {
        if (-not (Test-Path $Path)) {
            Write-Status SKIP "Clé pour $Description absente"
        }
        else {
            $errorMsg = $_.Exception.Message
            Write-Status ERROR "$Description | $errorMsg"
        }
    }
}

#======================================================================
# Démarrage en admin :
#======================================================================

# ANTI-BOUCLE : Vérif fichier temporaire
$restartMarker = "$env:TEMP\$($MyInvocation.MyCommand.Name).restart"
if (Test-Path $restartMarker) {
    Remove-Item $restartMarker -Force
    # 2ème lancement → ON CONTINUE (admin OU user)
}
else {
    # 1er lancement
    if (-not $User) {
        # Sans -User → relance admin si besoin
        $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
            Write-Status INFO "Elevation requise. Relance en administrateur..."
            $allArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
            if ($Test) { $allArgs += " -Test" }
            New-Item $restartMarker -ItemType File | Out-Null
            Start-Process powershell.exe -ArgumentList $allArgs -Verb RunAs -WorkingDirectory $PSScriptRoot
            exit
        }
    }
    else {
        Write-Status INFO "[USER] Mode utilisateur → nouveau terminal..."
        $allArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -User"
        if ($Test) { $allArgs += " -Test" }
        New-Item $restartMarker -ItemType File | Out-Null
        Start-Process powershell.exe -ArgumentList $allArgs -WorkingDirectory $PSScriptRoot
        exit
    }
}

Clear-Host

if ($Test -and $User) {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║             POST - INSTALL           ║" -ForegroundColor Magenta
    Write-Host "║          ✎ USER TEST - MODE          ║" -ForegroundColor Magenta
    Write-Host "║          WRITTEN BY 1337phtm         ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""

}
elseif ($Test) {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║             POST - INSTALL           ║" -ForegroundColor Magenta
    Write-Host "║             ✎ TEST - MODE            ║" -ForegroundColor Magenta
    Write-Host "║          WRITTEN BY 1337phtm         ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
}
elseif ($User) {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║             POST - INSTALL           ║" -ForegroundColor Blue
    Write-Host "║             ✎ USER - MODE            ║" -ForegroundColor Blue
    Write-Host "║          WRITTEN BY 1337phtm         ║" -ForegroundColor Blue
    Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}
else {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║             POST - INSTALL           ║" -ForegroundColor Blue
    Write-Host "║          WRITTEN BY 1337phtm         ║" -ForegroundColor Blue
    Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

#======================================================================
# Clé de Licence :
#======================================================================
Show-SectionHeader "🔑 GESTION DE LA LICENCE WINDOWS"

if (-not $User) {
    if (-not $Test) {
        if ((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID -eq "Professional") {
            Write-Status SUCCESS "Professional edition already installed"
        }
        else {
            $choice = Read-Host "Do you want to Upgrade your Windows to Pro ? (Y/N) "
            if ($choice -eq "Y" -or $choice -eq "y") {
                #slmgr /ipk W269N-WFGWX-YVC9B-4J6C9-T83GX #Clé de mise à niveau vers Pro
                $lic = Get-WmiObject -Query "SELECT * FROM SoftwareLicensingProduct WHERE PartialProductKey IS NOT NULL"

                if ($lic.Description -match "OEM_DM") {
                    Write-Host "Migration automatique impossible, ouverture de l'interface..."
                    Write-Host "Clé de licence copié dans le presse-papier, cliquez sur modifier la clé de produit et copiez la clé"
                    Start-Process ms-settings:activation -WindowStyle Hidden
                    Set-Clipboard -Value "VK7JG-NPHTM-C97JM-9MPGT-3V66T"
                }
                else {
                    slmgr /ipk VK7JG-NPHTM-C97JM-9MPGT-3V66T #Clé de mise à niveau vers Pro
                    #dism /online /Set-Edition:Professional /ProductKey:VK7JG-NPHTM-C97JM-9MPGT-3V66T /AcceptEula


                    $EditionId = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID
                    if ($EditionId -ne "Professional") {
                        Set-RegistryValueSafe `
                            -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" `
                            -Name EditionID `
                            -Value "Professional" `
                            -Description "Modif de l'Edition ID"
                    }

                    $ProductName = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName
                    if ($ProductName -ne "Windows 11 Pro") {
                        Set-RegistryValueSafe `
                            -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" `
                            -Name ProductName `
                            -Value "Windows 11 Pro" `
                            -Description "Modif du ProductName"
                    }
                }
            }
            else {
                Write-Status INFO "Upgrade skipped`n"
            }
        }
    }
    else {
        if ((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID -eq "Professional") {
            Write-Status SUCCESS "Professional edition already installed"
        }
        else {
            Write-Status INFO "No Professional licence Installed"
            Write-Status TEST "Modification de licence ignorée"
        }
    }
}
else {
    Write-Status USER "Mode utilisateur, gestion de licence ignorée"
}

#======================================================================
# Alimentation :
#======================================================================
Show-SectionHeader "⚡ PARAMÈTRES D'ALIMENTATION"

if (-not $User) {
    if (-not $Test) {
        # Activer l’hibernation
        try {
            powercfg /hibernate on
            Write-Status SUCCESS "Hibernation activée"
        }
        catch {
            Write-Status ERROR "Impossible d'activer l'hibernation"
        }

        $AC = @(
            @{Cmd = @("SUB_BUTTONS", "LIDACTION", 1); Desc = "Fermeture du capot (AC) → Veille"; } # 0 = Rien | 1 = Veille | 2 = Hibernate | 3 = Arrêt
            @{Cmd = @("SUB_BUTTONS", "PBUTTONACTION", 1); Desc = "Bouton Marche/Arrêt (AC) → Veille"; } # 0 = Rien | 1 = Veille | 2 = Hibernate | 3 = Arrêt
            @{Cmd = @("SUB_BUTTONS", "SBUTTONACTION", 1); Desc = "Bouton veille (AC) → Veille"; } # 0 = Rien | 1 = Veille | 2 = Hibernate | 3 = Arrêt
            @{Cmd = @("SUB_NONE", "CONSOLELOCK", 1); Desc = "Verrouillage auto après veille (AC)"; } # 0 = Désactivé | 1 = Activé
        )

        $DC = @(
            @{Cmd = @("SUB_BUTTONS", "LIDACTION", 2); Desc = "Fermeture du capot (DC) → Hibernate"; } # 0 = Rien | 1 = Veille | 2 = Hibernate | 3 = Arrêt
            @{Cmd = @("SUB_BUTTONS", "PBUTTONACTION", 2); Desc = "Bouton Marche/Arrêt (DC) → Hibernate"; } # 0 = Rien | 1 = Veille | 2 = Hibernate | 3 = Arrêt
            @{Cmd = @("SUB_BUTTONS", "SBUTTONACTION", 2); Desc = "Bouton veille (DC) → Hibernate"; } # 0 = Rien | 1 = Veille | 2 = Hibernate | 3 = Arrêt
            @{Cmd = @("SUB_NONE", "CONSOLELOCK", 2); Desc = "Verrouillage auto après veille (DC)"; } # 0 = Désactivé | 1 = Activé
        )

        foreach ($item in $AC) {
            try {
                powercfg /setacvalueindex SCHEME_CURRENT $item.Cmd
                Write-Status SUCCESS $item.Desc
            }
            catch {
                Write-Status ERROR "Impossible : $($item.Desc)"
            }
        }

        foreach ($item in $DC) {
            try {
                powercfg /setdcvalueindex SCHEME_CURRENT $($item.Cmd)
                Write-Status SUCCESS $item.Desc
            }
            catch {
                Write-Status ERROR "Impossible : $($item.Desc)"
            }
        }

        try {
            powercfg /change standby-timeout-ac 0
            powercfg /change standby-timeout-dc 0
            Write-Status SUCCESS "Paramètres de mise en veille configurés"
        }
        catch {
            Write-Status ERROR "Impossible de configurer la mise en veille"
        }

        try {
            powercfg /change monitor-timeout-ac 0
            powercfg /change monitor-timeout-dc 0
            Write-Status SUCCESS "Paramètres d'extinction de l'écran configurés"
        }
        catch {
            Write-Status ERROR "Impossible de configurer l'extinction de l'écran"
        }

        try {
            powercfg /setactive SCHEME_CURRENT
            Write-Status SUCCESS "Paramètres d'alimentation appliqués"
        }
        catch {
            Write-Status ERROR "Impossible d'appliquer le plan d'alimentation"
        }
    }
    else {
        Write-Status TEST "Modification des paramètres d'alimentation ignorée"
    }
}
else {
    Write-Status USER "Modification des paramètres d'alimentation ignorée"
}


#======================================================================
# Thèmes :
#======================================================================
Show-SectionHeader "🎨 THÈMES & APPARENCE"

$Changes = @(
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "AppsUseLightTheme"; Value = 0; Description = "Thème Apps (mode sombre)"; } # Mode sombre pour les apps | # 0 : Sombre (non) | 1 : Clair (oui)
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "SystemUsesLightTheme"; Value = 0; Description = "Thème Windows (mode sombre)"; } # Mode Clair pour Windows | # 0 : Sombre (non) | 1 : Clair (oui)
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "EnableTransparency"; Value = 1; Description = "Transparence Windows"; } # Transparence | # 0 : Désactivé | 1 : Activé
    @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "DisableStartupSound"; Value = 0; Description = "Son de démarrage"; } # Son de démarrage | # 0 : Activé | 1 : Désactivé
    # @{Path = "HKCU:\Control Panel\Desktop"; Name = "UserPreferencesMask"; Value = ([byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00)); Description = "Son de démarrage"; Experimental=$True;} # Désactivé animations Windows (profil agressif)
)
foreach ($item in $Changes) { Set-RegistryValueSafe @item }

#======================================================================
# BARRE DES TÂCHES :
#======================================================================
Show-SectionHeader "📋 BARRE DES TÂCHES"

$Changes = @(
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "TaskbarAl"; Value = 1; Description = "Alignement barre des tâches"; } # 0 = Gauche | 1 = Centre
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "SearchboxTaskbarMode"; Value = 0; Description = "Icône de recherche"; } # 0 = Masqué | 1 = Icône | 2 = Boîte
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowTaskViewButton"; Value = 0; Description = "Icône Task View"; } # 0 = Masqué | 1 = Affiché
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowSecondsInSystemClock"; Value = 1; Description = "Secondes horloge système"; } # 0 = Non | 1 = Oui
    # @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "TaskbarBadges"; Value = 0; Description = "Badges d'applications"; } # 0 = Désactivé | 1 = Activé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"; Name = "TaskbarEndTask"; Value = 1; Description = "Activer 'Terminer la tâche' dans la barre des tâches"; } # 0 = Désactivé | 1 = Activé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "TaskbarMn"; Value = 0; Description = "Widgets de la barre des tâches"; } # 0 = Désactivé | 1 = Activé
)
foreach ($item in $Changes) { Set-RegistryValueSafe @item }

#======================================================================
# Explorateur de fichier :
#======================================================================
Show-SectionHeader "📁 EXPLORATEUR DE FICHIERS"

$Changes = @(
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "HideFileExt"; Value = 0; Description = "Extensions de fichiers"; } # 0 = Afficher | 1 = Masquer
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Hidden"; Value = 1; Description = "Fichiers cachés"; } # 1 = Afficher | 2 = Masquer
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowSuperHidden"; Value = 0; Description = "Fichiers système protégés"; } # 0 = Masquer | 1 = Afficher
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "LaunchTo"; Value = 1; Description = "Explorateur sur Ce PC"; } # 1 = Ce PC | 2 = Accès rapide
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "UseCompactMode"; Value = 1; Description = "Mode compact Explorateur"; } # 0 = Désactivé | 1 = Activé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "AutoCheckSelect"; Value = 1; Description = "Cases à cocher dans Explorateur"; } # 0 = Désactivé | 1 = Activé
    @{Path = "HKCU:\Software\Microsoft\Clipboard"; Name = "EnableClipboardHistory"; Value = 1; Description = "Historique presse-papiers"; } # 0 = Désactivé | 1 = Activé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowInfoTip"; Value = 1; Description = "Info-bulles sur fichiers"; } # 0 = Désactivé | 1 = Activé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "SeparateProcess"; Value = 1; Description = "Processus séparé"; } # 0 = Même processus | 1 = Processus séparé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "IconsOnly"; Value = 0; Description = "Miniatures au lieu d'icônes"; } # 0 = Miniatures | 1 = Icônes seulement
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "DisableThumbnailCache"; Value = 1; Description = "Cache miniatures"; } # 0 = Activé | 1 = Désactivé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"; Name = "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"; Value = 1; Description = "Icône Ce PC sur bureau"; } # 0 = Affiché | 1 = Masqué
    # @{Path="HKCU:\Software\Classes\Directory\Background\shell\cmd"; Name="Extended"; Value=""; Description="Ajout cmd ici dans le menu contextuel";} # Optionnel
)
foreach ($item in $Changes) { Set-RegistryValueSafe @item }

#======================================================================
# Menu Démarrer :
#======================================================================
Show-SectionHeader "🏠 MENU DÉMARRER"

$Changes = @(
    # @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_ShowDocuments"; Value = 1; Description = "Documents dans le menu Démarrer"; Experimental = $true; } # Expérimental
    # @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_ShowDownloads"; Value = 1; Description = "Downloads dans le menu Démarrer"; Experimental = $true; } # Expérimental
    # @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_ShowSettings"; Value = 1; Description = "Paramètres dans Start"; Experimental = $true; } # Expérimental
    # @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_ShowFileExplorer"; Value = 1; Description = "Bouton Explorateur dans Start"; Experimental = $true; } # Expérimental
    # @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_ShowPictures"; Value = 1; Description = "Pictures dans le menu Démarrer"; Experimental = $true; } # Expérimental
    # @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_ShowMusic"; Value = 1; Description = "Music dans le menu Démarrer"; Experimental = $true; } # Expérimental
    # @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_ShowVideos"; Value = 1; Description = "Videos dans le menu Démarrer"; Experimental = $true; } # Expérimental
    # @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_ShowHomegroup"; Value = 1; Description = "Téléchargements dans le menu Démarrer"; Experimental = $true; } # Expérimental
    # @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_ShowNetwork"; Value = 1; Description = "Network dans le menu Démarrer"; Experimental = $true; } # Expérimental

    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "BingSearchEnabled"; Value = 0; Description = "Bing dans la recherche Windows"; } # 0 = Désactivé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_Recommendations"; Value = 0; Description = "Recommandations d'applications dans le menu Démarrer"; } # 0 = Désactivé
)
foreach ($item in $Changes) { Set-RegistryValueSafe @item }

#======================================================================
# Confidentialité :
#======================================================================
Show-SectionHeader "🔒 CONFIDENTIALITÉ & TÉLÉMÉTRIE"

$Changes = @(
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AllowCortana"; Value = 0; Description = "Désactiver Cortana"; } # 0 = Désactivé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "CortanaConsent"; Value = 0; Description = "Consentement Cortana"; } # 0 = Désactivé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowSyncProviderNotifications"; Value = 0; Description = "Notifications pubs Explorateur"; } # 0 = Pas de pubs
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "Enabled"; Value = 0; Description = "ID publicitaire"; } # 0 = Désactivé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP"; Name = "RomeSdkChannelUserAuthzPolicy"; Value = 0; Description = "Expériences partagées"; } # 0 = Désactivé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"; Name = "TailoredExperiencesWithDiagnosticDataEnabled"; Value = 0; Description = "Historique d'activité personnalisé"; } # 0 = Désactivé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"; Name = "EnableActivityFeed"; Value = 0; Description = "Historique d'activité Windows"; } # 0 = Désactivé
    @{Path = "HKCU:\Software\Microsoft\OneDrive"; Name = "DisablePersonalSync"; Value = 1; Description = "OneDrive pour le compte utilisateur"; } # 1 = Désactivé
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"; Name = "DisableFileSyncNGSC"; Value = 1; Description = "Synchronisation OneDrive par stratégies"; } # 1 = Désactivé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338388Enabled"; Value = 0; Description = "Suggestions Windows"; } # 0 = Désactivé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338389Enabled"; Value = 0; Description = "Suggestions de contenu"; } # 0 = Désactivé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-353694Enabled"; Value = 0; Description = "Suggestions de contenu"; } # 0 = Désactivé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-353696Enabled"; Value = 0; Description = "Suggestions de contenu"; } # 0 = Désactivé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"; Name = "IsDeviceSearchHistoryEnabled"; Value = 0; Description = "Historique de recherche locale"; } # 0 = Désactivé
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "PublishUserActivities"; Value = 0; Description = "Historique d'activité envoyé au cloud"; } # 0 = Désactivé
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System (Publish)"; Name = "UploadUserActivities"; Value = 0; Description = "Upload de l'historique d'activité vers le cloud"; } # 0 = Désactivé
    @{Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting"; Name = "Value"; Value = 0; Description = "Partage des données Wi-Fi (Wi-Fi Sense - reporting)"; } # 0 = Désactivé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"; Name = "UserActivityTracking"; Value = 0; Description = "Collecte des données d'utilisation des applications"; } # 0 = Désactivé
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"; Name = "LetAppsAccessDiagnosticInfo"; Value = 0; Description = "Bloquer l'accès des apps aux données de diagnostic"; } # 0 = Bloqué
    @{Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots"; Name = "Value"; Value = 0; Description = "Connexion auto aux hotspots Wi-Fi Sense"; } # 0 = Désactivé
    @{Path = "HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet"; Name = "EnableActiveProbing"; Value = 0; Description = "Sonde active NCSI (réseau)"; } # 0 = Désactivé
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"; Name = "DisableLocation"; Value = 1; Description = "Géolocalisation système"; } # 1 = Désactivé
    @{Path = "HKCU:\Software\Microsoft\Clipboard"; Name = "CloudClipboardEnabled"; Value = 0; Description = "Synchronisation cloud presse-papiers"; } # 0 = Désactivé
)
foreach ($item in $Changes) { Set-RegistryValueSafe @item }

#======================================================================
# Sécurité :
#======================================================================
Show-SectionHeader "🛡️ SÉCURITÉ WINDOWS"

$Changes = @(
    @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "DontDisplayLastUserName"; Value = 1; Description = "Nom du dernier utilisateur à l'écran de connexion"; } # 0 = Afficher | 1 = Masquer
    @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name = "NoDriveTypeAutoRun"; Value = 255; Description = "Exécution automatique (USB, CD, périphériques amovibles)"; Experimental = $true; } # 0x91 = Défaut | 255 = Désactivé
    @{Path = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"; Name = "VerifiedAndReputablePolicyState"; Value = 0; Description = "Smart App Control"; } # 0 = Désactivé | 1 = Activé | 2 = Audit
    @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "ConsentPromptBehaviorAdmin"; Value = 2; Description = "UAC au maximum (mot de passe obligatoire pour les admins)"; Experimental = $true; } # 0 = Désactivé | 5 = Moyen | 2 = Max
    @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "PromptOnSecureDesktop"; Value = 1; Description = "UAC sur bureau sécurisé"; Experimental = $true; } # 0 = Désactivé | 1 = Activé
    @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "DisableCAD"; Value = 0; Description = "Ctrl+Alt+Suppr pour la connexion"; Experimental = $true; } # 0 = Obligatoire | 1 = Non demandé
)
foreach ($item in $Changes) { Set-RegistryValueSafe @item }

#======================================================================
# MàJ :
#======================================================================
Show-SectionHeader "⚙️ Paramètres"

$Changes = @(
    # Mises à jour Microsoft Update (désactivé pour le moment)
    # @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"; Name = "DeferFeatureUpdatesPeriodInDays"; Value = 0; Description = "MàJ immédiate autres produits Microsoft"; } # Ne fonctionne pas encore
    # @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"; Name = "EnableFeaturedSoftware"; Value = 1; Description = "Activer Microsoft Update (autres produits Microsoft)"; }
    # @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"; Name = "BranchReadinessLevel"; Value = 48; Description = "Canal Current Branch (Office via WU)"; }
    @{Path = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"; Name = "RestartNotificationsAllowed2"; Value = 1; Description = "Avertir lors d'un redémarrage nécessaire"; } # 0 = Ne pas avertir | 1 = Avertir
)
foreach ($item in $Changes) { Set-RegistryValueSafe @item }

#======================================================================
# Performances Gaming :
#======================================================================
Show-SectionHeader "🎮 PERFORMANCES GAMING"

$Changes = @(
    @{Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_Enabled"; Value = 0; Description = "GameDVR (enregistrement de jeu)"; } # Désactivé Game DVR x2 | # 0 = Désactivé | 1 = Activé
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"; Name = "AllowGameDVR"; Value = 0; Description = "GameDVR via stratégies (téléversement de clip de jeu)"; }
    @{Path = "HKCU:\Software\Microsoft\GameBar"; Name = "GameBarEnabled"; Value = 0; Description = "Xbox Game Bar"; } # Désactivé Xbox Game Bar x2 | # 0 = Désactivé | 1 = Activé
    @{Path = "HKCU:\Software\Microsoft\GameBar"; Name = "ShowStartupPanel"; Value = 0; Description = "Panneau de démarrage de Xbox Game Bar"; }
)

foreach ($item in $Changes) {
    Set-RegistryValueSafe @item
}

#======================================================================
# Usefull :
#======================================================================
Show-SectionHeader "✨ PETIT PLUS"

$Changes = @(
    @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"; Name = "AllowDevelopmentWithoutDevLicense"; Value = 1; Description = "Mode développeur (installation d'applications sans licence)"; } # 0 = Désactivé | 1 = Activé
    @{Path = "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl"; Name = "DisplayParameters"; Value = 1; Description = "Détails complets des messages BSOD"; } # 0 = Simple | 1 = Détails
    @{Path = "HKCU:\Control Panel\Desktop"; Name = "MenuShowDelay"; Value = 0; Description = "Vitesse d'ouverture des menus"; } # 400 = Défaut | 0 = Instantané
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize"; Name = "WaitForIdleState"; Value = 0; Description = "Délai de démarrage des applications"; } # 0 = Activé | 1 = Désactivé
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize"; Name = "StartupDelayInMSec"; Value = 0; Description = "Délai de démarrage des applications"; } # 0 = Désactivé | 1 = Activé
    @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "VerboseStatus"; Value = 1; Description = "Mode Verbose Système"; } # 0 = Désactivé | 1 = Activé
)
foreach ($item in $Changes) { Set-RegistryValueSafe @item }

#======================================================================
# AppX :
#======================================================================
Show-SectionHeader "🗑️ SUPPRESSION DES BLOATWARES VIA APPX"

if (-not $User) {
    if (-not $Test) {
        # AppX classiques
        $AppxToRemove = @(
            "Microsoft.BingNews",
            "Microsoft.BingWeather",
            "Microsoft.GetHelp",
            "Microsoft.Getstarted",
            "Microsoft.MicrosoftOfficeHub",
            "Microsoft.MicrosoftSolitaireCollection",
            "Microsoft.MicrosoftStickyNotes",
            "Microsoft.OutlookForWindows",
            "Microsoft.PowerAutomateDesktop",
            "Microsoft.People",
            "Microsoft.SkypeApp",
            "Microsoft.Todos",
            "Microsoft.Xbox.TCUI",
            "Microsoft.XboxGameOverlay",
            "Microsoft.XboxGamingOverlay",
            "Microsoft.XboxIdentityProvider",
            "Microsoft.XboxSpeechToTextOverlay",
            "Microsoft.YourPhone",
            "Microsoft.ZuneMusic"
        )

        foreach ($app in $AppxToRemove) {
            $appx = Get-AppxPackage -Name $app -AllUsers | Select-Object -First 1
            if ($appx -and $appx.Status -eq "OK") {
                try {
                    Remove-AppxPackage -Package $appx.PackageFullName -AllUsers -ErrorAction Stop
                    Write-Status SUCCESS "App supprimée : $app"
                }
                catch {
                    Write-Status ERROR "Échec suppression $app : $($_.Exception.Message)"
                }

                # Provisionnés (séparé pour éviter double erreur)
                $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $app }
                if ($prov) {
                    try {
                        $prov | Remove-AppxProvisionedPackage -Online -ErrorAction Stop
                        Write-Status SUCCESS "Paquet supprimé : $app"
                    }
                    catch {
                        Write-Status ERROR "Paquet non supprimé : $app"
                    }
                }
            }
            else {
                Write-Status SKIP "App non présente : $app"
            }
        }
    }
    else {
        Write-Status TEST "AppX ignoré"
    }
}
else {
    Write-Status USER "AppX ignoré"
}

#======================================================================
# Winget :
#======================================================================
Show-SectionHeader "🗑️ SUPPRESSSION DES BLOATWARES VIA WINGET"

# Apps modernes WinGet
$WingetApps = @(
    "Microsoft Teams",
    "Microsoft OneDrive",
    "Clipchamp",
    "Xbox"
)
if (-not $User) {
    if (-not $Test) {
        foreach ($pkg in $WingetApps) {
            winget uninstall --silent --accept-source-agreements $pkg | Out-Null
            $err = $LASTEXITCODE
            if ($err -eq 0) {
                Write-Status SUCCESS "$pkg désinstallé"
            }
            else {
                Write-Status SKIP "$pkg déjà désinstallé"
            }
        }
        # widgets
        winget uninstall -e --id 9MSSGKG348SP --verbose | Out-Null
        $err = $LASTEXITCODE
        if ($err -eq 0) {
            Write-Status SUCCESS "Widget désinstallé"
        }
        elseif ($err -eq 0x80070002) {
            Write-Status ERROR "Échec de la désinstallation du Widget"
        }
        else {
            Write-Status SKIP "Widget déjà désinstallé ou non présent"
        }

        # widgets2
        winget uninstall -e --id MSIX\Microsoft.WidgetsPlatformRuntime_1.6.14.0_x64__8wekyb3d8bbwe --verbose | Out-Null
        $err = $LASTEXITCODE
        if ($err -eq 0) {
            Write-Status SUCCESS "Widget2 désinstallé"
        }
        elseif ($err -eq 0x80070002) {
            Write-Status ERROR "Échec de la désinstallation du Widget2"
        }
        else {
            Write-Status SKIP "Widget2 déjà désinstallé ou non présent"
        }
    }
    else {
        Write-Status TEST "Winget ignoré"
    }
}
else {
    Write-Status USER "Winget ignoré"
}

#======================================================================
# Services :
#======================================================================

Show-SectionHeader "🔴 SERVICES"

if (-not $User) {
    $Services = @(
        "DiagTrack",
        "diagsvc",
        "dmwappushservice",
        "OneSyncSvc",
        "WerSvc"
    )

    $OneSyncInstances = Get-Service | Where-Object { $_.Name -like "OneSyncSvc*" }

    foreach ($item in $Services) {
        try {
            if (Get-Service -Name $item -ErrorAction Stop) {
                Stop-Service -Name $item -Force -ErrorAction Stop
                Set-Service -Name $item -StartupType Disabled -ErrorAction Stop
                sc.exe failure $item reset=0 actions=none/0/none/0/none/0 | Out-Null
                Write-Status SUCCESS "Service désactivé : $item"
            }
        }
        catch {
            Write-Status SKIP "Impossible de désactiver : $item"
        }
    }

    foreach ($svc in $OneSyncInstances) {
        try {
            Stop-Service -Name $svc.Name -Force -ErrorAction Stop
            Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction Stop
            sc.exe failure $svc.Name reset=0 actions=none/0/none/0/none/0 | Out-Null
            Write-Status SUCCESS "Service désactivé : $($svc.Name)"
        }
        catch {
            Write-Status SKIP "Impossible de désactiver : $($svc.Name)"
        }
    }
}
else {
    Write-Status USER "Services de télémétrie ignorés"
}


#======================================================================
# Tâches planifiées inutiles :
#======================================================================
Show-SectionHeader "⏱️ TÂCHES PLANIFIÉES"

$ScheduledTasksToDisable = @(
    "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "Microsoft\Windows\Application Experience\StartupAppTask",
    "Microsoft\Windows\Autochk\Proxy",
    "Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",
    "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    #"Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver",
    "Microsoft\Windows\Feedback\Siuf\DmClient",
    "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
    "Microsoft\Windows\Windows Error Reporting\QueueReporting",
    "Microsoft\Windows\Maintenance\WinSAT",
    "Microsoft\Windows\Diagnosis\Scheduled",
    "Microsoft\Windows\OneDrive\OneDrive Standalone Update Task",
    "Microsoft\Windows\OneDrive\OneDrive Standalone Update Task v2",
    "Microsoft\Windows\Sync\BackgroundUploadTask",
    "Microsoft\Windows\Sync\Synchronize"
)

if (-not $User) {
    foreach ($task in $ScheduledTasksToDisable) {
        try {
            if (Get-ScheduledTask -TaskName $task -ErrorAction Stop) {
                Disable-ScheduledTask -TaskName $task -ErrorAction Stop | Out-Null
                Write-Status SUCCESS "Tâche désactivée : $task"
            }
        }
        catch {
            Write-Status SKIP "Tâche absente ou protégée : $task"
        }
    }
}
else {
    Write-Status USER "Tâches planifiées ignorées"
}

#======================================================================
# Nettoyage :
#======================================================================

Show-SectionHeader "🧹 NETTOYAGE"

if (Test-Path "C:\Windows.old") {
    Remove-Item "C:\Windows.old" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Status SUCCESS "Windows.old supprimé"
}
else {
    Write-Status SKIP "Windows.old non présent"
}

$Temp = @(
    "$env:TEMP\*",
    "C:\Windows\Temp\*",
    "C:\Windows\SoftwareDistribution\Download\*",
    "$env:LOCALAPPDATA\Microsoft\OneDrive",
    "$env:PROGRAMDATA\Microsoft OneDrive",
    "$env:USERPROFILE\OneDrive",
    "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
)

foreach ($item in $Temp) {
    try {
        if (Test-Path $item) {
            Remove-Item $item -Recurse -Force -ErrorAction Stop
            Write-Status SUCCESS "Nettoyage : $item"
        }
        else {
            Write-Status SKIP "Absent : $item"
        }
    }
    catch {
        Write-Status ERROR "Impossible de nettoyer : $item"
    }
}


if (-not $Test) {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    gpupdate /force | Out-Null
    Write-Status SUCCESS "Services Redémarrés"
    Remove-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue
}
else {
    gpupdate /force | Out-Null
    Write-Host ""
    Write-Status TEST "Nettoyage Ignoré"
}

#======================================================================
# FINEX :
#======================================================================
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║               ✅ CONFIGURATION TERMINÉE              ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════╝`n" -ForegroundColor Green

if ($StatusCounters.TEST -gt 0) {
    Write-Host " [TEST] : $($StatusCounters.TEST) settings skipped" -ForegroundColor Magenta
}
if ($StatusCounters.USER -gt 0) {
    Write-Host " [USER] : $($StatusCounters.USER) settings skipped" -ForegroundColor White
}

Show-Counters

if (-not $Test) {
    Write-Host "🚨 REDÉMARRAGE REQUIS POUR APPLIQUER TOUTES LES MODIFICATIONS 🚨`n" -ForegroundColor Red
    $choice = Read-Host "Redémarrer maintenant ? (O/N)"
    if ($choice -match "^[oOyY]") {
        Write-Status INFO "Redémarrage dans 5 secondes..."
        Start-Sleep 5
        Restart-Computer -Force
    }
    else {
        Write-Host "⚠️  Redémarrez manuellement ultérieurement`n" -ForegroundColor Yellow
    }
}
else {
    Write-Status TEST "Test terminé - Aucun redémarrage requis`n"
}

Write-Host "Appuyez sur Entrée pour quitter..." -ForegroundColor Gray
Read-Host
