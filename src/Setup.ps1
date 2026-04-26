<#
.SYNOPSIS
    Setup.ps1
    Setup pour chaque script (logs, affichage).

.DESCRIPTION
    Setup.ps1
    A faire.

.EXAMPLE
    . $PSScriptRoot\Setup.ps1 -LogName $PSCommandPath
    Usage basique dans un script.

.NOTES
    Auteur : 1337phtm
    Version : 1.0
    Compatibilité : Windows 11
    Nécessite : PowerShell 5.1+

.LINK
    GitHub :
    https://github.com/1337phtm/
#>

param(
    [string]$LogName
)

$Global:ErrorActionPreference = "Stop"

#======================================================================
# --- Logs ---
#======================================================================

$ScriptName = [System.IO.Path]::GetFileNameWithoutExtension($LogName)

# --- Dossiers de logs ---
$Global:MainLog = Join-Path $env:LOCALAPPDATA "Github - 1337phtm"
$Global:ScriptLogDir = Join-Path $Global:MainLog "$($ScriptName)_Logs"

foreach ($dir in @($Global:MainLog, $Global:ScriptLogDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

# --- Fichiers de log ---
$Global:LogFile = Join-Path $Global:ScriptLogDir "$($ScriptName).log"
$Global:ErrorLogFile = Join-Path $Global:ScriptLogDir "$($ScriptName).error.log"

foreach ($file in @($Global:LogFile, $Global:ErrorLogFile)) {
    if (-not (Test-Path $file)) {
        New-Item -ItemType File -Path $file | Out-Null
    }
}

#======================================================================
# --- Rotate de Logs ---
#======================================================================

# --- Rotate si besoin ---
$RunCountFile = Join-Path $Global:ScriptLogDir "run.count"
if (-not (Test-Path $RunCountFile)) {
    "0" | Out-File $RunCountFile -Encoding UTF8
}

#Essaye de décoder le contenu du fichier sinon réinitialise à 0
try {
    $RunCount = Get-Content $RunCountFile |
    Where-Object { $_.Trim() -ne "" } |
    Select-Object -First 1

    $RunCount = [int]$RunCount
}
catch {
    # Si le fichier est corrompu → on repart à zéro
    $RunCount = 0
    "0" | Out-File $RunCountFile -Encoding UTF8
    Write-ErrorLog -Source "Setup | Start-Log" -Message "run.count corrupted, reset to 0." -Silent
}

$RunCount++
$RunCount | Out-File $RunCountFile -Encoding UTF8

# --- Rotation avancée de logs (3 fichiers max) ---
function Local:RotateLogs {
    param(
        [string]$FilePath
    )

    for ($i = 3; $i -ge 1; $i--) {
        $old = "$FilePath.$i"
        $new = "$FilePath." + ($i + 1)

        if (Test-Path $old) {
            if ($i -eq 3) {
                Remove-Item $old -Force
            }
            else {
                Rename-Item $old $new -Force
            }
        }
    }

    if (Test-Path $FilePath) {
        Rename-Item $FilePath "$FilePath.1" -Force
        New-Item -ItemType File -Path $FilePath | Out-Null
    }
}

if ($RunCount -gt 150) {
    Local:RotateLogs -FilePath $Global:LogFile
    Local:RotateLogs -FilePath $Global:ErrorLogFile
    "0" | Out-File $RunCountFile -Encoding UTF8
}


#======================================================================
# --- Ecriture de logs ---
#======================================================================
function Write-Log {
    param(
        [string]$Message
    )

    Add-Content -Path $Global:LogFile -Value "$($Message)" -Force
}

function Write-ErrorLog {
    param(
        [string]$Message
    )

    Add-Content -Path $Global:ErrorLogFile -Value "$($Message)" -Force
}

#======================================================================
# --- Start ---
#======================================================================

Write-Log -Message ""
Write-Log -Message ""
Write-Log -Message "Démarrage du script : $($LogName) - $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
Write-Log -Message ""
Write-Log -Message ""


Write-ErrorLog -Message ""
Write-ErrorLog -Message ""
Write-ErrorLog -Message "Démarrage du script : $($LogName) - $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
Write-ErrorLog -Message ""
Write-ErrorLog -Message ""


#======================================================================
# --- Affichage ---
#======================================================================

$Global:StatusCounters = @{
    SUCCESS = 0
    ERROR   = 0
    SKIP    = 0
    INFO    = 0
}

function Show-SectionHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║ $Title" -ForegroundColor Blue
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
    Write-Log -Message ""
    Write-Log -Message "╔══════════════════════════════════════════╗"
    Write-Log -Message "║ $Title"
    Write-Log -Message "╚══════════════════════════════════════════╝"
    Write-Log -Message ""

}

function Write-Status {
    param(
        [ValidateSet("SUCCESS", "ERROR", "SKIP", "INFO"<#, "TEST"#>)]$Type,
        [string]$Message
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $Global:StatusCounters[$Type]++

    switch ($Type) {
        "SUCCESS" { Write-Host " [$timestamp] ✓  $Message" -ForegroundColor Green }
        "ERROR" { Write-Host " [$timestamp] ✗ $Message" -ForegroundColor Red }
        "SKIP" { Write-Host " [$timestamp] - $Message" -ForegroundColor Yellow }
        "INFO" { Write-Host " [$timestamp] → $Message" -ForegroundColor Cyan }
        #"TEST" { Write-Host " [$timestamp] ✎ [TEST] $Message" -ForegroundColor Magenta }
    }

    # LOG AUTOMATIQUE
    Write-Log -Message "[$timestamp] [$Type] $Message"

    if ($Type -eq "ERROR") {
        Write-ErrorLog -Message "[$timestamp] [$Type] $Message"
    }
}

function Show-Counters {
    Show-SectionHeader "Execution Summary"
    Write-Host "  ✓ SUCCESS : $($Global:StatusCounters.SUCCESS)" -ForegroundColor Green
    Write-Host "  ✗ ERROR   : $($Global:StatusCounters.ERROR)" -ForegroundColor Red
    Write-Host "  - SKIP    : $($Global:StatusCounters.SKIP)" -ForegroundColor Yellow
    Write-Host "  → INFO    : $($Global:StatusCounters.INFO)`n" -ForegroundColor Cyan
    Write-Host "  📝 Logs    : $($Global:LogFile)`n" -ForegroundColor Gray
}



#Start-Log
